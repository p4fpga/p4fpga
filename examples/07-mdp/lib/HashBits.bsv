//
// Copyright (c) 2014, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

//
// Bit hash functions designed to produce outputs with higher entropy than
// the inputs.
//
// All the functions here preserve two important properties:
//   1.  They always return the same number of bits as the input.
//   2.  There is a unique output for every unique input.
// Given these properties it is legal to hash an address, use some bits of
// the result as a cache set index and use the remaining result bits as a
// tag.  It is not necessary to use the whole input as the tag.  Note,
// however, that the hash function is not reversible.  A writeback cache
// can't recover the original address from a tag/set derived from a hash.
//
//
// The first function, hashBits, tries to pick the best hash available for
// input sizes up to 128 bits.  The remaining functions hash specific sizes.
//
//
//
// For each hash function there is also an inverse function that converts
// from the hashed value back to the original.  The inverse is computed
// as the inverse of the matrix formed by the bit masks for the hash
// functions.  The hash[] vector forms the rows and the bits participating
// in the hash form the columns.
//

import Extends::*;

//
// hashBits --
//     Pick the best hash available for the input size.  All of the input bits
//     participate in the hash for the lower bits, even the inputs beyond the
//     base hash function's reach.  The assumption is that the low bits of the
//     result will be used as a set index and the remainder may be the tag.
//
function Bit#(n) hashBits(Bit#(n) x);
    let n_bits = valueOf(n);
    // Work at 128 bits, maximum.  Assume some optimization phase will drop
    // high zero bits.
    Bit#(128) h = zeroExtendNP(x);

    //
    // Pick the hash function nearest in size to the input.
    //

    if (n_bits >= 32)
    begin
        // Bits beyond the base hash function participate in the hash of the
        // low bits, while still preserving the property that all inputs have
        // unique outputs.
        //
        // Rotate the values before including them by XOR so contiguous bits
        // in the original value aren't combined.
        Bit#(32) extra_bits = 0;
        if (n_bits > 32)
        begin
            extra_bits = reverseBits(h[63:32]);
        end
        if (n_bits > 64)
        begin
            extra_bits = extra_bits ^ { h[82:64], h[95:83] };
        end
        if (n_bits > 96)
        begin
            extra_bits = extra_bits ^ { h[118:96], h[127:119] };
        end

        h[31:0] = hash32(h[31:0] ^ extra_bits);
    end
    else if (n_bits >= 24)
    begin
        if (n_bits > 24)
            h[7:0] = h[7:0] ^ reverseBits(h[31:24]);

        h[23:0] = hash24(h[23:0]);
    end
    else if (n_bits >= 16)
    begin
        if (n_bits > 16)
            h[7:0] = h[7:0] ^ reverseBits(h[23:16]);

        h[15:0] = hash16(h[15:0]);
    end
    else if (n_bits >= 8)
    begin
        if (n_bits > 8)
        begin
            h[4:0] = h[4:0] ^ h[15:11];
            h[7:5] = h[7:5] ^ h[10:8];
        end

        h[7:0] = hash8(h[7:0]);
    end
    else if (n_bits == 7)
    begin
        h[6:0] = hash7(h[6:0]);
    end
    else if (n_bits == 6)
    begin
        h[5:0] = hash6(h[5:0]);
    end
    else if (n_bits == 5)
    begin
        h[4:0] = hash5(h[4:0]);
    end
    else if (n_bits == 4)
    begin
        h[3:0] = hash4(h[3:0]);
    end
    
    return truncateNP(h);
endfunction


// Inverse of hashBits
function Bit#(n) hashBits_inv(Bit#(n) x);
    let n_bits = valueOf(n);
    Bit#(128) h = zeroExtendNP(x);

    if (n_bits >= 32)
    begin
        h[31:0] = hash32_inv(h[31:0]);

        Bit#(32) extra_bits = 0;
        if (n_bits > 32)
        begin
            extra_bits = reverseBits(h[63:32]);
        end
        if (n_bits > 64)
        begin
            extra_bits = extra_bits ^ { h[82:64], h[95:83] };
        end
        if (n_bits > 96)
        begin
            extra_bits = extra_bits ^ { h[118:96], h[127:119] };
        end

        h[31:0] = h[31:0] ^ extra_bits;
    end
    else if (n_bits >= 24)
    begin
        h[23:0] = hash24_inv(h[23:0]);

        if (n_bits > 24)
            h[7:0] = h[7:0] ^ reverseBits(h[31:24]);
    end
    else if (n_bits >= 16)
    begin
        h[15:0] = hash16_inv(h[15:0]);

        if (n_bits > 16)
            h[7:0] = h[7:0] ^ reverseBits(h[23:16]);
    end
    else if (n_bits >= 8)
    begin
        h[7:0] = hash8_inv(h[7:0]);

        if (n_bits > 8)
        begin
            h[4:0] = h[4:0] ^ h[15:11];
            h[7:5] = h[7:5] ^ h[10:8];
        end
    end
    else if (n_bits == 7)
    begin
        h[6:0] = hash7_inv(h[6:0]);
    end
    else if (n_bits == 6)
    begin
        h[5:0] = hash6_inv(h[5:0]);
    end
    else if (n_bits == 5)
    begin
        h[4:0] = hash5_inv(h[4:0]);
    end
    else if (n_bits == 4)
    begin
        h[3:0] = hash4_inv(h[3:0]);
    end
    
    return truncateNP(h);
endfunction



//
// The remaining functions hash specific sizes.
//


