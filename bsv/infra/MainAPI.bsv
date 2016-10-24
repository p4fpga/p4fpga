`include "ConnectalProjectConfig.bsv"
import BuildVector::*;
import Clocks::*;
import Connectable::*;
import DefaultValue::*;
import Ethernet::*;
import GetPut::*;
import PacketBuffer::*;
import HostChannel::*;
import TxChannel::*;
import StreamChannel::*;
import Stream::*;
import Vector::*;
import Control::*;
import ConnectalTypes::*;
import PktGenChannel::*;
import PktCapChannel::*;
import MetaGenChannel::*;
import DbgDefs::*;
import Runtime::*;
import Program::*;
import StructDefines::*;
import Channel::*;

interface MainRequest;
  method Action read_version();
  method Action writePacketData(Vector#(2, Bit#(64)) data, Vector#(2, Bit#(8)) mask, Bit#(1) sop, Bit#(1) eop);
  method Action set_verbosity(Bit#(32) verbosity);
  method Action writePktGenData(Vector#(2, Bit#(64)) data, Vector#(2, Bit#(8)) mask, Bit#(1) sop, Bit#(1) eop);
  method Action pktgen_start(Bit#(32) iteration, Bit#(32) ipg);
  method Action pktgen_stop();
  method Action pktcap_start(Bit#(32) iteration);
  method Action pktcap_stop();
  method Action writeMetaGenData(Vector#(2, Bit#(64)) data, Vector#(2, Bit#(8)) mask, Bit#(1) sop, Bit#(1) eop);
  method Action metagen_start(Bit#(32) iteration, Bit#(32) freq);
  method Action metagen_stop();
  method Action read_pktcap_perf_info();
`include "APIDefGenerated.bsv"
endinterface
interface MainIndication;
  method Action read_version_rsp (Bit#(32) version);
  method Action read_pktcap_perf_info_resp(PktCapRec rec);
endinterface
interface MainAPI;
  interface MainRequest request;
endinterface

module mkMainAPI #(MainIndication indication,
                   Runtime#(`NUM_RXCHAN, `NUM_TXCHAN, `NUM_HOSTCHAN) runtime,
                   Program#(`NUM_RXCHAN, `NUM_TXCHAN, `NUM_HOSTCHAN, TAdd#(`NUM_PKTGEN, `NUM_METAGEN)) prog,
                   Vector#(`NUM_PKTGEN, PktGenChannel) pktgen,
                   PktCapChannel pktcap,
                   MetaGenChannel metagen)(MainAPI);
  function ByteStream#(16) buildByteStream(Vector#(2, Bit#(64)) data, Vector#(2, Bit#(8)) mask, Bit#(1) sop, Bit#(1) eop);
       ByteStream#(16) beat = defaultValue;
       beat.data = pack(reverse(data));
       beat.mask = pack(reverse(mask));
       beat.sop = unpack(sop);
       beat.eop = unpack(eop);
       return beat;
  endfunction
  interface MainRequest request;
    method Action read_version ();
       let v = `NicVersion;
       indication.read_version_rsp(v);
    endmethod
    method Action writePacketData (Vector#(2, Bit#(64)) data, Vector#(2, Bit#(8)) mask, Bit#(1) sop, Bit#(1) eop);
       ByteStream#(16) beat = buildByteStream(data, mask, sop, eop);
       runtime.hostchan[0].writeServer.writeData.put(beat);
       $display("write data ", fshow(beat));
    endmethod
    // packet gen/cap interfaces
    method Action writePktGenData(Vector#(2, Bit#(64)) data, Vector#(2, Bit#(8)) mask, Bit#(1) sop, Bit#(1) eop);
       ByteStream#(16) beat = buildByteStream(data, mask, sop, eop);
       // all four pktgen ports are loaded with same trace
       for (Integer i=0; i<`NUM_PKTGEN; i=i+1) begin
          pktgen[i].writeData.put(beat);
       end
    endmethod
    // metadata gen interface
    method Action writeMetaGenData(Vector#(2, Bit#(64)) data, Vector#(2, Bit#(8)) mask, Bit#(1) sop, Bit#(1) eop);
       ByteStream#(16) beat = buildByteStream(data, mask, sop, eop);
       metagen.writeData.put(beat);
    endmethod
    method Action pktgen_start (Bit#(32) iter, Bit#(32) ipg);
       for (Integer i=0; i<`NUM_PKTGEN; i=i+1) begin
          pktgen[i].start(iter, ipg);
       end
    endmethod
    method Action pktgen_stop ();
       for (Integer i=0; i<`NUM_PKTGEN; i=i+1) begin
          pktgen[i].stop();
       end
    endmethod
    method pktcap_start = pktcap.start;
    method pktcap_stop = pktcap.stop;
    method metagen_start = metagen.start;
    method metagen_stop = metagen.stop;
    method Action read_pktcap_perf_info();
       let v = pktcap.read_perf_info;
       indication.read_pktcap_perf_info_resp(v);
    endmethod
    // verbosity
    method Action set_verbosity (Bit#(32) verbosity);
       runtime.set_verbosity(unpack(verbosity));
       prog.set_verbosity(unpack(verbosity));
       mapM_(uncurry(set_verbosity), zip(pktgen, replicate(unpack(verbosity))));
    endmethod
`include "APIDeclGenerated.bsv"
  endinterface
endmodule
// Copyright (c) 2016 P4FPGA Project

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
