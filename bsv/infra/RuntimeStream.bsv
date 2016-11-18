// Copyright (c) 2016 Cornell University.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

package Runtime;

import Clocks::*;
import Library::*;
import RxChannel::*;
import TxChannel::*;
import HostChannel::*;
import StreamChannel::*;
import Channel::*;
import Gearbox::*;
import SharedBuff::*;
import PacketBuffer::*;
import Printf::*;
import Stream::*;
import StreamGearbox::*;
import XBar::*;
import Vector::*;
import SynthBuilder::*;
`include "ConnectalProjectConfig.bsv"
`include "Debug.defines"
`include "TieOff.defines"
`include "SynthBuilder.defines"
`TIEOFF_PIPEOUT("runtime stream ", MetadataRequest)

typedef 512 DatapathWidth;
typedef TDiv#(DatapathWidth, ChannelWidth) BusRatio;

function Bit#(32) destOf (ByteStream#(n) x);
   // return egress_port in metadata
   return x.user;
endfunction

/*
   P4FPGA runtime consists of 5 types of channels and optional packet memory to acclerate packet re-entry

   Streaming-based datapath pipeline
   -> hostchan + rxchan
   -> per channel fifo
   -> per channel deparser (modifier)
   -> crossbar
   -> txchan : gearbox 512 -> 256 -> 128 -> ring to mac
 */
interface Runtime#(numeric type nrx, numeric type ntx, numeric type nhs);
   interface Vector#(nrx, StreamRxChannel) rxchan;
   interface Vector#(nhs, StreamInChannel) hostchan;
   interface Vector#(ntx, TxChannel) txchan;
   // TODO: reentryChannel and dropChannel
   interface Vector#(TAdd#(nrx, nhs), PipeIn#(MetadataRequest)) prev;
   method Action set_verbosity (int verbosity);
endinterface

module mkRuntime#(Clock rxClock, Reset rxReset, Clock txClock, Reset txReset)(Runtime#(nrx, ntx, nhs))
   provisos(NumAlias#(TLog#(TAdd#(nrx, nhs)), cblogn)
           ,NumAlias#(TExp#(cblogn), cbn)
           ,NumAlias#(TAdd#(nrx, nhs), npi)
           ,NumAlias#(nhs, rx_offset)
           ,Add#(TAdd#(nrx, rx_offset), a__, TExp#(TLog#(TAdd#(nrx, rx_offset))))
           ,Add#(ntx, b__, TExp#(TLog#(TAdd#(nrx, rx_offset))))
           ); 
   let defaultClock <- exposeCurrentClock();
   let defaultReset <- exposeCurrentReset();
   Reset localReset <- mkSyncReset(2, defaultReset, defaultClock);

   Vector#(npi, FIFOF#(MetadataRequest)) meta_ff <- replicateM(mkFIFOF, clocked_by defaultClock, reset_by localReset);
   function PipeIn#(MetadataRequest) metaPipeIn(Integer i);
      return toPipeIn(meta_ff[i]);
   endfunction
   function PipeOut#(MetadataRequest) metaPipeOut(Integer i);
      return toPipeOut(meta_ff[i]);
   endfunction

   `PRINT_DEBUG_MSG

   function Put#(ByteStream#(64)) get_write_data(PacketBuffer#(64, 4) buff);
      return toPut(buff.writeServer);
   endfunction

   function Integer add_base (Integer j) = (valueOf(nhs) + j);
   Vector#(nhs, StreamInChannel) _hostchan <- genWithM(mkStreamInChannel, clocked_by defaultClock, reset_by localReset);
   Vector#(nrx, StreamRxChannel) _rxchan <- genWithM(compose(mkStreamRxChannel(rxClock, rxReset), add_base), clocked_by defaultClock, reset_by localReset);
   Vector#(npi, StreamOutChannel) _streamchan <- genWithM(mkStreamOutChannel, clocked_by defaultClock, reset_by localReset);
   Vector#(ntx, TxChannel) _txchan <- replicateM(mkTxChannel(txClock, txReset), clocked_by defaultClock, reset_by localReset);

   // processed metadata to stream pipeline
   //mapM_(mkTieOff, map(toPipeOut, meta_ff)); // for processing pipeline only experiment
   mapM_(uncurry(mkConnection), zip(genWith(metaPipeOut), map(getMetaIn, _streamchan))); // for full pipeline experiment

   // drop streamed bytes on the floor
   // mkTieOff(_hostchan[0].writeClient.writeData);

   Vector#(npi, StreamGearbox#(16, 32)) gearbox_up_16 <- replicateM(mkStreamGearboxUp_16_32, clocked_by defaultClock, reset_by localReset);
   Vector#(npi, StreamGearbox#(32, 64)) gearbox_up_32 <- replicateM(mkStreamGearboxUp_32_64, clocked_by defaultClock, reset_by localReset);
   let write_clients = append(map(getWriteClient, _hostchan), map(getWriteClient, _rxchan));
   mapM(uncurry(mkConnection), zip(write_clients, map(getWriteServer, _streamchan)));
   mapM(uncurry(mkConnection), zip(map(getWriteClient, _streamchan), map(getDataIn, gearbox_up_16)));
   mapM(uncurry(mkConnection), zip(map(getDataOut, gearbox_up_16), map(getDataIn, gearbox_up_32)));

   // DEBUG: sink after gearbox_up_32
   //mapM_(mkTieOff, map(getDataOut, gearbox_up_32));

   Vector#(npi, PacketBuffer#(64, 4)) input_queues <- mapM(mkPacketBuffer_64, genWith(sprintf("inputQ %h")), clocked_by defaultClock, reset_by localReset); // input queue
   mapM(uncurry(mkConnection), zip(map(getDataOut, gearbox_up_32), map(getWriteData, input_queues))); // gearbox -> input queue
   mapM(uncurry(mkConnection), zip(map(getReadLen, input_queues), map(getReadReq, input_queues))); // immediate transmit, performance issue?

   messageM("Generate Crossbar with parameter: port=" + sprintf("%d", valueOf(cbn)));
   XBar_synth#(nrx, ntx, nhs, 64) xbar <- mkXBar_synth(clocked_by defaultClock, reset_by localReset); // last two parameters are log(size) and idx
   mapM(uncurry(mkConnection), zip(map(getReadData, input_queues), take(xbar.input_ports))); // input queue -> xbar,

   Vector#(cbn, PacketBuffer#(64, 4)) output_queues <- mapM(mkPacketBuffer_64, genWith(sprintf("outputQ %h")), clocked_by defaultClock, reset_by localReset); // output queue
   mapM(uncurry(mkConnection), zip(map(getReadLen, output_queues), map(getReadReq, output_queues))); // immediate transmit

   Vector#(ntx, StreamGearbox#(64, 32)) gearbox_dn_32 <- replicateM(mkStreamGearboxDn_64_32, clocked_by defaultClock, reset_by localReset);
   Vector#(ntx, StreamGearbox#(32, 16)) gearbox_dn_16 <- replicateM(mkStreamGearboxDn_32_16, clocked_by defaultClock, reset_by localReset);
   //mapM_(mkTieOff, xbar.output_ports); // want to see which idx is going out of
   mapM(uncurry(mkConnection), zip(xbar.output_ports, map(get_write_data, output_queues))); // xbar -> output queue
   mapM(uncurry(mkConnection), zip(map(getReadData, takeAt(`NUM_HOSTCHAN, output_queues)), map(getDataIn, gearbox_dn_32))); // output queue -> gearbox

   mapM(uncurry(mkConnection), zip(map(getDataOut, gearbox_dn_32), map(getDataIn, gearbox_dn_16)));
   //mapM(uncurry(mkConnection), zip(map(getDataOut, gearbox_dn_16), map(getWriteServer, _txchan)));

   for (Integer i=0; i<valueOf(ntx); i=i+1) begin
      mkConnection(gearbox_dn_16[i].dataout, toPut(_txchan[i].writeServer));
   end

   // forward packet to any of these ports will be dropped
   mkTieOff(output_queues[0].readServer.readData);
   for (Integer i=valueOf(npi); i<valueOf(cbn); i=i+1) begin
      messageM("TieOff crossbar port " + sprintf("%d", i) + " as drop");
      mkTieOff(output_queues[i].readServer.readData);
   end

   interface prev = genWith(metaPipeIn); // metadata in
   interface rxchan = _rxchan;
   interface txchan = _txchan;
   interface hostchan = _hostchan;
   method Action set_verbosity (int verbosity);
      $display("(%0d) set verbosity to %d", $time, verbosity);
      cf_verbosity <= verbosity;
      mapM_(uncurry(set_verbosity), zip(_rxchan, replicate(verbosity)));
      mapM_(uncurry(set_verbosity), zip(_streamchan, replicate(verbosity)));
      mapM_(uncurry(set_verbosity), zip(_txchan, replicate(verbosity)));
      mapM_(uncurry(set_verbosity), zip(_hostchan, replicate(verbosity)));
      mapM_(uncurry(set_verbosity), zip(input_queues, replicate(verbosity)));
      mapM_(uncurry(set_verbosity), zip(output_queues, replicate(verbosity)));
   endmethod
endmodule

`SynthBuildModule4(mkRuntime, Clock, Reset, Clock, Reset, Runtime#(1, 1, 1), mkRuntime_1_1_1)
`SynthBuildModule4(mkRuntime, Clock, Reset, Clock, Reset, Runtime#(2, 2, 1), mkRuntime_2_2_1)
`SynthBuildModule4(mkRuntime, Clock, Reset, Clock, Reset, Runtime#(4, 4, 1), mkRuntime_4_4_1)
//`SynthBuildModule4(mkRuntime, Clock, Reset, Clock, Reset, Runtime#(6, 6, 1), mkRuntime_6_6_1)
//`SynthBuildModule4(mkRuntime, Clock, Reset, Clock, Reset, Runtime#(10, 10, 1), mkRuntime_10_10_1)

interface XBar_synth #(numeric type nrx, numeric type ntx, numeric type nhs, numeric type t);
   interface Vector#(TExp#(TLog#(TAdd#(nrx, nhs))), Put#(ByteStream#(t))) input_ports;
   interface Vector#(TExp#(TLog#(TAdd#(nrx, nhs))), Get#(ByteStream#(t))) output_ports;
endinterface
module mkXBar_synth(XBar_synth#(nrx, ntx, nhs, t))
   provisos (NumAlias#(TLog#(TAdd#(nrx, nhs)), cblogn)
            ,NumAlias#(TExp#(cblogn), cbn));
   let _i <- mkXBar(valueOf(cblogn), destOf, mkMerge2x1_lru, valueOf(cblogn), 0);
   interface input_ports = toVector(_i.input_ports);
   interface output_ports = toVector(_i.output_ports);
endmodule
`SynthBuildModule(mkXBar_synth, XBar_synth#(4, 4, 1, 64), mkXBar_synth_64)

endpackage