function Bit#(32) hash32(Bit#(32) d);
    //
    // CRC-32 (IEEE802.3), polynomial 0 1 2 4 5 7 8 10 11 12 16 22 23 26 32.
    //
    Bit#(32) hash;
    hash[0] = d[31] ^ d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[25] ^ d[24] ^ 
              d[16] ^ d[12] ^ d[10] ^ d[9] ^ d[6] ^ d[0];
    hash[1] = d[28] ^ d[27] ^ d[24] ^ d[17] ^ d[16] ^ d[13] ^ d[12] ^ 
              d[11] ^ d[9] ^ d[7] ^ d[6] ^ d[1] ^ d[0];
    hash[2] = d[31] ^ d[30] ^ d[26] ^ d[24] ^ d[18] ^ d[17] ^ d[16] ^ 
              d[14] ^ d[13] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[2] ^ 
              d[1] ^ d[0];
    hash[3] = d[31] ^ d[27] ^ d[25] ^ d[19] ^ d[18] ^ d[17] ^ d[15] ^ 
              d[14] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[3] ^ d[2] ^ 
              d[1];
    hash[4] = d[31] ^ d[30] ^ d[29] ^ d[25] ^ d[24] ^ d[20] ^ d[19] ^ 
              d[18] ^ d[15] ^ d[12] ^ d[11] ^ d[8] ^ d[6] ^ d[4] ^ 
              d[3] ^ d[2] ^ d[0];
    hash[5] = d[29] ^ d[28] ^ d[24] ^ d[21] ^ d[20] ^ d[19] ^ d[13] ^ 
              d[10] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[1] ^ d[0];
    hash[6] = d[30] ^ d[29] ^ d[25] ^ d[22] ^ d[21] ^ d[20] ^ d[14] ^ 
              d[11] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[1];
    hash[7] = d[29] ^ d[28] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ 
              d[16] ^ d[15] ^ d[10] ^ d[8] ^ d[7] ^ d[5] ^ d[3] ^ 
              d[2] ^ d[0];
    hash[8] = d[31] ^ d[28] ^ d[23] ^ d[22] ^ d[17] ^ d[12] ^ d[11] ^ 
              d[10] ^ d[8] ^ d[4] ^ d[3] ^ d[1] ^ d[0];
    hash[9] = d[29] ^ d[24] ^ d[23] ^ d[18] ^ d[13] ^ d[12] ^ d[11] ^ 
              d[9] ^ d[5] ^ d[4] ^ d[2] ^ d[1];
    hash[10] = d[31] ^ d[29] ^ d[28] ^ d[26] ^ d[19] ^ d[16] ^ d[14] ^ 
               d[13] ^ d[9] ^ d[5] ^ d[3] ^ d[2] ^ d[0];
    hash[11] = d[31] ^ d[28] ^ d[27] ^ d[26] ^ d[25] ^ d[24] ^ d[20] ^ 
               d[17] ^ d[16] ^ d[15] ^ d[14] ^ d[12] ^ d[9] ^ d[4] ^ 
               d[3] ^ d[1] ^ d[0];
    hash[12] = d[31] ^ d[30] ^ d[27] ^ d[24] ^ d[21] ^ d[18] ^ d[17] ^ 
               d[15] ^ d[13] ^ d[12] ^ d[9] ^ d[6] ^ d[5] ^ d[4] ^ 
               d[2] ^ d[1] ^ d[0];
    hash[13] = d[31] ^ d[28] ^ d[25] ^ d[22] ^ d[19] ^ d[18] ^ d[16] ^ 
               d[14] ^ d[13] ^ d[10] ^ d[7] ^ d[6] ^ d[5] ^ d[3] ^ 
               d[2] ^ d[1];
    hash[14] = d[29] ^ d[26] ^ d[23] ^ d[20] ^ d[19] ^ d[17] ^ d[15] ^ 
               d[14] ^ d[11] ^ d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[3] ^ 
               d[2];
    hash[15] = d[30] ^ d[27] ^ d[24] ^ d[21] ^ d[20] ^ d[18] ^ d[16] ^ 
               d[15] ^ d[12] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[4] ^ 
               d[3];
    hash[16] = d[30] ^ d[29] ^ d[26] ^ d[24] ^ d[22] ^ d[21] ^ d[19] ^ 
               d[17] ^ d[13] ^ d[12] ^ d[8] ^ d[5] ^ d[4] ^ d[0];
    hash[17] = d[31] ^ d[30] ^ d[27] ^ d[25] ^ d[23] ^ d[22] ^ d[20] ^ 
               d[18] ^ d[14] ^ d[13] ^ d[9] ^ d[6] ^ d[5] ^ d[1];
    hash[18] = d[31] ^ d[28] ^ d[26] ^ d[24] ^ d[23] ^ d[21] ^ d[19] ^ 
               d[15] ^ d[14] ^ d[10] ^ d[7] ^ d[6] ^ d[2];
    hash[19] = d[29] ^ d[27] ^ d[25] ^ d[24] ^ d[22] ^ d[20] ^ d[16] ^ 
               d[15] ^ d[11] ^ d[8] ^ d[7] ^ d[3];
    hash[20] = d[30] ^ d[28] ^ d[26] ^ d[25] ^ d[23] ^ d[21] ^ d[17] ^ 
               d[16] ^ d[12] ^ d[9] ^ d[8] ^ d[4];
    hash[21] = d[31] ^ d[29] ^ d[27] ^ d[26] ^ d[24] ^ d[22] ^ d[18] ^ 
               d[17] ^ d[13] ^ d[10] ^ d[9] ^ d[5];
    hash[22] = d[31] ^ d[29] ^ d[27] ^ d[26] ^ d[24] ^ d[23] ^ d[19] ^ 
               d[18] ^ d[16] ^ d[14] ^ d[12] ^ d[11] ^ d[9] ^ d[0];
    hash[23] = d[31] ^ d[29] ^ d[27] ^ d[26] ^ d[20] ^ d[19] ^ d[17] ^ 
               d[16] ^ d[15] ^ d[13] ^ d[9] ^ d[6] ^ d[1] ^ d[0];
    hash[24] = d[30] ^ d[28] ^ d[27] ^ d[21] ^ d[20] ^ d[18] ^ d[17] ^ 
               d[16] ^ d[14] ^ d[10] ^ d[7] ^ d[2] ^ d[1];
    hash[25] = d[31] ^ d[29] ^ d[28] ^ d[22] ^ d[21] ^ d[19] ^ d[18] ^ 
               d[17] ^ d[15] ^ d[11] ^ d[8] ^ d[3] ^ d[2];
    hash[26] = d[31] ^ d[28] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ 
               d[20] ^ d[19] ^ d[18] ^ d[10] ^ d[6] ^ d[4] ^ d[3] ^ 
               d[0];
    hash[27] = d[29] ^ d[27] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ 
               d[20] ^ d[19] ^ d[11] ^ d[7] ^ d[5] ^ d[4] ^ d[1];
    hash[28] = d[30] ^ d[28] ^ d[27] ^ d[26] ^ d[25] ^ d[24] ^ d[22] ^ 
               d[21] ^ d[20] ^ d[12] ^ d[8] ^ d[6] ^ d[5] ^ d[2];
    hash[29] = d[31] ^ d[29] ^ d[28] ^ d[27] ^ d[26] ^ d[25] ^ d[23] ^ 
               d[22] ^ d[21] ^ d[13] ^ d[9] ^ d[7] ^ d[6] ^ d[3];
    hash[30] = d[30] ^ d[29] ^ d[28] ^ d[27] ^ d[26] ^ d[24] ^ d[23] ^ 
               d[22] ^ d[14] ^ d[10] ^ d[8] ^ d[7] ^ d[4];
    hash[31] = d[31] ^ d[30] ^ d[29] ^ d[28] ^ d[27] ^ d[25] ^ d[24] ^ 
               d[23] ^ d[15] ^ d[11] ^ d[9] ^ d[8] ^ d[5];

    return hash;

