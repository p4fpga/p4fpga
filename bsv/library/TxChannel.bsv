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

import Library::*;
import Channel::*;
import MemMgmt::*;
import MemTypes::*;
import StoreAndForward::*;
import SharedBuff::*;
import HeaderSerializer::*;
import Channel::*;
`include "ConnectalProjectConfig.bsv"
import `DEPARSER::*;
import `TYPEDEF::*;
`include "Debug.defines"

// // Encapsulate Egress Pipeline, Tx Ring
// interface TxChannel;
//    interface MemReadClient#(`DataBusWidth) readClient;
//    interface MemFreeClient freeClient;
//    interface PipeIn#(MetadataRequest) prev;
//    interface Get#(ByteStream#(8)) macTx;
//    method TxChannelDbgRec read_debug_info;
//    method DeparserPerfRec read_deparser_perf_info;
//    method Action set_verbosity (int verbosity);
// endinterface
// 
// instance GetMacTx#(TxChannel);
//    function Get#(ByteStream#(8)) getMacTx(TxChannel chan);
//       return chan.macTx;
//    endfunction
// endinstance
// 
// // merge StreamOutChannel
// // 
// module mkTxChannel#(Clock txClock, Reset txReset)(TxChannel);
//    RX #(MetadataRequest)  rx_prev_req <- mkRX;
//    let rx_prev_req_info = rx_prev_req.u;
//    PacketBuffer#(16) pktBuff <- mkPacketBuffer();
//    Deparser deparser <- mkDeparser();
//    HeaderSerializer serializer <- mkHeaderSerializer();
//    StoreAndFwdFromMemToRing egress <- mkStoreAndFwdFromMemToRing();
//    StoreAndFwdFromRingToMac ringToMac <- mkStoreAndFwdFromRingToMac(txClock, txReset);
// 
//    mkConnection(egress.writeClient, deparser.writeServer);
//    mkConnection(deparser.writeClient, serializer.writeServer); 
//    mkConnection(serializer.writeClient, pktBuff.writeServer);
//    mkConnection(ringToMac.readClient, pktBuff.readServer);
// 
//    rule handle_request;
//       let req = rx_prev_req_info.first;
//       rx_prev_req_info.deq;
//       let meta = req.meta;
//       let pkt = req.pkt;
//       $display("(%0d) TxChannel:handle_request ", $time, fshow(req));
//       egress.eventPktSend.enq(pkt);
//       deparser.metadata.enq(meta);
//    endrule
// 
//    interface macTx = ringToMac.macTx;
//    interface readClient = egress.readClient;
//    interface freeClient = egress.free;
//    interface prev = rx_prev_req.e;
//    method TxChannelDbgRec read_debug_info;
//       return TxChannelDbgRec {
//          egressCount : 0,
//          pktBuff: pktBuff.dbg
//          };
//    endmethod
//    method read_deparser_perf_info = deparser.read_perf_info;
//    method Action set_verbosity (int verbosity);
//       deparser.set_verbosity(verbosity);
//       serializer.set_verbosity(verbosity);
//    endmethod
// endmodule

// FIXME:
interface TxChannel;
   interface PktWriteServer#(16) writeServer;
   interface Get#(ByteStream#(8)) macTx;
   method Action set_verbosity (int verbosity);
endinterface

instance GetMacTx#(TxChannel);
   function Get#(ByteStream#(8)) getMacTx(TxChannel chan);
      return chan.macTx;
   endfunction
endinstance

instance GetWriteServer#(TxChannel);
   function Put#(ByteStream#(16)) getWriteServer(TxChannel chan);
      return chan.writeServer.writeData;
   endfunction
endinstance

instance SetVerbosity#(TxChannel);
   function Action set_verbosity(TxChannel t, int verbosity);
      action
         t.set_verbosity(verbosity);
      endaction
   endfunction
endinstance

// Tx Channel
module mkTxChannel#(Clock txClock, Reset txReset)(TxChannel);
   `PRINT_DEBUG_MSG
   PacketBuffer#(16) pktBuff <- mkPacketBuffer("txchan");
   StoreAndFwdFromRingToMac ringToMac <- mkStoreAndFwdFromRingToMac(txClock, txReset);
   mkConnection(ringToMac.readClient, pktBuff.readServer);

   interface writeServer= pktBuff.writeServer;
   interface macTx = ringToMac.macTx;
   method Action set_verbosity (int verbosity);
      cf_verbosity <= verbosity;
   endmethod
endmodule


