// Copyright 2010-2011 Bluespec, Inc.  All rights reserved.
// $Revision: 32843 $
// $Date: 2013-12-16 16:25:57 +0000 (Mon, 16 Dec 2013) $

package LedController;

// This package contains some logic for doing useful things with Leds
// beyond just connecting them to a signal.
//
// The LedController supports setting the Led to an intermediate
// brightness level, blinking the Led at different speeds, and using
// the Led as an activity meter.

import Clocks :: *;
import Vector :: *;
import DummyDriver :: *;

export Time, Level;
export led_off, led_on_max;
export Led(..), LedController(..), mkLedController;
export combineLeds, bitsToLed;

typedef UInt#(16) Time;   // Very roughly a count of ms
typedef UInt#(3)  Level;  // Brightness level

// Constants for min and max brightness levels
Level led_off    = 0;
Level led_on_max = unpack('1);

// This is the interface that goes out of the FPGA to the Led
interface Led#(numeric type n);
   (* always_ready *)
   method Bit#(n) out;
endinterface

// This allows us to stub out the Led ports so they may exist
// in the netlist, but can be tied-off.
instance DummyDriver#(Led#(n));
   module mkStub(Led#(n) ifc);
      method Bit#(n) out = 0;
   endmodule
endinstance

// This is the main controller interface
interface LedController;
   // Blink the Led, alternating between lo_lvl brightness for lo_time
   // and then hi_lvl brightness for hi_time.  Setting lo_lvl ==
   // hi_lvl will give a steady brightness at the requested level.
   (* always_ready *)
   method Action setPeriod(Level lo_lvl, Time lo_time,
                           Level hi_lvl, Time hi_time);
   // The interface for connecting to the FPGA pins
   (* prefix = "" *)
   interface Led#(1) ifc;
endinterface: LedController

// Implementation of an Led controller

(* synthesize *)
module mkLedController#(Bool invert)(LedController);

   // The Led is controlled by a repeating bit pattern that attempts
   // to reproduce 8 evenly spaced (perceptually) Led intensities

   Reg#(Bit#(16)) pattern   <- mkReg('0);
   Wire#(Level)   new_level <- mkWire();

   function Bit#(16) pattern_for(Level lvl);
      Bit#(16) p = '0;
      case (lvl)
         0: p = 16'b0000_0000_0000_0000;
         1: p = 16'b0000_0001_0000_0001;
         2: p = 16'b0001_0001_0001_0001;
         3: p = 16'b0101_0101_0101_0101;
         4: p = 16'b0101_1011_0110_1101;
         5: p = 16'b1101_0101_1011_1011;
         6: p = 16'b1111_0111_1011_1110;
         7: p = 16'b1111_1111_1111_1111;
      endcase
      return p;
   endfunction

   rule new_pattern;
      pattern <= pattern_for(new_level);
   endrule

   (* preempts = "new_pattern, rotate_pattern" *)
   rule rotate_pattern;
      pattern <= {pattern[0],pattern[15:1]};
   endrule

   // We want to tick once every ms or so
   // (assumes a 50 to 100 MHz clock / 2^16)
   Reg#(UInt#(16)) counter <- mkReg(0);
   Bool tick = (counter == 0);

   (* fire_when_enabled, no_implicit_conditions *)
   rule incr_counter;
      counter <= counter + 1;
   endrule

   // There is always a current Led level and a target level
   Reg#(Level) current_level <- mkReg(0);
   Reg#(Level) target_level  <- mkReg(0);

   Bool do_level_update = tick;

   function Level adjustment(Level diff);
      Level l = 0;
      case (diff)
         7: l = 3;
         6: l = 3;
         5: l = 2;
         4: l = 2;
         3: l = 1;
         2: l = 1;
         1: l = 1;
         0: l = 0;
      endcase
      return l;
   endfunction

   (* fire_when_enabled, no_implicit_conditions *)
   rule update_level if (do_level_update && (current_level != target_level));
      Level l;
      if (target_level > current_level)
         l = current_level + adjustment(target_level - current_level);
      else
         l = current_level - adjustment(current_level - target_level);
      current_level <= l;
      new_level <= l;
   endrule

   // In the periodic mode, alternate between levels at controlled
   // intervals
   Reg#(Level) lo     <- mkReg(0);
   Reg#(Level) hi     <- mkReg(0);
   Reg#(Time)  lo_for <- mkReg(500);
   Reg#(Time)  hi_for <- mkReg(500);

   Reg#(Time) countdown <- mkReg(0);

   (* no_implicit_conditions *)
   rule do_periodic if (tick);
      if (countdown == 0) begin
         if (target_level == lo) begin
            target_level <= hi;
            countdown <= hi_for;
         end
         else begin
            target_level <= lo;
            countdown <= lo_for;
         end
      end
      else begin
         countdown <= countdown - 1;
      end
   endrule

   CrossingReg#(Bit#(1)) _out <- mkNullCrossingReg(noClock, 0);

   (* fire_when_enabled, no_implicit_conditions *)
   rule update_output;
      _out <= invert ? ~pattern[0] : pattern[0];
   endrule

   method Action setPeriod(Level lo_lvl, Time lo_time,
                           Level hi_lvl, Time hi_time);
      lo            <= lo_lvl;
      hi            <= hi_lvl;
      lo_for        <= lo_time;
      hi_for        <= hi_time;
   endmethod

   interface Led ifc;
      method Bit#(1) out = _out.crossed();
   endinterface

endmodule

// A utility function to create a unified Led interface
function Led#(n) combineLeds(Vector#(n,LedController) ctrls);

   function Bit#(1) getLed(LedController ctrl);
      return ctrl.ifc.out();
   endfunction: getLed

   return (interface Led#(n);
              method Bit#(n) out();
                 return pack(map(getLed,ctrls));
              endmethod
           endinterface);
endfunction: combineLeds

// A utility function to create an Led interface from bits
function Led#(n) bitsToLed(Bit#(n) in);
   return (interface Led#(n);
              method Bit#(n) out();
                 return in;
              endmethod
           endinterface);
endfunction: bitsToLed

endpackage: LedController