endfunction


function Bit#(32) hash32_inv(Bit#(32) d);
    //
    // Inverse of hash32
    //
    Bit#(32) hash;
    hash[0] = d[31] ^ d[29] ^ d[27] ^ d[25] ^ d[23] ^ d[21] ^ d[20] ^
              d[16] ^ d[14] ^ d[9] ^ d[5] ^ d[2] ^ d[1];
    hash[1] = d[31] ^ d[30] ^ d[29] ^ d[28] ^ d[27] ^ d[26] ^ d[25] ^
              d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[17] ^ d[16] ^ d[15] ^
              d[14] ^ d[10] ^ d[9] ^ d[6] ^ d[5] ^ d[3] ^ d[1] ^
              d[0];
    hash[2] = d[30] ^ d[28] ^ d[26] ^ d[24] ^ d[20] ^ d[18] ^ d[17] ^
              d[15] ^ d[14] ^ d[11] ^ d[10] ^ d[9] ^ d[7] ^ d[6] ^
              d[5] ^ d[4];
    hash[3] = d[31] ^ d[29] ^ d[27] ^ d[25] ^ d[21] ^ d[19] ^ d[18] ^
              d[16] ^ d[15] ^ d[12] ^ d[11] ^ d[10] ^ d[8] ^ d[7] ^
              d[6] ^ d[5] ^ d[0];
    hash[4] = d[31] ^ d[30] ^ d[29] ^ d[28] ^ d[27] ^ d[26] ^ d[25] ^
              d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[17] ^ d[14] ^ d[13] ^
              d[12] ^ d[11] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[2] ^
              d[0];
    hash[5] = d[30] ^ d[28] ^ d[26] ^ d[25] ^ d[24] ^ d[22] ^ d[21] ^
              d[18] ^ d[16] ^ d[15] ^ d[13] ^ d[12] ^ d[8] ^ d[7] ^
              d[6] ^ d[5] ^ d[3] ^ d[2];
    hash[6] = d[31] ^ d[29] ^ d[27] ^ d[26] ^ d[25] ^ d[23] ^ d[22] ^
              d[19] ^ d[17] ^ d[16] ^ d[14] ^ d[13] ^ d[9] ^ d[8] ^
              d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[0];
    hash[7] = d[31] ^ d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[25] ^ d[24] ^
              d[21] ^ d[18] ^ d[17] ^ d[16] ^ d[15] ^ d[10] ^ d[8] ^
              d[7] ^ d[4] ^ d[2] ^ d[0];
    hash[8] = d[30] ^ d[26] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[19] ^
              d[18] ^ d[17] ^ d[14] ^ d[11] ^ d[8] ^ d[3] ^ d[2];
    hash[9] = d[31] ^ d[27] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^
              d[19] ^ d[18] ^ d[15] ^ d[12] ^ d[9] ^ d[4] ^ d[3];
    hash[10] = d[31] ^ d[29] ^ d[28] ^ d[27] ^ d[24] ^ d[22] ^ d[19] ^
               d[14] ^ d[13] ^ d[10] ^ d[9] ^ d[4] ^ d[2] ^ d[1] ^
               d[0];
    hash[11] = d[31] ^ d[30] ^ d[28] ^ d[27] ^ d[21] ^ d[16] ^ d[15] ^
               d[11] ^ d[10] ^ d[9] ^ d[3] ^ d[0];
    hash[12] = d[28] ^ d[27] ^ d[25] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^
               d[17] ^ d[14] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[5] ^
               d[4] ^ d[2];
    hash[13] = d[29] ^ d[28] ^ d[26] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^
               d[18] ^ d[15] ^ d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[6] ^
               d[5] ^ d[3] ^ d[0];
    hash[14] = d[30] ^ d[29] ^ d[27] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^
               d[19] ^ d[16] ^ d[14] ^ d[13] ^ d[12] ^ d[11] ^ d[7] ^
               d[6] ^ d[4] ^ d[1];
    hash[15] = d[31] ^ d[30] ^ d[28] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^
               d[20] ^ d[17] ^ d[15] ^ d[14] ^ d[13] ^ d[12] ^ d[8] ^
               d[7] ^ d[5] ^ d[2] ^ d[0];
    hash[16] = d[26] ^ d[24] ^ d[23] ^ d[20] ^ d[18] ^ d[15] ^ d[13] ^
               d[8] ^ d[6] ^ d[5] ^ d[3] ^ d[2] ^ d[0];
    hash[17] = d[27] ^ d[25] ^ d[24] ^ d[21] ^ d[19] ^ d[16] ^ d[14] ^
               d[9] ^ d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[1];
    hash[18] = d[28] ^ d[26] ^ d[25] ^ d[22] ^ d[20] ^ d[17] ^ d[15] ^
               d[10] ^ d[8] ^ d[7] ^ d[5] ^ d[4] ^ d[2];
    hash[19] = d[29] ^ d[27] ^ d[26] ^ d[23] ^ d[21] ^ d[18] ^ d[16] ^
               d[11] ^ d[9] ^ d[8] ^ d[6] ^ d[5] ^ d[3];
    hash[20] = d[30] ^ d[28] ^ d[27] ^ d[24] ^ d[22] ^ d[19] ^ d[17] ^
               d[12] ^ d[10] ^ d[9] ^ d[7] ^ d[6] ^ d[4] ^ d[0];
    hash[21] = d[31] ^ d[29] ^ d[28] ^ d[25] ^ d[23] ^ d[20] ^ d[18] ^
               d[13] ^ d[11] ^ d[10] ^ d[8] ^ d[7] ^ d[5] ^ d[1] ^
               d[0];
    hash[22] = d[31] ^ d[30] ^ d[27] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^
               d[20] ^ d[19] ^ d[16] ^ d[12] ^ d[11] ^ d[8] ^ d[6] ^
               d[5] ^ d[0];
    hash[23] = d[29] ^ d[28] ^ d[26] ^ d[24] ^ d[23] ^ d[17] ^ d[16] ^
               d[14] ^ d[13] ^ d[12] ^ d[7] ^ d[6] ^ d[5] ^ d[2] ^
               d[0];
    hash[24] = d[30] ^ d[29] ^ d[27] ^ d[25] ^ d[24] ^ d[18] ^ d[17] ^
               d[15] ^ d[14] ^ d[13] ^ d[8] ^ d[7] ^ d[6] ^ d[3] ^
               d[1] ^ d[0];
    hash[25] = d[31] ^ d[30] ^ d[28] ^ d[26] ^ d[25] ^ d[19] ^ d[18] ^
               d[16] ^ d[15] ^ d[14] ^ d[9] ^ d[8] ^ d[7] ^ d[4] ^
               d[2] ^ d[1] ^ d[0];
    hash[26] = d[26] ^ d[25] ^ d[23] ^ d[21] ^ d[19] ^ d[17] ^ d[15] ^
               d[14] ^ d[10] ^ d[8] ^ d[3];
    hash[27] = d[27] ^ d[26] ^ d[24] ^ d[22] ^ d[20] ^ d[18] ^ d[16] ^
               d[15] ^ d[11] ^ d[9] ^ d[4] ^ d[0];
    hash[28] = d[28] ^ d[27] ^ d[25] ^ d[23] ^ d[21] ^ d[19] ^ d[17] ^
               d[16] ^ d[12] ^ d[10] ^ d[5] ^ d[1];
    hash[29] = d[29] ^ d[28] ^ d[26] ^ d[24] ^ d[22] ^ d[20] ^ d[18] ^
               d[17] ^ d[13] ^ d[11] ^ d[6] ^ d[2];
    hash[30] = d[30] ^ d[29] ^ d[27] ^ d[25] ^ d[23] ^ d[21] ^ d[19] ^
               d[18] ^ d[14] ^ d[12] ^ d[7] ^ d[3] ^ d[0];
    hash[31] = d[31] ^ d[30] ^ d[28] ^ d[26] ^ d[24] ^ d[22] ^ d[20] ^
               d[19] ^ d[15] ^ d[13] ^ d[8] ^ d[4] ^ d[1] ^ d[0];

    return hash;

