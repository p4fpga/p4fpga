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
`include "Debug.defines"

interface HeaderSerializer;
   interface PktWriteServer#(16) writeServer;
   interface PktWriteClient#(16) writeClient;
   method Action set_verbosity(int verbosity);
endinterface

typedef TDiv#(PktDataWidth, 8) MaskWidth;
typedef TLog#(PktDataWidth) DataSize;
typedef TLog#(TDiv#(PktDataWidth, 8)) MaskSize;
typedef TAdd#(DataSize, 1) NumBits;
typedef TAdd#(MaskSize, 1) NumBytes;

module mkHeaderSerializer(HeaderSerializer);
   `PRINT_DEBUG_MSG

   FIFOF#(ByteStream#(16)) data_in_ff <- mkFIFOF;
   FIFOF#(ByteStream#(16)) data_out_ff <- mkFIFOF;

   Array#(Reg#(Bool)) sop_buff <- mkCReg(3, False);
   Array#(Reg#(Bool)) eop_buff <- mkCReg(3, False);
   Array#(Reg#(Bit#(PktDataWidth))) data_buff <- mkCReg(3, 0);
   Array#(Reg#(Bit#(MaskWidth))) mask_buff <- mkCReg(3, 0);

   Reg#(Bool) sop_buffered <- mkReg(False);
   Reg#(Bool) eop_buffered <- mkReg(False);
   Reg#(Bit#(PktDataWidth)) data_buffered <- mkReg(0);
   Reg#(Bit#(MaskWidth)) mask_buffered <- mkReg(0);
   Reg#(UInt#(TAdd#(MaskSize, 1))) n_bytes_buffered <- mkReg(0);
   Reg#(UInt#(TAdd#(DataSize, 1))) n_bits_buffered <- mkReg(0);

   PulseWire w_send_frame <- mkPulseWire();
   PulseWire w_buff_frame <- mkPulseWire();
   PulseWire w_send_last2 <- mkPulseWire();
   PulseWire w_send_last1 <- mkPulseWire();

   Array#(Reg#(UInt#(NumBytes))) n_bytes <- mkCReg(2, 0);
   Array#(Reg#(UInt#(NumBits))) n_bits <- mkCReg(2, 0); 

   // deq fifo
   // shift and append
   rule rl_serialize_stage1;
      data_in_ff.deq;
      let data_in_buff = data_in_ff.first.data;
      let eop = data_in_ff.first.eop;
      UInt#(NumBytes) n_bytes_used = countOnes(data_in_ff.first.mask);
      UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;

      n_bytes[0] <= n_bytes_used;
      n_bits[0] <= n_bits_used;
      data_buff[0] <= data_in_ff.first.data;
      mask_buff[0] <= data_in_ff.first.mask;
      eop_buff[0] <= data_in_ff.first.eop;

      if (data_in_ff.first.sop) begin
         sop_buff[0] <= True;
      end

      if (!eop) begin
         if (n_bytes_used + n_bytes_buffered >= fromInteger(valueOf(MaskWidth))) begin
            w_send_frame.send();
         end
         else begin
            w_buff_frame.send();
         end
      end
      else begin
         if (n_bytes_used + n_bytes_buffered >= fromInteger(valueOf(MaskWidth))) begin
            w_send_last2.send();
         end
         else begin
            w_send_last1.send();
         end
      end

      dbprint(3, $format("HeaderSerializer:rl_serialize_stage1 maskwidth=%d buffered %d nbytes %d nbits %d", fromInteger(valueOf(MaskWidth)), n_bytes_buffered, n_bytes_used, n_bits_used));
      dbprint(3, $format("HeaderSerializer:rl_serialize_stage1 ", fshow(data_in_ff.first)));
   endrule

   (* mutually_exclusive = "rl_send_full_frame, rl_buffer_partial_frame, rl_eop_full_frame, rl_eop_partial_frame" *)
   rule rl_send_full_frame if (w_send_frame);
      let data = data_buff[1] << n_bits_buffered | data_buffered; 
      let n_bytes_used = fromInteger(valueOf(MaskWidth)) - n_bytes_buffered;
      UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;
      n_bytes_buffered <= n_bytes[1] - n_bytes_used;
      n_bits_buffered <= n_bits[1] - n_bits_used;
      data_buffered <= data_buff[1] >> n_bits_used;
      mask_buffered <= mask_buff[1] >> n_bytes_used;
      ByteStream#(16) eth = defaultValue;
      eth.sop = sop_buff[1];
      eth.eop = False;
      eth.mask = 'hffff;
      eth.data = data;
      sop_buff[1] <= False;
      data_out_ff.enq(eth);
      dbprint(3, $format("HeaderSerializer:rl_send_full_frame n_bytes_buffered=%d", n_bytes[1] - n_bytes_used, fshow(eth)));
   endrule

   rule rl_buffer_partial_frame if (w_buff_frame);
      let n_bytes_used = n_bytes[1] + n_bytes_buffered;
      UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;
      let data = (data_buff[1] << n_bits_buffered) | data_buffered;
      let mask = (mask_buff[1] << n_bytes_buffered) | mask_buffered;
      n_bytes_buffered <= n_bytes_used;
      n_bits_buffered <= n_bits_used;
      data_buffered <= data;
      mask_buffered <= mask;
      dbprint(3, $format("HeaderSerializer:rl_buffer_partial_frame n_bytes_buffered=%d", n_bytes_used));
   endrule

   rule rl_eop_full_frame if (w_send_last2);
      let data = data_buff[1] << n_bits_buffered | data_buffered; 
      let n_bytes_used = fromInteger(valueOf(MaskWidth)) - n_bytes_buffered;
      UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;
      n_bytes_buffered <= n_bytes[1] - n_bytes_used;
      n_bits_buffered <= n_bits[1] - n_bits_used;
      ByteStream#(16) eth = defaultValue;
      eth.sop = False;
      eth.eop = True;
      eth.mask = 'hffff;
      eth.data = data;
      data_out_ff.enq(eth);
      dbprint(3, $format("HeaderSerializer:rl_eop_full_frame n_bytes_buffered=%d", n_bytes[1] - n_bytes_used));
   endrule

   rule rl_eop_partial_frame if (w_send_last1);
      let data = (data_buff[1] << n_bits_buffered) | data_buffered; 
      let mask = (mask_buff[1] << n_bytes_buffered) | mask_buffered;
      n_bytes_buffered <= 0;
      n_bits_buffered <= 0;
      ByteStream#(16) eth = defaultValue;
      eth.sop = False;
      eth.eop = True;
      eth.mask = mask;
      eth.data = data;
      data_out_ff.enq(eth);
      dbprint(3, $format("HeaderSerializer:rl_eop_partial_frame ", fshow(eth)));
   endrule

   interface PktWriteServer writeServer;
      interface writeData = toPut(data_in_ff);
   endinterface
   interface PktWriteClient writeClient;
      interface writeData = toGet(data_out_ff);
   endinterface
   method Action set_verbosity(int verbosity);
      cf_verbosity <= verbosity;
   endmethod
endmodule


