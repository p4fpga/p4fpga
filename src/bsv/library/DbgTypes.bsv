import DefaultValue::*;

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