endfunction


function Bit#(24) hash24(Bit#(24) d);
    //
    // CRC-24, polynomial 0 1 3 4 5 6 7 10 11 14 17 18 23 24.
    //
    Bit#(24) hash;
    hash[0] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[18] ^ d[17] ^ 
              d[16] ^ d[14] ^ d[10] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ 
              d[1] ^ d[0];
    hash[1] = d[16] ^ d[15] ^ d[14] ^ d[11] ^ d[10] ^ d[6] ^ d[0];
    hash[2] = d[17] ^ d[16] ^ d[15] ^ d[12] ^ d[11] ^ d[7] ^ d[1];
    hash[3] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[14] ^ d[13] ^ 
              d[12] ^ d[10] ^ d[8] ^ d[5] ^ d[4] ^ d[3] ^ d[1] ^ 
              d[0];
    hash[4] = d[19] ^ d[18] ^ d[17] ^ d[16] ^ d[15] ^ d[13] ^ d[11] ^ 
              d[10] ^ d[9] ^ d[6] ^ d[3] ^ d[0];
    hash[5] = d[23] ^ d[22] ^ d[21] ^ d[12] ^ d[11] ^ d[7] ^ d[5] ^ 
              d[3] ^ d[2] ^ d[0];
    hash[6] = d[21] ^ d[20] ^ d[19] ^ d[18] ^ d[17] ^ d[16] ^ d[14] ^ 
              d[13] ^ d[12] ^ d[10] ^ d[8] ^ d[6] ^ d[5] ^ d[2] ^ 
              d[0];
    hash[7] = d[23] ^ d[16] ^ d[15] ^ d[13] ^ d[11] ^ d[10] ^ d[9] ^ 
              d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[0];
    hash[8] = d[17] ^ d[16] ^ d[14] ^ d[12] ^ d[11] ^ d[10] ^ d[8] ^ 
              d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[1];
    hash[9] = d[18] ^ d[17] ^ d[15] ^ d[13] ^ d[12] ^ d[11] ^ d[9] ^ 
              d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[2];
    hash[10] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[17] ^ d[13] ^ d[12] ^ 
               d[9] ^ d[8] ^ d[7] ^ d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[11] = d[20] ^ d[19] ^ d[17] ^ d[16] ^ d[13] ^ d[9] ^ d[8] ^ 
               d[4] ^ d[0];
    hash[12] = d[21] ^ d[20] ^ d[18] ^ d[17] ^ d[14] ^ d[10] ^ d[9] ^ 
               d[5] ^ d[1];
    hash[13] = d[22] ^ d[21] ^ d[19] ^ d[18] ^ d[15] ^ d[11] ^ d[10] ^ 
               d[6] ^ d[2];
    hash[14] = d[21] ^ d[18] ^ d[17] ^ d[14] ^ d[12] ^ d[11] ^ d[10] ^ 
               d[7] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[15] = d[22] ^ d[19] ^ d[18] ^ d[15] ^ d[13] ^ d[12] ^ d[11] ^ 
               d[8] ^ d[6] ^ d[5] ^ d[3] ^ d[2] ^ d[1];
    hash[16] = d[23] ^ d[20] ^ d[19] ^ d[16] ^ d[14] ^ d[13] ^ d[12] ^ 
               d[9] ^ d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[2];
    hash[17] = d[23] ^ d[22] ^ d[19] ^ d[18] ^ d[16] ^ d[15] ^ d[13] ^ 
               d[8] ^ d[7] ^ d[2] ^ d[1] ^ d[0];
    hash[18] = d[22] ^ d[21] ^ d[18] ^ d[10] ^ d[9] ^ d[8] ^ d[5] ^ 
               d[4] ^ d[0];
    hash[19] = d[23] ^ d[22] ^ d[19] ^ d[11] ^ d[10] ^ d[9] ^ d[6] ^ 
               d[5] ^ d[1];
    hash[20] = d[23] ^ d[20] ^ d[12] ^ d[11] ^ d[10] ^ d[7] ^ d[6] ^ 
               d[2];
    hash[21] = d[21] ^ d[13] ^ d[12] ^ d[11] ^ d[8] ^ d[7] ^ d[3];
    hash[22] = d[22] ^ d[14] ^ d[13] ^ d[12] ^ d[9] ^ d[8] ^ d[4];
    hash[23] = d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[18] ^ d[17] ^ d[16] ^ 
               d[15] ^ d[13] ^ d[9] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ 
               d[0];

    return hash;

