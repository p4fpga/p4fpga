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

import DefaultValue::*;
//import DbgTypes::*;

typedef UInt#(64) LUInt;
typedef Int#(64)  LInt;


typedef struct {
   Bit#(64) sopEnq;
   Bit#(64) eopEnq;
   Bit#(64) sopDeq;
   Bit#(64) eopDeq;
} PktBuffDbgRec deriving (Bits, Eq, FShow);
instance DefaultValue#(PktBuffDbgRec);
   defaultValue = unpack(0);
endinstance

typedef struct {
   Bit#(64) allocCnt;
   Bit#(64) freeCnt;
   Bit#(64) allocCompleted;
   Bit#(64) freeCompleted;
   Bit#(64) errorCode;
   Bit#(64) lastIdFreed;
   Bit#(64) lastIdAllocated;
   Bit#(64) freeStarted;
   Bit#(64) firstSegment;
   Bit#(64) lastSegment;
   Bit#(64) currSegment;
   Bit#(64) invalidSegment;
} MemMgmtDbgRec deriving (Bits, Eq);
instance DefaultValue#(MemMgmtDbgRec);
   defaultValue =
   MemMgmtDbgRec {
      allocCnt: 0,
      freeCnt: 0,
      allocCompleted: 0,
      freeCompleted: 0,
      errorCode: 0,
      lastIdFreed: 0,
      lastIdAllocated: 0,
      freeStarted: 0,
      firstSegment: 0,
      lastSegment: 0,
      currSegment: 0,
      invalidSegment: 0
   };
endinstance

typedef struct {
   Bit#(64) fwdReqCnt;
   Bit#(64) sendCnt;
} TDMDbgRec deriving (Bits, Eq);
instance DefaultValue#(TDMDbgRec);
   defaultValue =
   TDMDbgRec {
      fwdReqCnt: 0,
      sendCnt: 0
   };
endinstance

typedef struct {
   Bit#(64) matchRequestCount;
   Bit#(64) matchResponseCount;
   Bit#(64) matchValidCount;
   Bit#(64) lastMatchIdx;
   Bit#(64) lastMatchRequest;
} MatchTableDbgRec deriving (Bits, Eq);
instance DefaultValue#(MatchTableDbgRec);
   defaultValue =
   MatchTableDbgRec {
      matchRequestCount: 0,
      matchResponseCount: 0,
      matchValidCount: 0,
      lastMatchIdx: 0,
      lastMatchRequest: 0
   };
endinstance

typedef struct {
   Bit#(64) goodputCount;
   Bit#(64) idleCount;
} TxThruDbgRec deriving (Bits, Eq);
instance DefaultValue#(TxThruDbgRec);
   defaultValue =
   TxThruDbgRec {
      goodputCount: 0,
      idleCount: 0
   };
endinstance

typedef struct {
   Bit#(64) lookupCnt;
} IPv4RouteDbgRec deriving (Bits, Eq);
instance DefaultValue#(IPv4RouteDbgRec);
   defaultValue = 
   IPv4RouteDbgRec {
      lookupCnt: 0
   };
endinstance

typedef struct {
   Bit#(64) data_bytes;
   Bit#(64) sops;
   Bit#(64) eops;
   Bit#(64) idle_cycles;
   Bit#(64) total_cycles;
} ThruDbgRec deriving (Bits, Eq);
instance DefaultValue#(ThruDbgRec);
   defaultValue=
   ThruDbgRec {
      data_bytes: 0,
      sops: 0,
      eops: 0,
      idle_cycles: 0,
      total_cycles: 0
   };
endinstance

typedef struct {
   LUInt pktIn;
   LUInt pktOut;
} TableDbgRec deriving (Bits, Eq, FShow);
instance DefaultValue #(TableDbgRec);
   defaultValue = unpack(0);
endinstance

typedef struct {
   LUInt fwdCount;
   TableDbgRec accTbl;
   TableDbgRec seqTbl;
   TableDbgRec dmacTbl;
} IngressDbgRec deriving (Bits, Eq, FShow);
instance DefaultValue #(IngressDbgRec);
   defaultValue = unpack(0);
endinstance

typedef struct {
   LUInt paxosCount;
   LUInt ipv6Count;
   LUInt udpCount;
   PktBuffDbgRec pktBuff;
} HostChannelDbgRec deriving (Bits, Eq, FShow);
instance DefaultValue#(HostChannelDbgRec);
   defaultValue = unpack(0);
endinstance

typedef struct {
   LUInt egressCount;
   PktBuffDbgRec pktBuff;
} TxChannelDbgRec deriving (Bits, Eq, FShow);
instance DefaultValue#(TxChannelDbgRec);
   defaultValue = unpack(0);
endinstance

typedef struct {
   Bit#(32) ingress_start_time;
   Bit#(32) ingress_end_time;
   Bit#(32) acceptor_start_time;
   Bit#(32) acceptor_end_time;
   Bit#(32) sequence_start_time;
   Bit#(32) sequence_end_time;
} IngressPerfRec deriving (Bits, Eq, FShow);
instance DefaultValue#(IngressPerfRec);
   defaultValue = unpack(0);
endinstance

typedef struct {
   Bit#(32) parser_start_time;
   Bit#(32) parser_end_time;
} ParserPerfRec deriving (Bits, Eq, FShow);
instance DefaultValue#(ParserPerfRec);
   defaultValue = unpack(0);
endinstance

typedef struct {
   Bit#(64) data_bytes;
   Bit#(64) idle_cycles;
   Bit#(64) total_cycles;
} PktCapRec deriving (Bits, Eq, FShow);
instance DefaultValue#(PktCapRec);
   defaultValue = unpack(0);
endinstance

typedef struct {
   Bit#(32) deparser_start_time;
   Bit#(32) deparser_end_time;
} DeparserPerfRec deriving (Bits, Eq, FShow);
instance DefaultValue#(DeparserPerfRec);
   defaultValue = unpack(0);
endinstance

