// Copyright (c) 2005 Bluespec, Inc.  All rights reserved.

// Based on Bluespec's Crossbar switch using butterfly topology
// Modified to be stream-aware

package XBar;

import FIFO :: *;
import FIFOF :: *;
import List :: *;
import GetPut :: *;
import Stream::*;
import PrintTrace::*;
import Printf::*;

// ================================================================
// Basic building block: a 2-to-1 merge

interface Merge2x1 #(numeric type t);
   interface Put#(ByteStream#(t)) iport0;
   interface Put#(ByteStream#(t)) iport1;
   interface Get#(ByteStream#(t)) oport;
endinterface

// ----------------
// An implementation of Merge2x1
// Arbitration on two inputs: LRU (fair)

module mkMerge2x1_lru (Merge2x1#(t));

   FIFOF#(ByteStream#(t)) fi0 <- mkFIFOF;
   FIFOF#(ByteStream#(t)) fi1 <- mkFIFOF;
   FIFOF#(ByteStream#(t)) fo  <- mkFIFOF;

   Reg#(Maybe#(Bit#(1))) routeFrom <- mkReg(tagged Invalid);
   Reg#(Bool) fi0HasPrio <- mkReg (True);

   rule fi0_is_empty (! fi0.notEmpty);
      let x = fi1.first;
      //$display("(%0d) f1 ", $time, fshow(x));
      fi1.deq;
      fo.enq (x);
      fi0HasPrio <= True;
   endrule

   rule fi1_is_empty (! fi1.notEmpty);
      let x = fi0.first;
      //$display("(%0d) f0 ", $time, fshow(x));
      fi0.deq;
      fo.enq (x);
      fi0HasPrio <= False;
   endrule

   rule both_have_data (fi0.notEmpty && fi1.notEmpty);
      if (routeFrom matches tagged Valid .port) begin
         FIFOF#(ByteStream#(t)) fi = (port == 0) ? fi0 : fi1;
         let x = fi.first;
         $display("(%0d) both avail %d ", $time, port, fshow(x));
         fi.deq;
         fo.enq(x);
         if (x.eop) begin
            routeFrom <= Invalid;
            fi0HasPrio <= ! fi0HasPrio;
         end
      end
      else begin
         FIFOF#(ByteStream#(t)) fi = ((fi0HasPrio) ? fi0 : fi1);
         let x = fi.first;
         $display("(%0d) both avail ", $time, fshow(x));
         fi.deq;
         if (x.sop) begin
            fo.enq (x);
            if (!x.eop) begin
               Bit#(1) port = (fi0HasPrio) ? 0 : 1;
               routeFrom <= tagged Valid port;
            end
            else begin
               fi0HasPrio <= ! fi0HasPrio;
            end
         end
      end
   endrule

   interface iport0 = interface Put
                         method Action put (x);
                            fi0.enq (x);
                         endmethod
                      endinterface;
   interface iport1 = interface Put
                         method Action put (x);
                            fi1.enq (x);
                         endmethod
                      endinterface;
   interface oport =  interface Get
                         method ActionValue#(ByteStream#(t)) get;
                            fo.deq;
                            return fo.first;
                         endmethod
                      endinterface;
endmodule: mkMerge2x1_lru

// ================================================================
// The XBar module, using the basic Merge2x1 building block

// ----------------
// The XBar module interface

interface XBar #(numeric type t);
   interface List#(Put#(ByteStream#(t)))  input_ports;
   interface List#(Get#(ByteStream#(t)))  output_ports;
endinterface

// ----------------
// The routing function: decides whether the packet goes straight
// through, or gets "flipped" to the opposite side

function ActionValue#(Bool) flipCheck (Bit #(32) dst, Bit #(32) src, Integer logn);
   actionvalue
   $display("%x %x %d", dst, src, logn);
   return (dst[fromInteger(logn-1)] != src [fromInteger(logn-1)]);
   endactionvalue
endfunction: flipCheck

// ----------------
// The XBar module constructor

module mkXBar #(Integer logn,
                function Bit #(32) destinationOf (ByteStream#(t) x),
                module #(Merge2x1 #(t)) mkMerge2x1,
                Integer logsize,
                Integer idx)
              (XBar #(t));

   List#(Put#(ByteStream#(t))) iports;
   List#(Get#(ByteStream#(t))) oports;

   // ---- BASE CASE (n = 1 = 2^0)
   if (logn == 0) begin
      FIFO#(ByteStream#(t)) f <- mkFIFO;
      iports = cons (fifoToPut (f), nil);
      oports = cons (fifoToGet (f), nil);
   end

   // ---- RECURSIVE CASE (n = 2^logn, logn > 0)
   else begin
      Integer n     = 2**logn;
      Integer nHalf = div (n, 2);

      // Recursively create two switches of half size
      XBar#(t) upper <- mkXBar (logn-1, destinationOf, mkMerge2x1, logn, nHalf+idx);
      XBar#(t) lower <- mkXBar (logn-1, destinationOf, mkMerge2x1, logn, idx);

      // input ports are just the input ports of upper and lower halves
      iports = append (upper.input_ports, lower.input_ports);

      // intermediate ports are output ports of upper and lower halves
      List#(Get#(ByteStream#(t))) oports_mid =
               append (upper.output_ports, lower.output_ports);

      // Create new column of n 2x1 merges
      List#(Merge2x1#(t)) merges <- replicateM (n, mkMerge2x1);

      // output ports are just the output ports of the new merges
      oports = nil;
      for (Integer j = n-1; j >= 0; j = j - 1)
         oports = cons (merges [j].oport, oports);

      // Routing from each intermediate oport to new column
      for (Integer j = 0; j < n; j = j + 1) begin
         rule route;
            let x <- oports_mid [j].get;
            Bool flip <- flipCheck (destinationOf (x), fromInteger (j), logn);
            let jFlipped = ((j < nHalf) ? j + nHalf : j - nHalf);
            if (! flip) begin
               $display("(%0d) XBar out =%0d flip=%d %h", $time, j, flip, x);
               merges [j]       .iport0.put (x);
            end
            else begin
               $display("(%0d) XBar out =%0d flip=%d %h", $time, jFlipped, flip, x);
               merges [jFlipped].iport1.put (x);
            end
         endrule
      end
   end

   interface input_ports  = iports;
   interface output_ports = oports;
endmodule: mkXBar

// ================================================================

endpackage: XBar
