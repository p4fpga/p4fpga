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

package Ethernet;

import Vector ::*;
import DefaultValue          ::*;
import Connectable           ::*;
import GetPut                ::*;
import Pipe                  ::*;
import Stream                ::*;

`include "ConnectalProjectConfig.bsv"

`ifdef NUMBER_OF_10G_PORTS
typedef `NUMBER_OF_10G_PORTS NumPorts;
`else
typedef 4 NumPorts;
`endif

typedef 8   PktAddrWidth;
typedef 128  PktDataWidth;
typedef 16   EtherLen; //14 bits is enough!

interface EthPhyIfc;
   (*always_ready, always_enabled*)
   interface Vector#(NumPorts, Put#(Bit#(72)))  tx;
   (*always_ready, always_enabled*)
   interface Vector#(NumPorts, Get#(Bit#(72))) rx;
   (*always_ready, always_enabled*)
   method Vector#(NumPorts, Bit#(1)) serial_tx;
   (*always_ready, always_enabled*)
   method Action serial_rx(Vector#(NumPorts, Bit#(1)) v);
   interface Vector#(NumPorts, Clock) rx_clkout;
endinterface

typedef struct {
   Bit#(PktAddrWidth) addr;
   ByteStream#(16)     data;
} AddrTransRequest deriving (Eq, Bits);
instance FShow#(AddrTransRequest);
   function Fmt fshow (AddrTransRequest req);
      return ($format(" addr=0x%x ", req.addr)
              + $format(" data=0x%x ", req.data.data)
              + $format(" sop= %d ", req.data.sop)
              + $format(" eop= %d ", req.data.eop));
   endfunction
endinstance

typedef struct {
   Bit#(EtherLen) len;
} EtherReq deriving (Eq, Bits);

typedef struct {
   Bit#(64) bytes;
   Bit#(64) starts;
   Bit#(64) ends;
   Bit#(64) errorframes;
   Bit#(64) frames;
} PcsDbgRec deriving (Bits, Eq);

// ===========================
// Shared Packet Memory Types
// ===========================
typedef 32 MaxNumSGLists; // Maximum in-flight packet in pipeline
typedef Bit#(TLog#(MaxNumSGLists)) PktId;
typedef struct {
   PktId id;
   Bit#(EtherLen) size;
} PacketInstance deriving(Bits, Eq, FShow);

endpackage: Ethernet
