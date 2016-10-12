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
import Clocks::*;

interface SimClocks;
   interface Clock clock_50;
   interface Reset reset_50_n;
   interface Clock clock_156_25;
   interface Reset reset_156_25_n;
   interface Clock clock_644_53;
endinterface

// assume timescale 
module mkSimClocks(SimClocks);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   Clock clock50mhz <- mkAbsoluteClock(0, 50);
   Clock clock644mhz <- mkAbsoluteClock(0, 4);
   Clock clock156mhz <- mkAbsoluteClock(0, 16);

   Reset reset50n <- mkSyncReset(2, defaultReset, clock50mhz);
   Reset reset156n <- mkSyncReset(2, defaultReset, clock156mhz);

   interface clock_50 = clock50mhz;
   interface clock_156_25 = clock156mhz;
   interface clock_644_53 = clock644mhz;
   interface reset_50_n = reset50n;
   interface reset_156_25_n = reset156n;
endmodule