endfunction


function Bit#(24) hash24_inv(Bit#(24) d);
    //
    // Inverse of hash24
    //
    Bit#(24) hash;
    hash[0] = d[23] ^ d[22] ^ d[19] ^ d[17] ^ d[14] ^ d[13] ^ d[12] ^
              d[9] ^ d[7] ^ d[6] ^ d[1] ^ d[0];
    hash[1] = d[22] ^ d[20] ^ d[19] ^ d[18] ^ d[17] ^ d[15] ^ d[12] ^
              d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[2];
    hash[2] = d[23] ^ d[21] ^ d[20] ^ d[19] ^ d[18] ^ d[16] ^ d[13] ^
              d[11] ^ d[10] ^ d[9] ^ d[7] ^ d[3];
    hash[3] = d[23] ^ d[21] ^ d[20] ^ d[13] ^ d[11] ^ d[10] ^ d[9] ^
              d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[1] ^ d[0];
    hash[4] = d[23] ^ d[21] ^ d[19] ^ d[17] ^ d[13] ^ d[11] ^ d[10] ^
              d[8] ^ d[6] ^ d[5] ^ d[2];
    hash[5] = d[23] ^ d[20] ^ d[19] ^ d[18] ^ d[17] ^ d[13] ^ d[11] ^
              d[3] ^ d[1];
    hash[6] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[17] ^ d[13] ^
              d[9] ^ d[7] ^ d[6] ^ d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[7] = d[21] ^ d[18] ^ d[17] ^ d[13] ^ d[12] ^ d[10] ^ d[9] ^
              d[8] ^ d[6] ^ d[5] ^ d[3] ^ d[2];
    hash[8] = d[22] ^ d[19] ^ d[18] ^ d[14] ^ d[13] ^ d[11] ^ d[10] ^
              d[9] ^ d[7] ^ d[6] ^ d[4] ^ d[3];
    hash[9] = d[23] ^ d[20] ^ d[19] ^ d[15] ^ d[14] ^ d[12] ^ d[11] ^
              d[10] ^ d[8] ^ d[7] ^ d[5] ^ d[4] ^ d[0];
    hash[10] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[17] ^ d[16] ^
               d[15] ^ d[14] ^ d[11] ^ d[8] ^ d[7] ^ d[5];
    hash[11] = d[21] ^ d[20] ^ d[19] ^ d[18] ^ d[16] ^ d[15] ^ d[14] ^
               d[13] ^ d[8] ^ d[7] ^ d[1];
    hash[12] = d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[17] ^ d[16] ^ d[15] ^
               d[14] ^ d[9] ^ d[8] ^ d[2];
    hash[13] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[17] ^ d[16] ^
               d[15] ^ d[10] ^ d[9] ^ d[3] ^ d[0];
    hash[14] = d[21] ^ d[18] ^ d[16] ^ d[14] ^ d[13] ^ d[12] ^ d[11] ^
               d[10] ^ d[9] ^ d[7] ^ d[6] ^ d[4] ^ d[0];
    hash[15] = d[22] ^ d[19] ^ d[17] ^ d[15] ^ d[14] ^ d[13] ^ d[12] ^
               d[11] ^ d[10] ^ d[8] ^ d[7] ^ d[5] ^ d[1] ^ d[0];
    hash[16] = d[23] ^ d[20] ^ d[18] ^ d[16] ^ d[15] ^ d[14] ^ d[13] ^
               d[12] ^ d[11] ^ d[9] ^ d[8] ^ d[6] ^ d[2] ^ d[1];
    hash[17] = d[23] ^ d[22] ^ d[21] ^ d[16] ^ d[15] ^ d[10] ^ d[6] ^
               d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[18] = d[19] ^ d[16] ^ d[14] ^ d[13] ^ d[12] ^ d[11] ^ d[9] ^
               d[6] ^ d[4] ^ d[3] ^ d[2] ^ d[0];
    hash[19] = d[20] ^ d[17] ^ d[15] ^ d[14] ^ d[13] ^ d[12] ^ d[10] ^
               d[7] ^ d[5] ^ d[4] ^ d[3] ^ d[1];
    hash[20] = d[21] ^ d[18] ^ d[16] ^ d[15] ^ d[14] ^ d[13] ^ d[11] ^
               d[8] ^ d[6] ^ d[5] ^ d[4] ^ d[2];
    hash[21] = d[22] ^ d[19] ^ d[17] ^ d[16] ^ d[15] ^ d[14] ^ d[12] ^
               d[9] ^ d[7] ^ d[6] ^ d[5] ^ d[3];
    hash[22] = d[23] ^ d[20] ^ d[18] ^ d[17] ^ d[16] ^ d[15] ^ d[13] ^
               d[10] ^ d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[0];
    hash[23] = d[23] ^ d[22] ^ d[21] ^ d[18] ^ d[16] ^ d[13] ^ d[12] ^
               d[11] ^ d[8] ^ d[6] ^ d[5] ^ d[0];

    return hash;

