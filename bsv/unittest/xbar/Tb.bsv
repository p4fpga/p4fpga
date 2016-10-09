// Copyright (c) 2005 Bluespec, Inc.  All rights reserved.

// Testbench for cross-bar switch XBar.bsv

package Tb;

import List :: *;
import GetPut :: *;
import StmtFSM :: *;
import Stream::*;

import XBar :: *;

// egress_port + ByteStream
function Bit#(32) destOf (ByteStream#(8) x);
   return truncate(pack (x.data)) & 'hF;
endfunction

(* synthesize *)
module mkTb (Empty);
   let fi <- mkTbi();
   return fi;
endmodule

//(* synthesize *)
module mkTbi (Empty);

   // A register to count clock cycles, and a rule to increment it,
   // used in displaying time with inputs and outputs
   Reg#(int) ctr <- mkReg(0);
   rule inc_ctr;
      ctr <= ctr+1;
   endrule

   // Instantiate the DUT (4x4 switch, int packets, lru arbitration)
   // XBar#(int) xbar <- mkXBar (2, destOf, mkMerge2x1_static);
   XBar#(8) xbar <- mkXBar (2, 0, destOf, mkMerge2x1_lru);

   // This function encapsulates the action of sending a datum x into input port i
   function Action enqueue (Integer i, ByteStream#(8) x);
      action
         xbar.input_ports[i].put (x);
         int ii = fromInteger (i);
         $display("%d: In:  (port %1d, val )", ctr, i, fshow(x));
      endaction
   endfunction

   // We define a sequence of actions to exercise the DUT.  (This is a
   // particularly simple example: the feature allows considerably more
   // complicated "programs" than this.)
   Stmt test_seq =
     (seq
//         enqueue(0, StreamData{data:'h11, mask:'hff, sop:True, eop:False});
//         enqueue(0, StreamData{data:'h11, mask:'hff, sop:False, eop:True});
//         enqueue(0, StreamData{data:'h12, mask:'hff, sop:True, eop:False});
//         enqueue(0, StreamData{data:'h12, mask:'hff, sop:False, eop:True});
//
//         enqueue(1, StreamData{data:'h21, mask:'hff, sop:True, eop:False});
//         enqueue(1, StreamData{data:'h20, mask:'hff, sop:True, eop:False});
//         enqueue(1, StreamData{data:'h22, mask:'hff, sop:True, eop:False});
//         enqueue(1, StreamData{data:'h23, mask:'hff, sop:True, eop:False});
//
//         enqueue(2, StreamData{data:'h31, mask:'hff, sop:True, eop:False});
//         enqueue(2, StreamData{data:'h30, mask:'hff, sop:True, eop:False});
//         enqueue(2, StreamData{data:'h32, mask:'hff, sop:True, eop:False});
//         enqueue(2, StreamData{data:'h33, mask:'hff, sop:True, eop:False});
//
//         enqueue(3, StreamData{data:'h41, mask:'hff, sop:True, eop:False});
//         enqueue(3, StreamData{data:'h40, mask:'hff, sop:True, eop:False});
//         enqueue(3, StreamData{data:'h42, mask:'hff, sop:True, eop:False});
//         enqueue(3, StreamData{data:'h43, mask:'hff, sop:True, eop:False});

         action    // no collisions
            enqueue(0, StreamData{data:'h51, mask:'hff, sop:True, eop:False});
            enqueue(1, StreamData{data:'h3351, mask:'hff, sop:True, eop:False});
            enqueue(2, StreamData{data:'h2251, mask:'hff, sop:True, eop:False});
            //enqueue(3, StreamData{data:'h1151, mask:'hff, sop:True, eop:False});
         endaction

         action    // no collisions
            enqueue(0, StreamData{data:'h51, mask:'hff, sop:False, eop:False});
            enqueue(1, StreamData{data:'h3351, mask:'hff, sop:False, eop:False});
            enqueue(2, StreamData{data:'h2251, mask:'hff, sop:False, eop:False});
            //enqueue(3, StreamData{data:'h1151, mask:'hff, sop:False, eop:False});
         endaction

         action    // no collisions
            enqueue(0, StreamData{data:'h51, mask:'hff, sop:False, eop:True});
            enqueue(1, StreamData{data:'h3351, mask:'hff, sop:False, eop:True});
            enqueue(2, StreamData{data:'h2251, mask:'hff, sop:False, eop:True});
            //enqueue(3, StreamData{data:'h1151, mask:'hff, sop:False, eop:True});
         endaction

//         action    // collisions
//            enqueue(0, 'h81);
//            enqueue(1, 'h83);
//            enqueue(2, 'h80);
//            enqueue(3, 'h82);
//         endaction
//
//         // Test arbitration
//         action
//            enqueue(0, 'h900);
//            enqueue(1, 'h910);
//         endaction
//         action
//            enqueue(0, 'ha00);
//            enqueue(1, 'ha10);
//         endaction
//         action
//            enqueue(0, 'hb00);
//            enqueue(1, 'hb10);
//         endaction
//         action
//            enqueue(0, 'hc00);
//            enqueue(1, 'hc10);
//         endaction
//
         // ---- sentinel, to finish simulation
         //enqueue (0, StreamData{data:'hFFF0, mask:'hff, sop:True, eop:True});
      endseq);
   
   // Next we use this sequence as argument to a module which instantiates a
   // FSM to implement it.
   FSM test_fsm <- mkFSM(test_seq);

   // A register to control the start rule
   Reg#(Bool) going <- mkReg(False);

   // This rule kicks off the test FSM, which then runs to completion.
   rule start (!going);
      going <= True;
      test_fsm.start;
   endrule
   
   List#(Reg#(ByteStream#(8))) xs <- replicateM (4, mkRegU);

   // Rules to dequeue items from each output port
   for (Integer oj = 0; oj < 4; oj = oj + 1) begin
      rule recv;
         let x <- xbar.output_ports[oj].get;
         (xs [oj]) <= x;
         int intoj = fromInteger (oj);
         $display("%d: Out:      (port %1d, val )", ctr, intoj, fshow(x));

         // ---- Finish when we see sentinel value
         if (x.data == 'hFFF0) $finish (0);
      endrule
   end

endmodule: mkTbi

// ================================================================

endpackage: Tb
