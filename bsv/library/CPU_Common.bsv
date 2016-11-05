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

typedef enum {
   CPU_STOPPED,
   CPU_FETCH,
   CPU_EXEC,
   CPU_DONE
} CPU_State deriving (Bits, Eq);

typedef enum {READ, WRITE} Command deriving (Bits, Eq, FShow);
typedef enum {SUCCESS, FAIL} Status deriving (Bits, Eq, FShow);

// Tiny instruction memory, 1000 instructions at most
typedef 10 IMemAddrSz;
typedef 32 IMemDataSz;
typedef Bit#(IMemAddrSz) IMemAddr;
typedef Bit#(IMemDataSz) IMemData;

typedef struct {
   Command command;
   Bit#(addr_sz) addr;
   Bit#(data_sz) data;
} IMemReq #(type addr_sz, type data_sz) deriving (Bits, FShow);

typedef struct {
   Command command;
   Status status;
   Bit#(data_sz) data;
} IMemRsp #(type data_sz) deriving (Bits, FShow);

typedef IMemReq#(IMemAddrSz, IMemDataSz) IMemRequest;
typedef IMemRsp#(IMemDataSz)             IMemResponse;