endfunction


function Bit#(16) hash16(Bit#(16) d);
    //
    // CRC-16, polynomial 0 2 15 16.
    //
    Bit#(16) hash;
    hash[0] = d[15] ^ d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^
              d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[1] = d[14] ^ d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^
              d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1];
    hash[2] = d[14] ^ d[1] ^ d[0];
    hash[3] = d[15] ^ d[2] ^ d[1];
    hash[4] = d[3] ^ d[2];
    hash[5] = d[4] ^ d[3];
    hash[6] = d[5] ^ d[4];
    hash[7] = d[6] ^ d[5];
    hash[8] = d[7] ^ d[6];
    hash[9] = d[8] ^ d[7];
    hash[10] = d[9] ^ d[8];
    hash[11] = d[10] ^ d[9];
    hash[12] = d[11] ^ d[10];
    hash[13] = d[12] ^ d[11];
    hash[14] = d[13] ^ d[12];
    hash[15] = d[15] ^ d[14] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^
               d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];

    return hash;

endfunction


function Bit#(16) hash16_inv(Bit#(16) d);
    //
    // Inverse of hash16
    //
    Bit#(16) hash;
    hash[0] = d[14] ^ d[12] ^ d[10] ^ d[8] ^ d[6] ^ d[4] ^ d[2] ^
              d[1];
    hash[1] = d[15] ^ d[13] ^ d[11] ^ d[9] ^ d[7] ^ d[5] ^ d[3] ^
              d[2];
    hash[2] = d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[3] = d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[4] = d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[5] = d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[6] = d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^
              d[0];
    hash[7] = d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^
              d[1] ^ d[0];
    hash[8] = d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^
              d[2] ^ d[1] ^ d[0];
    hash[9] = d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^
              d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[10] = d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^
               d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[11] = d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^
               d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[12] = d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^
               d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[13] = d[14] ^ d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^
               d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^
               d[0];
    hash[14] = d[15] ^ d[14] ^ d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^
               d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^
               d[1];
    hash[15] = d[15] ^ d[13] ^ d[11] ^ d[9] ^ d[7] ^ d[5] ^ d[3] ^
               d[1] ^ d[0];

    return hash;

endfunction


