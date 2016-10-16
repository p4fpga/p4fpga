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

import Stream::*;
import GetPut::*;
import Pipe::*;
import StructDefines::*;

typeclass GetMacTx#(type a);
   function Get#(ByteStream#(8)) getMacTx(a t);
endtypeclass

typeclass GetWriteClient#(type a);
   function Get#(ByteStream#(16)) getWriteClient(a t);
endtypeclass

typeclass GetWriteServer#(type a);
   function Put#(ByteStream#(16)) getWriteServer(a t);
endtypeclass

typeclass GetMetaIn#(type a);
   function PipeIn#(MetadataRequest) getMetaIn(a t);
endtypeclass

typeclass SetVerbosity#(type a);
   function Action set_verbosity(a t, int verbosity);
endtypeclass

typedef 128 ChannelWidth;

