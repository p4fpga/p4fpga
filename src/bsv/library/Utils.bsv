
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

package Utils;

import GetPut::*;
import FIFOF::*;
import Vector::*;
import ClientServer::*;

typedef 8'h07 Idle;
typedef 8'h55 Preamble;
typedef 8'hfb Start;
typedef 8'hd5 Sfd;
typedef 8'hfd Terminate;
typedef 8'hfe Error;
typedef 8'h9c Sequence;

typedef 8'd1  LocalFault;
typedef 8'd2  RemoteFault;

typedef 48'h010000c28001 PauseFrame;

typedef 2'd0  LINK_FAULT_OK;
typedef 2'd1  LINK_FAULT_LOCAL;
typedef 2'd2  LINK_FAULT_REMOTE;
typedef 1'b0  FAULT_SEQ_LOCAL;
typedef 1'b1  FAULT_SEQ_REMOTE;

typedef struct {
   Bit#(64) data;
   Bit#(8) ctrl;
} XgmiiTup deriving (Eq, Bits);

function alpha byteSwap(alpha w)
   provisos (Bits#(alpha, asz),
             Div#(asz, 8, avec),
             Bits#(Vector::Vector#(avec, Bit#(8)), asz));
   Vector#(avec, Bit#(8)) bytes = unpack(pack(w));
   return unpack(pack(reverse(bytes)));
endfunction

function alpha apply_changes (alpha data, alpha metadata, alpha mask)
   provisos (Bits#(alpha, asz),
             Bitwise#(alpha));
   return (data & mask) | metadata;
endfunction

function Bool fifoNotEmpty(FIFOF#(a) fifo);
   return fifo.notEmpty();
endfunction

typeclass DefaultMask#(type t);
   t defaultMask;
endtypeclass

typeclass ToClient #(type req_t, type rsp_t, type ifc1_t, type ifc2_t);
   function Client #(req_t, rsp_t) toClient (ifc1_t ifc1, ifc2_t ifc2);
endtypeclass

typeclass ToServer #(type req_t, type rsp_t, type ifc1_t, type ifc2_t);
   function Server #(req_t, rsp_t) toServer (ifc1_t  ifc1, ifc2_t  ifc2);
endtypeclass

instance ToClient #(req_t, rsp_t, ifc1_t, ifc2_t)
   provisos (ToGet #(ifc1_t, req_t), ToPut #(ifc2_t, rsp_t));
   function Client #(req_t, rsp_t) toClient (ifc1_t ifc1, ifc2_t ifc2);
      return interface Client;
                interface Get request  = toGet (ifc1);
                interface Put response = toPut (ifc2);
             endinterface;
   endfunction
endinstance

instance ToServer #(req_t, rsp_t, ifc1_t, ifc2_t)
   provisos (ToPut #(ifc1_t, req_t), ToGet #(ifc2_t, rsp_t));
   function Server #(req_t, rsp_t) toServer (ifc1_t ifc1, ifc2_t ifc2);
      return interface Server;
                interface Put request  = toPut (ifc1);
                interface Get response = toGet (ifc2);
             endinterface;
   endfunction
endinstance

function Action prettyPrint (String callName, Bit#(asz) data)
   provisos (Div#(asz, 128, avec),
             Add#(a__, 128, asz));
   Fmt fmt = $format(callName);
   for (Integer i = valueOf(avec) - 1; i >= 0; i = i-1) begin
      Bit#(128) d = truncate(data >> (fromInteger(i) * 128));
      fmt = fmt + $format("%016h ", d);
   end
   $display("(%0d)", $time, fmt);
endfunction

endpackage
