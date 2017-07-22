// Copyright 2010-2011 Bluespec, Inc.  All rights reserved.
// $Revision: 32843 $
// $Date: 2013-12-16 16:25:57 +0000 (Mon, 16 Dec 2013) $

package PushButtonController;

// This is a simple controller for intefacing with the switches on
// Xilinx evaluation boards.

import Clocks :: *;

// This is the interface for the FPGA boundary
interface Button;
   (* always_ready, always_enabled *)
   method Action button(Bit#(1) down);
endinterface

// This is the full switch interface
interface PushButtonController;
   // Returns True for one cycle when the button is pressed
   (* always_ready *)
   method Bool pressed();
   // Returns True for one cycle when the button is pressed
   (* always_ready *)
   method Bool released();
   // Set parameters for how long the button must be held to
   // trigger repetition and how quickly the repetition
   // events will occur when the button is held continuously.
   // Values are roughly in units of ms.
   (* always_ready *)
   method Action setRepeatParams(UInt#(10) delay, UInt#(10) interval);
   // Returns True for one cycle for each repetition event
   (* always_ready *)
   method Bool repeating();
   // Returns the current status of the button
   // (True if pressed, False otherwise)
   (* always_ready *)
   method Bool _read();
   // The interface for connecting to the FPGA pin
   (* prefix = "" *)
   interface Button ifc;
endinterface

// This creates a controller for a single button.
// It allows events such as button press and button release
// to be monitored, debounces the buttons, and supports
// a programmable button repeat rate when the button is
// held down.
(* synthesize *)
module mkPushButtonController#(Clock fpga_clk)(PushButtonController);

   // This implementation assumes a default clock speed around 50 Mhz
   // to 100 MHz.  That allows these delays to roughly correspond to
   // times in milliseconds.

   Reg#(UInt#(10)) first_repeat_after <- mkReg(500);
   Reg#(UInt#(10)) next_repeat_after  <- mkReg(100);

   // We want to tick once every ms or so
   // (assumes a 50 to 100 MHz clock / 2^16)
   Reg#(UInt#(16)) counter <- mkReg(0);
   Bool tick = (counter == 0);

   rule incr;
      counter <= counter + 1;
   endrule

   Clock clk <- exposeCurrentClock();
   CrossingReg#(Bool) _down <- mkNullCrossingReg(clk, False, clocked_by fpga_clk, reset_by noReset);

   Bool on = _down.crossed();
   Reg#(Bool) on_prev1 <- mkReg(False);
   Reg#(Bool) on_prev2 <- mkReg(False);
   Bool bpress   = on && on_prev1 && !on_prev2;
   Bool bhold    = on && on_prev1 && on_prev2;
   Bool brelease = !on && !on_prev1 && on_prev2;

   Reg#(UInt#(10)) down_count  <- mkRegU();
   PulseWire       fire_repeat <- mkPulseWire();

   (* fire_when_enabled, no_implicit_conditions *)
   rule on_press if (bpress);
      down_count <= first_repeat_after;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule held_down if (bhold && tick);
      if (down_count == 0) begin
         down_count <= next_repeat_after;
         fire_repeat.send();
      end
      else
         down_count <= down_count - 1;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule history if (tick);
      if (on == on_prev1)
         on_prev2 <= on_prev1;
      on_prev1 <= on;
   endrule

   method Bool pressed  = bpress;
   method Bool released = brelease;

   method Action setRepeatParams(UInt#(10) delay, UInt#(10) interval);
      first_repeat_after <= delay;
      next_repeat_after  <= interval;
   endmethod

   method Bool repeating = fire_repeat;

   method Bool _read = on && on_prev1;

   interface Button ifc;
      method Action button(Bit#(1) down);
         _down <= unpack(down);
      endmethod
   endinterface
endmodule

endpackage: PushButtonController
