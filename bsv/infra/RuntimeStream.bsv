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

package Runtime;

import Library::*;
import RxChannel::*;
import TxChannel::*;
import HostChannel::*;
import StreamChannel::*;
import Channel::*;
import Gearbox::*;
import SharedBuff::*;
import PacketBuffer::*;
import Stream::*;
import XBar::*;
`include "ConnectalProjectConfig.bsv"

typedef 512 DatapathWidth;
typedef TDiv#(DatapathWidth, ChannelWidth) BusRatio;

// FIXME: make this right
function Bit#(32) destOf (ByteStream#(8) x);
   // return egress_port in metadata
   return truncate(pack (x.data)) & 'hF;
endfunction

/*
   P4FPGA runtime consists of 5 types of channels and optional packet memory
   to acclerate packet re-entry
 */
interface Runtime#(numeric type nrx, numeric type ntx, numeric type nhs);
   interface Vector#(nrx, StreamInChannel) rxchan;
   interface Vector#(ntx, StreamOutChannel) txchan;
   interface Vector#(nhs, StreamInChannel) hostchan;
   // TODO: reentryChannel and dropChannel
   method Action set_verbosity (int verbosity);
endinterface
module mkRuntime#(Clock rxClock, Reset rxReset, Clock txClock, Reset txReset)(Runtime#(nrx, ntx, nhs));

   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   Vector#(nhs, StreamInChannel) _hostchan <- genWithM(mkStreamInChannel);
   // FIXME: StreamRxChannel
   Vector#(nrx, StreamInChannel) _rxchan <- genWithM(mkStreamInChannel);//FIXME, clocked_by rxClock, reset_by rxReset);
   Vector#(ntx, StreamOutChannel) _txchan <- replicateM(mkStreamOutChannel(txClock, txReset));
   // drop streamed bytes on the floor
   mkTieOff(_hostchan[0].writeClient.writeData);
   // write streamed byte to input queue
   // gearbox 128 -> 512
   // input queue 512-bit fifo
   Gearbox#(1, BusRatio, Bit#(ChannelWidth)) chanWriteGearbox <- mk1toNGearbox(clock, reset, clock, reset);

   // each rxchan exposes a writeClient ..
   // write stream byte to input queue
   // gearbox 128 -> 512
   // input queue 512-bit fifo

   // xbar 512 bit
   XBar#(8) xbar <- mkXBar(2, 0, destOf, mkMerge2x1_lru);

   // 512-bit output queue
   // gearbox down to 128 bit
   // write to txchan

   interface rxchan = _rxchan;
   interface txchan = _txchan;
   interface hostchan = _hostchan;
   method Action set_verbosity (int verbosity);
      //_rxchan.set_verbosity(verbosity);
      _txchan[0].set_verbosity(verbosity);
      _hostchan[0].set_verbosity(verbosity);
   endmethod
endmodule

endpackage
