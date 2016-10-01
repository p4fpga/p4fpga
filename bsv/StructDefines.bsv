import DefaultValue::*;
import Ethernet::*;
import Utils::*;
import Vector::*;

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

`include "StructGenerated.bsv"
