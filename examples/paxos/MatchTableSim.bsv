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

import MatchTable::*;

import "BDPI" function ActionValue#(Bit#(10)) matchtable_read_routing(Bit#(36) msgtype);
import "BDPI" function Action matchtable_write_routing(Bit#(36) msgtype, Bit#(10) data);

import "BDPI" function ActionValue#(Bit#(10)) matchtable_read_fwd(Bit#(9) msgtype);
import "BDPI" function Action matchtable_write_fwd(Bit#(9) msgtype, Bit#(10) data);


instance MatchTableSim#(36, 10);
   function ActionValue#(Bit#(10)) matchtable_read(Bit#(36) key);
   actionvalue
      let v <- matchtable_read_routing(key);
      return v;
   endactionvalue
   endfunction
   function Action matchtable_write(Bit#(36) key, Bit#(10) data);
   action
      $display("(%0d) matchtable write routing %h %h", $time, key, data);
      matchtable_write_routing(key, data);
      $display("(%0d) matchtable write routing done", $time);
   endaction
   endfunction
endinstance

instance MatchTableSim#(9, 10);
   function ActionValue#(Bit#(10)) matchtable_read(Bit#(9) key);
   actionvalue
      let v <- matchtable_read_fwd(key);
      return v;
   endactionvalue
   endfunction
   function Action matchtable_write(Bit#(9) key, Bit#(10) data);
   action
      $display("(%0d) matchtable write fwd %h %h", $time, key, data);
      matchtable_write_fwd(key, data);
      $display("(%0d) matchtable write fwd done", $time);
   endaction
   endfunction
endinstance

