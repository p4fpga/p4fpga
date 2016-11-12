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

import BUtils::*;
import ClientServer::*;
import Connectable::*;
import CBus::*;
import ConfigReg::*;
import DbgDefs::*;
import DefaultValue::*;
import Ethernet::*;
import EthMac::*;
import GetPut::*;
import FIFOF::*;
import MemMgmt::*;
import MemTypes::*;
import MIMO::*;
import Pipe::*;
import PacketBuffer::*;
import PrintTrace::*;
import StoreAndForward::*;
import Stream::*;
import SpecialFIFOs::*;
import SharedBuff::*;
`include "ConnectalProjectConfig.bsv"
`include "Debug.defines"

typedef Bit#(9) EgressPort;

interface HeaderSerializer;
   interface PipeIn#(EgressPort) metadata;
   interface PipeIn#(ByteStream#(16)) writeServer;
   interface PipeOut#(ByteStream#(16)) writeClient;
   method Action set_verbosity(int verbosity);
endinterface

typedef TDiv#(PktDataWidth, 8) MaskWidth;
typedef TLog#(PktDataWidth) DataSize;
typedef TLog#(TDiv#(PktDataWidth, 8)) MaskSize;
typedef TAdd#(DataSize, 1) NumBits;
typedef TAdd#(MaskSize, 1) NumBytes;

typedef struct {
   UInt#(TAdd#(MaskSize, 1)) byte_shift;
   UInt#(TAdd#(DataSize, 1)) bit_shift;
   ByteStream#(16) flit;
} ReqT deriving (Bits);

