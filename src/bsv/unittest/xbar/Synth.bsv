package Synth;

// Copyright (c) 2005 Bluespec, Inc.  All rights reserved.

// ================================================================
// Synthesizable instances of the XBar, of various sizes

// The bsc synthesizer is a currently unable to handle vectors of
// interfaces inside interfaces.  Thus, we define separate XBar4
// and XBar8 interfaces, for example, with explicitly enumerated
// ports.  Hopefully this will shrink once we support vectored
// interfaces.

import List :: *;
import GetPut :: *;
import StmtFSM :: *;

import XBar :: *;

function Bit#(32) destOf (int x);
   return pack (x) & 'hF;
endfunction

// ----------------------------------------------------------------
// The XBar4 module interface

interface XBar4 #(type t);
   interface Put#(t)  input_port_0;
   interface Put#(t)  input_port_1;
   interface Put#(t)  input_port_2;
   interface Put#(t)  input_port_3;

   interface Get#(t)  output_port_0;
   interface Get#(t)  output_port_1;
   interface Get#(t)  output_port_2;
   interface Get#(t)  output_port_3;
endinterface

// ----------------
// A XBar4 module constructor

(* synthesize *)
module mkXBar4 (XBar4#(int));

   XBar#(int) xbar <- mkXBar (2, destOf, mkMerge2x1_lru);

   interface input_port_0 = xbar.input_ports [0];
   interface input_port_1 = xbar.input_ports [1];
   interface input_port_2 = xbar.input_ports [2];
   interface input_port_3 = xbar.input_ports [3];

   interface output_port_0 = xbar.output_ports [0];
   interface output_port_1 = xbar.output_ports [1];
   interface output_port_2 = xbar.output_ports [2];
   interface output_port_3 = xbar.output_ports [3];
endmodule: mkXBar4

// ----------------------------------------------------------------
// The XBar8 module interface

interface XBar8 #(type t);
   interface Put#(t)  input_port_0;
   interface Put#(t)  input_port_1;
   interface Put#(t)  input_port_2;
   interface Put#(t)  input_port_3;
   interface Put#(t)  input_port_4;
   interface Put#(t)  input_port_5;
   interface Put#(t)  input_port_6;
   interface Put#(t)  input_port_7;

   interface Get#(t)  output_port_0;
   interface Get#(t)  output_port_1;
   interface Get#(t)  output_port_2;
   interface Get#(t)  output_port_3;
   interface Get#(t)  output_port_4;
   interface Get#(t)  output_port_5;
   interface Get#(t)  output_port_6;
   interface Get#(t)  output_port_7;
endinterface

// ----------------
// A XBar8 module constructor

(* synthesize *)
module mkXBar8 (XBar8#(int));

   XBar#(int) xbar <- mkXBar (3, destOf, mkMerge2x1_lru);

   interface input_port_0 = xbar.input_ports [0];
   interface input_port_1 = xbar.input_ports [1];
   interface input_port_2 = xbar.input_ports [2];
   interface input_port_3 = xbar.input_ports [3];
   interface input_port_4 = xbar.input_ports [4];
   interface input_port_5 = xbar.input_ports [5];
   interface input_port_6 = xbar.input_ports [6];
   interface input_port_7 = xbar.input_ports [7];

   interface output_port_0 = xbar.output_ports [0];
   interface output_port_1 = xbar.output_ports [1];
   interface output_port_2 = xbar.output_ports [2];
   interface output_port_3 = xbar.output_ports [3];
   interface output_port_4 = xbar.output_ports [4];
   interface output_port_5 = xbar.output_ports [5];
   interface output_port_6 = xbar.output_ports [6];
   interface output_port_7 = xbar.output_ports [7];
endmodule: mkXBar8

// ================================================================

endpackage: Synth
