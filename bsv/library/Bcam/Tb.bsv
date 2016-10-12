package Tb;

import GetPut::*;
import ClientServer::*;
import StmtFSM::*;
import FIFO::*;
import Pipe::*;

import PriorityEncoder::*;
import Ram9b::*;
import BcamTypes::*;
import Bcam::*;

function Stmt testSeq(BinaryCam#(256, 9) dut,
                      String dut_name);
    return seq
        noAction;
        action
            dut.writeServer.put(BcamWriteReq{addr:'h1, data:'h0});
        endaction
        delay(100);
        action
            dut.writeServer.put(BcamWriteReq{addr:'h2, data:'h});
        endaction
        delay(100);
        action
            dut.writeServer.put(BcamWriteReq{addr:'h3, data:'h0});
        endaction
        delay(100);
        action
            dut.writeServer.put(BcamWriteReq{addr:'h4, data:'h0});
        endaction
        delay(100);
        action
            dut.readServer.request.put('h0);
        endaction
        delay(10);
        action
            let v <- dut.readServer.response.get;
            $display("read result=%x", fromMaybe(?,v));
        endaction
   endseq;
endfunction

function Stmt testSeq2(BinaryCam#(256, 18) dut,
                      String dut_name);
    return seq
        noAction;
        action
            dut.writeServer.put(BcamWriteReq{addr:'h1, data:'h1000});
        endaction
        delay(100);
        action
            dut.writeServer.put(BcamWriteReq{addr:'h2, data:'h2000});
        endaction
        delay(100);
        action
            dut.writeServer.put(BcamWriteReq{addr:'h3, data:'h3000});
        endaction
        delay(100);
        action
            dut.writeServer.put(BcamWriteReq{addr:'h4, data:'h4000});
        endaction
        delay(100);
        action
            dut.readServer.request.put('h2000);
        endaction
        delay(10);
        action
            let v <- dut.readServer.response.get;
            $display("read result=%x", fromMaybe(?,v));
        endaction
   endseq;
endfunction

function Stmt testSeq3(BinaryCam#(256, 36) dut,
                      String dut_name);
    return seq
        noAction;
        action
            dut.writeServer.put(BcamWriteReq{addr:'h6, data:'h0200000a});
        endaction
        delay(100);
        action
            dut.writeServer.put(BcamWriteReq{addr:'h2, data:'h1000000a});
        endaction
        delay(100);
        action
            dut.writeServer.put(BcamWriteReq{addr:'h3, data:'h3000000a});
        endaction
        delay(100);
        action
            dut.writeServer.put(BcamWriteReq{addr:'h4, data:'h0400000a});
        endaction
        delay(100);
        action
            dut.readServer.request.put('h0200000a);
        endaction
        delay(10);
        action
            let v <- dut.readServer.response.get;
            $display("read result=%x", fromMaybe(?,v));
        endaction
   endseq;
endfunction


(* synthesize *)
module mkTb (Empty);

   //BinaryCam#(256, 9) bcam <- mkBinaryCam();
   //BinaryCam#(256, 18) bcam <- mkBinaryCam();
   BinaryCam#(256, 36) bcam <- mkBinaryCam();
   //PEnc#(1024) pe <- mkPriorityEncoder();

   //mkAutoFSM(testSeq(bcam, "bcam"));
   //mkAutoFSM(testSeq2(bcam, "bcam"));
   mkAutoFSM(testSeq3(bcam, "bcam"));

endmodule: mkTb

endpackage: Tb