(* synthesize *)
module mkHeaderSerializer(HeaderSerializer);
   `PRINT_DEBUG_MSG

   Reg#(Bit#(PktDataWidth)) data_buffered <- mkReg(0);
   Reg#(Bit#(MaskWidth)) mask_buffered <- mkReg(0);
   Reg#(UInt#(TAdd#(MaskSize, 1))) n_bytes_buffered <- mkReg(0);
   Reg#(UInt#(TAdd#(DataSize, 1))) n_bits_buffered <- mkReg(0);

   FIFOF#(ByteStream#(16)) data_in_ff <- mkSizedFIFOF(4);
   FIFOF#(ByteStream#(16)) data_out_ff <- mkSizedFIFOF(4);
   FIFOF#(EgressPort) meta_in_ff <- mkSizedFIFOF(16);

   FIFOF#(ReqT) send_frame_ff <- mkFIFOF;
   FIFOF#(ReqT) buff_frame_ff <- mkFIFOF;
   FIFOF#(ReqT) send_last2_ff <- mkFIFOF;
   FIFOF#(ReqT) send_last1_ff <- mkFIFOF;

   Array#(Reg#(Bool)) sop_buff <- mkCReg(2, False);

   rule rl_serialize_stage1;
      let v = data_in_ff.first;
      data_in_ff.deq;

      UInt#(NumBytes) n_bytes_used = countOnes(data_in_ff.first.mask);
      UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;
      let total_bytes = n_bytes_buffered + n_bytes_used;
      let total_bits = n_bits_buffered + n_bits_used;

      if (v.sop) begin
         sop_buff[0] <= True;
      end

      // keep track of n_bytes_used and n_bytes_buffered, and decide what to do next.
      if (!v.eop) begin
         // new byte + existing byte more than one flit?
         if (total_bytes >= fromInteger(valueOf(MaskWidth))) begin
            $display("(%0d) send_frame %d ", $time, total_bytes);
            let req = ReqT {byte_shift: n_bytes_buffered, bit_shift: n_bits_buffered, flit: v};
            n_bytes_buffered <= total_bytes - 16;
            n_bits_buffered <= total_bits - 128;
            send_frame_ff.enq(req);
         end
         else begin
            $display("(%0d) buff_frame %d ", $time, total_bytes);
            let req = ReqT {byte_shift: n_bytes_buffered, bit_shift: n_bits_buffered, flit: v};
            n_bytes_buffered <= total_bytes;
            n_bits_buffered <= total_bits;
            buff_frame_ff.enq(req);
         end
      end
      else begin
         if (total_bytes >= fromInteger(valueOf(MaskWidth))) begin
            $display("(%0d) send_last2 %d ", $time, total_bytes);
            let req = ReqT {byte_shift: n_bytes_buffered, bit_shift: n_bits_buffered, flit: v};
            n_bytes_buffered <= total_bytes - 16;
            n_bits_buffered <= total_bits - 128;
            send_last2_ff.enq(req);
         end
         else begin
            $display("(%0d) send_last1 %d ", $time, total_bytes);
            let req = ReqT {byte_shift: n_bytes_buffered, bit_shift: n_bits_buffered, flit: v};
            n_bytes_buffered <= 0;
            n_bits_buffered <= 0;
            send_last1_ff.enq(req);
         end
      end

      dbprint(3, $format("HeaderSerializer:rl_serialize_stage1 maskwidth=%d buffered %d", fromInteger(valueOf(MaskWidth)), total_bytes));
      dbprint(3, $format("HeaderSerializer:rl_serialize_stage1 ", fshow(data_in_ff.first)));
   endrule

   (* mutually_exclusive = "rl_send_full_frame, rl_buffer_partial_frame, rl_eop_full_frame, rl_eop_partial_frame" *)
   rule rl_send_full_frame;
      let v = send_frame_ff.first;
      send_frame_ff.deq;
      let egress_port = meta_in_ff.first;
      // shift data by n_bits_buffered and concat;
      let data = v.flit.data << v.bit_shift | data_buffered;
      // update total byte buffered, 16 - xxx
      let n_bytes_used = fromInteger(valueOf(MaskWidth)) - v.byte_shift;
      UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;
      data_buffered <= v.flit.data >> n_bits_used;
      mask_buffered <= v.flit.mask >> n_bytes_used;
      // send flit
      ByteStream#(16) eth = defaultValue;
      eth.sop = sop_buff[1];
      eth.eop = False;
      eth.mask = 'hffff;
      eth.data = data;
      sop_buff[1] <= False;
      // set egress_port to stream
      eth.user = zeroExtend(egress_port);
      data_out_ff.enq(eth);
      dbprint(3, $format("HeaderSerializer:rl_send_full_frame ", fshow(eth)));
   endrule

   rule rl_buffer_partial_frame;
      let v = buff_frame_ff.first;
      buff_frame_ff.deq;
      // shift and append
      let data = (v.flit.data << v.bit_shift) | data_buffered;
      // shift and append
      let mask = (v.flit.mask << v.byte_shift) | mask_buffered;
      // update buffered data
      data_buffered <= data;
      // update buffered mask
      mask_buffered <= mask;
      dbprint(3, $format("HeaderSerializer:rl_buffer_partial_frame "));
   endrule

   // FIXME: there may be a bug here, when last beat has eop enabled and more than 16 bytes left to send.
   rule rl_eop_full_frame;
      let v = send_last2_ff.first;
      send_last2_ff.deq;
      let egress_port = meta_in_ff.first;
      let data = v.flit.data << v.bit_shift | data_buffered; 
      ByteStream#(16) eth = defaultValue;
      eth.sop = False;
      eth.eop = True;
      eth.mask = 'hffff;
      eth.data = data;
      eth.user = zeroExtend(egress_port);
      data_out_ff.enq(eth);
      dbprint(3, $format("HeaderSerializer:rl_eop_full_frame ", fshow(eth)));
      // eop, dequeue metadata
      meta_in_ff.deq;
   endrule

   rule rl_eop_partial_frame;
      let v = send_last1_ff.first;
      send_last1_ff.deq;
      let egress_port = meta_in_ff.first;
      let data = (v.flit.data << v.bit_shift) | data_buffered;
      let mask = (v.flit.mask << v.byte_shift) | mask_buffered;
      // send flit
      ByteStream#(16) eth = defaultValue;
      eth.sop = False;
      eth.eop = True;
      eth.mask = mask;
      eth.data = data;
      eth.user = zeroExtend(egress_port);
      data_out_ff.enq(eth);
      dbprint(3, $format("HeaderSerializer:rl_eop_partial_frame ", fshow(eth)));
      // eop, dequeue metadata
      meta_in_ff.deq;
   endrule

   interface metadata = toPipeIn(meta_in_ff);
   interface writeServer = toPipeIn(data_in_ff);
   interface writeClient = toPipeOut(data_out_ff);
   method Action set_verbosity(int verbosity);
      cf_verbosity <= verbosity;
   endmethod
endmodule


