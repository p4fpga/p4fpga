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
`include "ConnectalProjectConfig.bsv"
`include "Debug.defines"
`include "TieOff.defines"
`TIEOFF_PIPEOUT("runtime stream ", MetadataRequest)

typedef 512 DatapathWidth;
typedef TDiv#(DatapathWidth, ChannelWidth) BusRatio;

// FIXME: make this right
function Bit#(32) destOf (ByteStream#(64) x);
   // return egress_port in metadata
   return x.user;
   //return 2; //truncate(pack (x.data)) & 'hF;
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
   provisos(Add#(ntx, a__, 8) // FIXME: make ntx == 8, caused by take()
           ,Add#(TAdd#(nrx, nhs), b__, 8) // introduced by take()
           ,NumAlias#(TAdd#(nrx, nhs), npi)
           ,NumAlias#(nhs, rx_offset)
           ); 

   Vector#(npi, FIFOF#(MetadataRequest)) meta_ff <- replicateM(mkFIFOF);
   function PipeIn#(MetadataRequest) metaPipeIn(Integer i);
      return toPipeIn(meta_ff[i]);
   endfunction
   function PipeOut#(MetadataRequest) metaPipeOut(Integer i);
      return toPipeOut(meta_ff[i]);
   endfunction

   `PRINT_DEBUG_MSG

   function Put#(ByteStream#(64)) get_write_data(PacketBuffer#(64) buff);
      return buff.writeServer.writeData;
   endfunction

   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   function Integer add_base (Integer j) = (valueOf(nhs) + j);
   Vector#(nhs, StreamInChannel) _hostchan <- genWithM(mkStreamInChannel);
   Vector#(nrx, StreamRxChannel) _rxchan <- genWithM(compose(mkStreamRxChannel(rxClock, rxReset), add_base));
   Vector#(npi, StreamOutChannel) _streamchan <- genWithM(mkStreamOutChannel());
   Vector#(ntx, TxChannel) _txchan <- replicateM(mkTxChannel(txClock, txReset));

   // processed metadata to stream pipeline
   // mapM_(mkTieOff, map(toPipeOut, meta_ff));
   mapM_(uncurry(mkConnection), zip(genWith(metaPipeOut), map(getMetaIn, _streamchan)));

   // drop streamed bytes on the floor
   // mkTieOff(_hostchan[0].writeClient.writeData);

   Vector#(npi, StreamGearbox#(16, 32)) gearbox_up_16 <- replicateM(mkStreamGearboxUp());
   Vector#(npi, StreamGearbox#(32, 64)) gearbox_up_32 <- replicateM(mkStreamGearboxUp());
   let write_clients = append(map(getWriteClient, _hostchan), map(getWriteClient, _rxchan));
   mapM(uncurry(mkConnection), zip(write_clients, map(getWriteServer, _streamchan)));
   mapM(uncurry(mkConnection), zip(map(getWriteClient, _streamchan), map(getDataIn, gearbox_up_16)));
   mapM(uncurry(mkConnection), zip(map(getDataOut, gearbox_up_16), map(getDataIn, gearbox_up_32)));

   Vector#(npi, PacketBuffer#(64)) input_queues <- mapM(mkPacketBuffer, genWith(sprintf("inputQ %h"))); // input queue
   mapM(uncurry(mkConnection), zip(map(getDataOut, gearbox_up_32), map(getWriteData, input_queues))); // gearbox -> input queue
   mapM(uncurry(mkConnection), zip(map(getReadLen, input_queues), map(getReadReq, input_queues))); // immediate transmit

   XBar#(64) xbar <- mkXBar(3, destOf, mkMerge2x1_lru, 3, 0); // last two parameters are log(size) and idx
   Vector#(8, Put#(ByteStream#(64))) input_ports = toVector(xbar.input_ports);
   mapM(uncurry(mkConnection), zip(map(getReadData, input_queues), take(input_ports))); // input queue -> xbar

   Vector#(8, PacketBuffer#(64)) output_queues <- mapM(mkPacketBuffer, genWith(sprintf("outputQ %h"))); // output queue
   mapM(uncurry(mkConnection), zip(map(getReadLen, output_queues), map(getReadReq, output_queues))); // immediate transmit

   Vector#(8, Get#(ByteStream#(64))) outvec = toVector(xbar.output_ports);
   Vector#(ntx, StreamGearbox#(64, 32)) gearbox_dn_32 <- replicateM(mkStreamGearboxDn());
   Vector#(ntx, StreamGearbox#(32, 16)) gearbox_dn_16 <- replicateM(mkStreamGearboxDn());
   //mapM_(mkTieOff, outvec); // want to see which idx is going out of
   mapM(uncurry(mkConnection), zip(outvec, map(get_write_data, output_queues))); // xbar -> output queue
   mapM(uncurry(mkConnection), zip(map(getReadData, take(output_queues)), map(getDataIn, gearbox_dn_32))); // output queue -> gearbox

   mapM(uncurry(mkConnection), zip(map(getDataOut, gearbox_dn_32), map(getDataIn, gearbox_dn_16)));
   mapM(uncurry(mkConnection), zip(map(getDataOut, gearbox_dn_16), map(getWriteServer, _txchan)));

   interface prev = genWith(metaPipeIn); // metadata in
   interface rxchan = _rxchan;
   interface txchan = _txchan;
   interface hostchan = _hostchan;
   method Action set_verbosity (int verbosity);
      cf_verbosity <= verbosity;
      mapM_(uncurry(set_verbosity), zip(_rxchan, replicate(verbosity)));
      mapM_(uncurry(set_verbosity), zip(_streamchan, replicate(verbosity)));
      mapM_(uncurry(set_verbosity), zip(_txchan, replicate(verbosity)));
      mapM_(uncurry(set_verbosity), zip(_hostchan, replicate(verbosity)));
      mapM_(uncurry(set_verbosity), zip(input_queues, replicate(verbosity)));
      mapM_(uncurry(set_verbosity), zip(output_queues, replicate(verbosity)));
   endmethod
endmodule

endpackage
