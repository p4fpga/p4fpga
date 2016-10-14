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
import DefaultValue::*;
import TieOff::*;
import GetPut::*;
`include "TieOff.defines"

typedef struct {
   // user : output port?
   Bit#(td)    data;
   Bit#(tm)    mask;
   Bool        sop;
   Bool        eop;
} StreamData#(numeric type td, numeric type tm) deriving (Eq, Bits);
StreamData#(td, tm) streamDefault = StreamData{data:0, mask:0, sop:False, eop:False};

instance FShow#(StreamData#(td, tm));
   function Fmt fshow (StreamData#(td, tm) d);
      return ($format(" data=0x%x", d.data)
             +$format(" mask=0x%x", d.mask)
             +$format(" sop=%d", d.sop)
             +$format(" eop=%d", d.eop));
   endfunction
endinstance

instance DefaultValue#(StreamData#(td, tm));
   function defaultValue = streamDefault;
endinstance

typedef StreamData#(TMul#(bw, 8), bw) ByteStream#(numeric type bw);

`TIEOFF_GET(ByteStream#(64))
`TIEOFF_GET(ByteStream#(32))
`TIEOFF_GET(ByteStream#(16))
`TIEOFF_GET(ByteStream#(8))