function Bit#(8) hash8(Bit#(8) d);
    //
    // CRC-8 (ATM HEC), polynomial 0 1 2 8.
    //
    Bit#(8) hash;
    hash[0] = d[7] ^ d[6] ^ d[0];
    hash[1] = d[6] ^ d[1] ^ d[0];
    hash[2] = d[6] ^ d[2] ^ d[1] ^ d[0];
    hash[3] = d[7] ^ d[3] ^ d[2] ^ d[1];
    hash[4] = d[4] ^ d[3] ^ d[2];
    hash[5] = d[5] ^ d[4] ^ d[3];
    hash[6] = d[6] ^ d[5] ^ d[4];
    hash[7] = d[7] ^ d[6] ^ d[5];

    return hash;

endfunction


function Bit#(8) hash8_inv(Bit#(8) d);
    //
    // Inverse of hash8
    //
    Bit#(8) hash;
    hash[0] = d[7] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[1] = d[7] ^ d[6] ^ d[4] ^ d[3];
    hash[2] = d[2] ^ d[1];
    hash[3] = d[3] ^ d[2] ^ d[0];
    hash[4] = d[4] ^ d[3] ^ d[1] ^ d[0];
    hash[5] = d[5] ^ d[4] ^ d[2] ^ d[1];
    hash[6] = d[6] ^ d[5] ^ d[3] ^ d[2] ^ d[0];
    hash[7] = d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[1] ^ d[0];

    return hash;

endfunction


//
// Multiple variants of 8 bit hashes, useful for Bloom filters.
//

function Bit#(8) hash8a(Bit#(8) d);
    //
    // CRC-8 (CCITT), polynomial 0 2 3 7 8.
    //
    Bit#(8) hash;
    hash[0] = d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[1] = d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1];
    hash[2] = d[6] ^ d[5] ^ d[1] ^ d[0];
    hash[3] = d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[0];
    hash[4] = d[7] ^ d[5] ^ d[4] ^ d[1];
    hash[5] = d[6] ^ d[5] ^ d[2];
    hash[6] = d[7] ^ d[6] ^ d[3];
    hash[7] = d[7] ^ d[3] ^ d[2] ^ d[1] ^ d[0];

    return hash;

endfunction

function Bit#(8) hash8a_inv(Bit#(8) d);
    //
    // Inverse of hash8a
    //
    Bit#(8) hash;
    hash[0] = d[6] ^ d[5] ^ d[4] ^ d[0];
    hash[1] = d[7] ^ d[6] ^ d[5] ^ d[1] ^ d[0];
    hash[2] = d[7] ^ d[5] ^ d[4] ^ d[2] ^ d[1];
    hash[3] = d[4] ^ d[3] ^ d[2];
    hash[4] = d[5] ^ d[4] ^ d[3] ^ d[0];
    hash[5] = d[6] ^ d[5] ^ d[4] ^ d[1];
    hash[6] = d[7] ^ d[6] ^ d[5] ^ d[2];
    hash[7] = d[7] ^ d[5] ^ d[4] ^ d[3];

    return hash;

endfunction


function Bit#(8) hash8b(Bit#(8) d);
    //
    // CRC-8 (Dallas/Maxim), polynomial 0 4 5 8.
    //
    Bit#(8) hash;
    hash[0] = d[6] ^ d[4] ^ d[3] ^ d[0];
    hash[1] = d[7] ^ d[5] ^ d[4] ^ d[1];
    hash[2] = d[6] ^ d[5] ^ d[2];
    hash[3] = d[7] ^ d[6] ^ d[3];
    hash[4] = d[7] ^ d[6] ^ d[3] ^ d[0];
    hash[5] = d[7] ^ d[6] ^ d[3] ^ d[1] ^ d[0];
    hash[6] = d[7] ^ d[4] ^ d[2] ^ d[1];
    hash[7] = d[5] ^ d[3] ^ d[2];

    return hash;

endfunction


function Bit#(8) hash8b_inv(Bit#(8) d);
    //
    // Inverse of hash8b
    //
    Bit#(8) hash;
    hash[0] = d[4] ^ d[3];
    hash[1] = d[5] ^ d[4];
    hash[2] = d[6] ^ d[5] ^ d[0];
    hash[3] = d[7] ^ d[6] ^ d[1];
    hash[4] = d[7] ^ d[4] ^ d[3] ^ d[2] ^ d[0];
    hash[5] = d[5] ^ d[1] ^ d[0];
    hash[6] = d[6] ^ d[2] ^ d[1];
    hash[7] = d[7] ^ d[3] ^ d[2];

    return hash;

endfunction


function Bit#(8) hash8c(Bit#(8) d);
    //
    // CRC-8 (SAE J1850), polynomial 0 2 3 4 8.
    //
    Bit#(8) hash;
    hash[0] = d[6] ^ d[5] ^ d[4] ^ d[0];
    hash[1] = d[7] ^ d[6] ^ d[5] ^ d[1];
    hash[2] = d[7] ^ d[5] ^ d[4] ^ d[2] ^ d[0];
    hash[3] = d[4] ^ d[3] ^ d[1] ^ d[0];
    hash[4] = d[6] ^ d[2] ^ d[1] ^ d[0];
    hash[5] = d[7] ^ d[3] ^ d[2] ^ d[1];
    hash[6] = d[4] ^ d[3] ^ d[2];
    hash[7] = d[5] ^ d[4] ^ d[3];

    return hash;

endfunction


