
// Copyright (c) 2014 Cornell University.

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

package EthMac;

import Clocks::*;
import Vector::*;
import Connectable::*;
import Pipe::*;
import FIFOF::*;
import GetPut::*;
import Pipe::*;
import DefaultValue::*;
import OInt::*;
import Stream::*;
import Ethernet::*;
import TieOff::*;
import Channel::*;
`include "ConnectalProjectConfig.bsv"

`ifdef ALTERA
import AlteraMacWrap::*;

interface EthMacIfc;
   (* always_ready, always_enabled *)
   interface Get#(Bit#(72)) tx;
   (* always_ready, always_enabled *)
   interface Put#(Bit#(72)) rx;
   interface Put#(ByteStream#(8)) packet_tx;
   interface Get#(ByteStream#(8)) packet_rx;
endinterface

// Mac Wrapper
(* synthesize *)
module mkEthMac#(Clock clk_50, Clock clk_156_25, Clock rx_clk, Reset rst_156_25_n)(EthMacIfc);
   Clock defaultClock <- exposeCurrentClock;
   Reset defaultReset <- exposeCurrentReset;

   Reset rx_rst_n <- mkAsyncReset(2, rst_156_25_n, rx_clk);
   Reset rst_50_n <- mkAsyncReset(2, defaultReset, clk_50);

   // Wire data_dw
   Wire#(Maybe#(Bit#(64))) tx_data_w <- mkDWire(tagged Invalid, clocked_by clk_156_25, reset_by rst_156_25_n);
   Wire#(Bit#(3)) tx_empty_w <- mkDWire(0, clocked_by clk_156_25, reset_by rst_156_25_n);
   Wire#(Bit#(1)) tx_ready_w <- mkDWire(0, clocked_by clk_156_25, reset_by rst_156_25_n);
   Wire#(Bit#(1)) tx_sop_w <- mkDWire(0, clocked_by clk_156_25, reset_by rst_156_25_n);
   Wire#(Bit#(1)) tx_eop_w <- mkDWire(0, clocked_by clk_156_25, reset_by rst_156_25_n);

   FIFOF#(ByteStream#(8)) rx_fifo <- mkFIFOF(clocked_by rx_clk, reset_by rx_rst_n);

   MacWrap mac <- mkMacWrap(clk_50, clk_156_25, rx_clk, rst_50_n, rst_156_25_n, rx_rst_n, clocked_by clk_156_25, reset_by rst_156_25_n);

   rule tx_ready;
      tx_ready_w <= mac.tx.fifo_in_ready();
   endrule

   rule tx_data;
      mac.tx.fifo_in_data(fromMaybe(0,tx_data_w));
   endrule

   rule tx_sop;
      mac.tx.fifo_in_startofpacket(tx_sop_w);
   endrule

   rule tx_eop;
      mac.tx.fifo_in_endofpacket(tx_eop_w);
   endrule

   rule tx_empty;
      mac.tx.fifo_in_empty(tx_empty_w);
   endrule

   rule tx_error;
      mac.tx.fifo_in_error(1'b0);
   endrule

   rule tx_valid;
      mac.tx.fifo_in_valid(pack(isValid(tx_data_w)));
   endrule

   rule rx_data;
      let valid = mac.rx.fifo_out_valid();

      ByteStream#(8) packet = defaultValue;
      packet.data = mac.rx.fifo_out_data();
      packet.sop = unpack(mac.rx.fifo_out_startofpacket());
      packet.eop = unpack(mac.rx.fifo_out_endofpacket());
      packet.mask =  ('hff >> mac.rx.fifo_out_empty());

      if (valid == 1'b1) begin
         rx_fifo.enq(packet);
      end
   endrule

   rule rx_ready;
      mac.rx.fifo_out_ready(pack(rx_fifo.notFull));
   endrule

   interface Get tx;
      method ActionValue#(Bit#(72)) get;
         return mac.xgmii.tx_data;
      endmethod
   endinterface
   interface Put rx;
      method Action put(Bit#(72) v);
         mac.xgmii.rx_data(v);
      endmethod
   endinterface
   interface Put packet_tx;
      method Action put(ByteStream#(8) d) if (tx_ready_w != 0);
         Bit#(3) tx_empty = truncate(pack(countOnes(maxBound-unpack(d.mask))));
         //Bit#(3) tx_empty = truncate(fromOInt(unpack(d.mask + 1)));
         tx_data_w <= tagged Valid pack(d.data);
         tx_empty_w <= tx_empty;
         tx_sop_w <= pack(d.sop);
         tx_eop_w <= pack(d.eop);
         //$display("tx_empty %h", tx_empty);
      endmethod
   endinterface
   interface Get packet_rx = toGet(rx_fifo);
endmodule

`elsif XILINX
import XilinxMacWrap::*;
import Xilinx10GE::*;

interface EthMacIfc;
   (* always_ready, always_enabled *)
   interface Get#(XGMIIData) tx;
   (* always_ready, always_enabled *)
   interface Put#(XGMIIData) rx;
   interface Put#(ByteStream#(8)) packet_tx;
   interface Get#(ByteStream#(8)) packet_rx;
endinterface

typeclass GetEthMac#(type a);
  function Get#(ByteStream#(8)) getEthMacRx(a t);
  function Put#(ByteStream#(8)) getEthMacTx(a t);
endtypeclass

instance GetEthMac#(EthMacIfc);
   function Put#(ByteStream#(8)) getEthMacTx(EthMacIfc t);
      return t.packet_tx;
   endfunction
   function Get#(ByteStream#(8)) getEthMacRx(EthMacIfc t);
      return t.packet_rx;
   endfunction
endinstance

// Mac Wrapper
(* synthesize *)
module mkEthMac#(Clock clk_50, Clock clk_156_25, Reset rst_156_25_n)(EthMacIfc);
   Clock defaultClock <- exposeCurrentClock;
   Reset defaultReset <- exposeCurrentReset;

   Clock rx_clk = clk_156_25;
   Reset rx_rst_n = rst_156_25_n;
   Reset rst_50_n <- mkAsyncReset(2, defaultReset, clk_50);
   Reset rst_50 <- mkResetInverter(rst_50_n, clocked_by clk_50);

   Reg#(Bit#(64)) cntr <- mkReg(0, clocked_by clk_156_25, reset_by rst_156_25_n);

   MacWrap mac <- mkMacWrap(clk_50, clk_156_25, rx_clk, rst_50, rst_50_n, rst_156_25_n, rx_rst_n);
   FIFOF#(ByteStream#(8)) rx_fifo <- mkSizedFIFOF(4, clocked_by rx_clk, reset_by rx_rst_n);
   FIFOF#(ByteStream#(8)) tx_fifo <- mkSizedFIFOF(4, clocked_by clk_156_25, reset_by rst_156_25_n);
   Reg#(Bit#(1)) rx_valid <- mkReg(0, clocked_by rx_clk, reset_by rx_rst_n);

   Wire#(Bit#(1)) tx_ready_w <- mkDWire(0, clocked_by clk_156_25, reset_by rst_156_25_n);
   Wire#(Maybe#(Bit#(64))) tx_data_w <- mkDWire(tagged Invalid, clocked_by clk_156_25, reset_by rst_156_25_n);
   Wire#(Bit#(1)) tx_last_w <- mkDWire(0, clocked_by clk_156_25, reset_by rst_156_25_n);
   Wire#(Bit#(8)) tx_keep_w <- mkDWire(0, clocked_by clk_156_25, reset_by rst_156_25_n);
   Wire#(Bit#(1)) tx_user_w <- mkDWire(0, clocked_by clk_156_25, reset_by rst_156_25_n);
   Wire#(Bit#(1)) rx_dcm_locked <- mkDWire(1, clocked_by clk_156_25, reset_by rst_156_25_n);
   Wire#(Bit#(1)) tx_dcm_locked <- mkDWire(1, clocked_by clk_156_25, reset_by rst_156_25_n);

   rule countup;
      cntr <= cntr + 1;
   endrule

   rule dcm_locked_rx;
      mac.rx.dcm_locked(rx_dcm_locked);
   endrule

   rule dcm_locked_tx;
      mac.tx.dcm_locked(tx_dcm_locked);
   endrule

   rule tx_ready;
      tx_ready_w <= mac.tx_axis.tready();
   endrule

   rule tx_data;
      mac.tx_axis.tdata(fromMaybe(0, tx_data_w));
   endrule

   rule tx_keep;
      mac.tx_axis.tkeep(tx_keep_w);
   endrule

   rule tx_last;
      mac.tx_axis.tlast(tx_last_w);
   endrule

   rule tx_user;
      mac.tx_axis.tuser(tx_user_w);
   endrule

   rule tx_valid;
      mac.tx_axis.tvalid(pack(isValid(tx_data_w)));
   endrule

   rule tx_dequeue if (tx_fifo.notEmpty());
      let d = tx_fifo.first;
      tx_data_w <= tagged Valid pack(d.data);
      tx_keep_w <= d.mask;
      tx_last_w <= pack(d.eop);
      tx_user_w <= 1'b0;
      if (tx_ready_w != 0) begin
         tx_fifo.deq;
         $display("deq");
      end
      $display("%d: data=%h %h %h", cntr, d.data, d.eop, d.mask);
   endrule

   rule rx_data;
      let valid = mac.rx_axis.tvalid();
      ByteStream#(8) packet = defaultValue;
      packet.data = mac.rx_axis.tdata();
      packet.sop = (rx_valid==0) && (valid==1);
      packet.eop = unpack(mac.rx_axis.tlast());
      packet.mask =  mac.rx_axis.tkeep();
      if (valid == 1'b1) begin
         rx_fifo.enq(packet);
         $display("%d: rx= %h %h %h %h", cntr, packet.data, packet.sop, packet.eop, packet.mask);
      end
      rx_valid <= valid;
   endrule

   interface Get tx;
      method ActionValue#(XGMIIData) get;
         return XGMIIData{ data: mac.xgmii.txd, ctrl: mac.xgmii.txc };
      endmethod
   endinterface
   interface Put rx;
      method Action put(XGMIIData v);
         mac.xgmii.rxd(v.data);
         mac.xgmii.rxc(v.ctrl);
      endmethod
   endinterface
   interface Put packet_tx = toPut(tx_fifo);
   interface Get packet_rx = toGet(rx_fifo);
endmodule
`endif


endpackage: EthMac

