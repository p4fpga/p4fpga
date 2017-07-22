import DefaultValue::*;
import Ethernet::*;
import Utils::*;
import Vector::*;

`include "ConnectalProjectConfig.bsv"

typedef struct {
  PacketInstance pkt;
  MetadataT meta;
} MetadataRequest deriving (Bits, Eq, FShow);
typedef struct {
  PacketInstance pkt;
  MetadataT meta;
} MetadataResponse deriving (Bits, Eq, FShow);

typedef union tagged {
  void NotPresent;
  void Forward;
  void Delete;
  void Insert;
  void Processed;
  } HeaderState
deriving (Bits, Eq, FShow);

typedef struct {
   HeaderState state;
   hdrType hdr;
} Header#(type hdrType) deriving (Bits, Eq, FShow);
instance DefaultValue#(Header#(t))
   provisos(Bits#(StructDefines::Header#(t), a__));
   defaultValue = unpack(0);
endinstance

//NOTE: MetadataT struct based on v1model
`ifndef MDP
typedef struct {
    Headers hdr;
    Metadata meta;
    StandardMetadataT standard_metadata;
} MetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(MetadataT);
    defaultValue = unpack(0);
endinstance
`endif

`include "StructGenerated.bsv"