function Bit#(8) hash8c_inv(Bit#(8) d);
    //
    // Inverse of hash8c
    //
    Bit#(8) hash;
    hash[0] = d[6] ^ d[5] ^ d[1] ^ d[0];
    hash[1] = d[7] ^ d[6] ^ d[2] ^ d[1] ^ d[0];
    hash[2] = d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[2];
    hash[3] = d[7] ^ d[5] ^ d[4] ^ d[3] ^ d[1];
    hash[4] = d[4] ^ d[2] ^ d[1];
    hash[5] = d[5] ^ d[3] ^ d[2];
    hash[6] = d[6] ^ d[4] ^ d[3];
    hash[7] = d[7] ^ d[5] ^ d[4] ^ d[0];

    return hash;

endfunction


function Bit#(8) hash8d(Bit#(8) d);
    //
    // CRC-8, polynomial 0 2 4 6 7 8.
    //
    Bit#(8) hash;
    hash[0] = d[7] ^ d[6] ^ d[3] ^ d[1] ^ d[0];
    hash[1] = d[7] ^ d[4] ^ d[2] ^ d[1];
    hash[2] = d[7] ^ d[6] ^ d[5] ^ d[2] ^ d[1] ^ d[0];
    hash[3] = d[7] ^ d[6] ^ d[3] ^ d[2] ^ d[1];
    hash[4] = d[6] ^ d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[5] = d[7] ^ d[5] ^ d[3] ^ d[2] ^ d[1];
    hash[6] = d[7] ^ d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[7] = d[7] ^ d[6] ^ d[5] ^ d[2] ^ d[0];

    return hash;

endfunction


function Bit#(8) hash8d_inv(Bit#(8) d);
    //
    // Inverse of hash8d
    //
    Bit#(8) hash;
    hash[0] = d[6] ^ d[1];
    hash[1] = d[7] ^ d[2];
    hash[2] = d[6] ^ d[3] ^ d[1] ^ d[0];
    hash[3] = d[7] ^ d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[4] = d[6] ^ d[5] ^ d[3] ^ d[2];
    hash[5] = d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[0];
    hash[6] = d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[0];
    hash[7] = d[7] ^ d[5] ^ d[0];

    return hash;

endfunction


function Bit#(7) hash7(Bit#(7) d);
    //
    // CRC-7, polynomial 0 3 7.
    //
    Bit#(7) hash;
    hash[0] = d[4] ^ d[0];
    hash[1] = d[5] ^ d[1];
    hash[2] = d[6] ^ d[2];
    hash[3] = d[4] ^ d[3] ^ d[0];
    hash[4] = d[5] ^ d[4] ^ d[1];
    hash[5] = d[6] ^ d[5] ^ d[2];
    hash[6] = d[6] ^ d[3];

    return hash;

endfunction


function Bit#(7) hash7_inv(Bit#(7) d);
    //
    // Inverse of hash7
    //
    Bit#(7) hash;
    hash[0] = d[4] ^ d[1] ^ d[0];
    hash[1] = d[5] ^ d[2] ^ d[1];
    hash[2] = d[6] ^ d[3] ^ d[2] ^ d[0];
    hash[3] = d[3] ^ d[0];
    hash[4] = d[4] ^ d[1];
    hash[5] = d[5] ^ d[2];
    hash[6] = d[6] ^ d[3] ^ d[0];

    return hash;

endfunction


function Bit#(6) hash6(Bit#(6) d);
    //
    // CRC-6 (ITU), polynomial 0 1 6.
    //
    Bit#(6) hash;
    hash[0] = d[5] ^ d[0];
    hash[1] = d[5] ^ d[1] ^ d[0];
    hash[2] = d[2] ^ d[1];
    hash[3] = d[3] ^ d[2];
    hash[4] = d[4] ^ d[3];
    hash[5] = d[5] ^ d[4];

    return hash;

endfunction


function Bit#(6) hash6_inv(Bit#(6) d);
    //
    // Inverse of hash6
    //
    Bit#(6) hash;
    hash[0] = d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1];
    hash[1] = d[1] ^ d[0];
    hash[2] = d[2] ^ d[1] ^ d[0];
    hash[3] = d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[4] = d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[5] = d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];

    return hash;

endfunction


function Bit#(5) hash5(Bit#(5) d);
    //
    // CRC-5 (USB), polynomial 0 2 5.
    //
    Bit#(5) hash;
    hash[0] = d[3] ^ d[0];
    hash[1] = d[4] ^ d[1];
    hash[2] = d[3] ^ d[2] ^ d[0];
    hash[3] = d[4] ^ d[3] ^ d[1];
    hash[4] = d[4] ^ d[2];

    return hash;

endfunction


function Bit#(5) hash5_inv(Bit#(5) d);
    //
    // Inverse of hash5
    //
    Bit#(5) hash;
    hash[0] = d[3] ^ d[1] ^ d[0];
    hash[1] = d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[2] = d[2] ^ d[0];
    hash[3] = d[3] ^ d[1];
    hash[4] = d[4] ^ d[2] ^ d[0];

    return hash;

endfunction


function Bit#(4) hash4(Bit#(4) d);
    //
    // CRC-4 (ITU), polynomial 0 1 4.
    //
    Bit#(4) hash;
    hash[0] = d[3] ^ d[0];
    hash[1] = d[3] ^ d[1] ^ d[0];
    hash[2] = d[2] ^ d[1];
    hash[3] = d[3] ^ d[2];

    return hash;

endfunction


function Bit#(4) hash4_inv(Bit#(4) d);
    //
    // Inverse of hash4
    //
    Bit#(4) hash;
    hash[0] = d[3] ^ d[2] ^ d[1];
    hash[1] = d[1] ^ d[0];
    hash[2] = d[2] ^ d[1] ^ d[0];
    hash[3] = d[3] ^ d[2] ^ d[1] ^ d[0];

    return hash;

endfunction
