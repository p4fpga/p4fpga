import BUtils::*;
import BuildVector::*;
import CBus::*;
import ClientServer::*;
import ConfigReg::*;
import Connectable::*;
import DbgDefs::*;
import DefaultValue::*;
import Ethernet::*;
import FIFO::*;
import FIFOF::*;
import FShow::*;
import GetPut::*;
import List::*;
import MIMO::*;
import MatchTable::*;
import PacketBuffer::*;
import Pipe::*;
import PrintTrace::*;
import Register::*;
import SpecialFIFOs::*;
import SharedBuff::*;
import StmtFSM::*;
import TxRx::*;
import Utils::*;
import Vector::*;
import StructDefines::*;
import UnionDefines::*;

export Ingress(..), mkIngress;
export Egress(..), mkEgress;

`include "ControlGenerated.bsv"
