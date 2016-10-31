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

import Library::*;
import Channel::*;
import StoreAndForward::*;
import StreamGearbox::*;
import SharedBuff::*;
import HeaderSerializer::*;
import PrintTrace::*;
`include "ConnectalProjectConfig.bsv"
import `PARSER::*;
import `DEPARSER::*;
import `TYPEDEF::*;
`include "Debug.defines"

interface PacketModifier;
   interface PipeIn#(MetadataRequest) prev;
   interface PipeIn#(ByteStream#(16)) writeServer;
   interface PipeOut#(ByteStream#(16)) writeClient;
   method Action set_verbosity (int verbosity);
endinterface

module mkPacketModifier(PacketModifier);
   `PRINT_DEBUG_MSG
   FIFOF#(MetadataRequest) req_ff <- printTimedTraceM("modifier", mkFIFOF);
   Deparser deparser <- mkDeparser();
   HeaderSerializer serializer <- mkHeaderSerializer();

   rule rl_req;
      let req <- toGet(req_ff).get;
      let meta = req.meta;
      let pkt = req.pkt;
      deparser.metadata.enq(meta);
      // set user metadata in output bytestream for cross bar
      let egress_port = meta.standard_metadata.egress_port;
      if (egress_port matches tagged Valid .p) begin
         serializer.metadata.enq(p);
      end
      else begin
         // FIXME: if egress_port is not valid, drop port
         serializer.metadata.enq(0);
      end
      dbprint(3, $format("stream out metadata %d", pkt, fshow(meta)));
   endrule

   rule deparse_to_serializer;
      let v <- toGet(deparser.writeClient).get;
      serializer.writeServer.enq(v);
   endrule

   interface writeServer= deparser.writeServer;
   interface writeClient = serializer.writeClient;
   interface prev = toPipeIn(req_ff);
   method Action set_verbosity (int verbosity);
      cf_verbosity <= verbosity;
      deparser.set_verbosity(verbosity);
      serializer.set_verbosity(verbosity);
   endmethod
endmodule

