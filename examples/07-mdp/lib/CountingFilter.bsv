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

// Library imports.
import BaseDef::*;
import Extends::*;
import HashBits::*;

import ConfigReg::*;
import RegFile::*;
import Vector::*;
import RWire::*;

//
// Counting filters can be used to determine whether an entry is present in
// a set.  All counting filters have both test(), set() and remove() methods.
// This module provides multiple implementations for sets of varying sizes.
// Smaller sets can use direct decode filters.  Larger sets can use Bloom
// filters, which have more logic to deal with hashes but have good false
// positive rates with relatively small filter vector sizes.
//
// For automatic selection of a reasonable filter, use the mkCountingFilter
// module.  It picks decode filters for smaller sets and Bloom filters for
// larger sets.
//
// t_OPAQUE is used internally by counting filter implementations to pass
// state from test() to set().  The type may vary for different implementations.
// Each implementation must provide a typedef for defining t_OPAQUE.
//
interface COUNTING_FILTER_IFC#(type t_ENTRY, type t_OPAQUE);
    // Test whether a new entry may be added to the current state.
    // Returns Valid when the entry may be added along with some internal,
    // implementation-dependent, state to pass to the set() method.
    // Multiple test() calls may be scheduled in parallel (though this
    // may have high hardware costs).  However, set() may be called
    // for only one successful test() and once set() is called all
    // earlier test() results must be considered invalid.
    method Maybe#(t_OPAQUE) test(t_ENTRY newEntry);

    // When test() has said an element may be added, request addition of
    // the element by passing the result of the test() call.  Implementations
    // don't necessarily re-confirm that the element may be added, so
    // clients must be careful only to call set() for legal additions.
    // As noted for test(), once set() is called clients must not use the
    // results of any earlier test() responses.
    method Action set(t_OPAQUE stateUpdate);

    // Remove an entry from the filter.
    method Action remove(t_ENTRY oldEntry);

    // Test whether entry is busy
    method Bool notSet(t_ENTRY entry);

    // Clear filter
    method Action reset();

    method Action set_verbosity(int verbosity);
endinterface


// ========================================================================
//
//   Generic counting filter implementation.  mkCountingFilter tailors
//   the algorithm to the size of the set, picking counting Bloom filters
//   for large sets and decode filters for small sets.
//
// ========================================================================

// Private types used to compute the type of filter to employ in the
// standard implementation of mkCountingFilter.  Static elaboration using
// ifs would be preferable, but types are needed in order to set the size
// of t_OPAQUE.
//
// tF_OPAQUE stores the state passed between the test() and set() methods
// in order to avoid recomputing logic required by both methods.
//

// Use couting Bloom filter when the entry size is larger than 10 bits.
typedef TGT#(SizeOf#(t_ENTRY), 10) CF_USE_BLOOM#(type t_ENTRY);

// State of the appropriate filter for the t_ENTRY size
typedef Bit#(TSelect#(TAnd#(CF_USE_BLOOM#(t_ENTRY), permitComplexFilter),
                      SizeOf#(BLOOM_FILTER_STATE#(128)),
                      SizeOf#(DECODE_FILTER_STATE#(t_ENTRY))))
    CF_OPAQUE#(type t_ENTRY, numeric type permitComplexFilter);


//
// COUNTING_FILTER is the interface of a mkCountingFilter, derived from
// COUNTING_FILTER_IFC.
//
typedef COUNTING_FILTER_IFC#(t_ENTRY, CF_OPAQUE#(t_ENTRY, permitComplexFilter))
    COUNTING_FILTER#(type t_ENTRY, numeric type permitComplexFilter);

//
// mkCountingFilter --
//   Pick a reasonable filter based on the entry set size.  Uses a Bloom filter
//   for large sets and a simple decode filter for smaller sets.
//
module mkCountingFilter
    // interface:
    (COUNTING_FILTER#(t_ENTRY, permitComplexFilter))
    provisos (Bits#(t_ENTRY, t_ENTRY_SZ));

    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
       action
       if (cf_verbosity > fromInteger(level)) begin
          $display("(%0d) ", $time, msg);
       end
       endaction
    endfunction

    if (valueOf(TAnd#(CF_USE_BLOOM#(t_ENTRY), permitComplexFilter)) != 0)
    begin
        // Large sets use Bloom filters
        COUNTING_BLOOM_FILTER#(t_ENTRY, 128, 2) filter <- mkCountingBloomFilter();

        method Maybe#(CF_OPAQUE#(t_ENTRY, permitComplexFilter)) test(t_ENTRY newEntry) = sameSizeNP(filter.test(newEntry));
        method Action set(CF_OPAQUE#(t_ENTRY, permitComplexFilter) stateUpdate) = filter.set(sameSizeNP(stateUpdate));
        method Action remove(t_ENTRY oldEntry) = filter.remove(oldEntry);
        method Bool notSet(t_ENTRY entry) = filter.notSet(entry);
        method Action reset() = filter.reset;
        method Action set_verbosity(int verbosity) = filter.set_verbosity(verbosity);
    end
    else
    begin
        // Smaller sets use decode filters
        let filter = ?;

        if (valueOf(t_ENTRY_SZ) > 7)
        begin
            // Medium sized sets share 2 bits per entry
            DECODE_FILTER#(t_ENTRY, TDiv#(TExp#(t_ENTRY_SZ), 2)) decodeFilterL <- mkSizedDecodeFilter();
            filter = decodeFilterL;
        end
        else
        begin
            // Small sets get unique bit per entry
            DECODE_FILTER#(t_ENTRY, TExp#(t_ENTRY_SZ)) decodeFilterS <- mkSizedDecodeFilter();
            filter = decodeFilterS;
        end

        method Maybe#(CF_OPAQUE#(t_ENTRY, permitComplexFilter)) test(t_ENTRY newEntry) = sameSizeNP(filter.test(newEntry));
        method Action set(CF_OPAQUE#(t_ENTRY, permitComplexFilter) stateUpdate) = filter.set(sameSizeNP(stateUpdate));
        method Action remove(t_ENTRY oldEntry) = filter.remove(oldEntry);
        method Bool notSet(t_ENTRY entry) = filter.notSet(entry);
        method Action reset() = filter.reset;
        method Action set_verbosity(int verbosity) = filter.set_verbosity(verbosity);
    end
endmodule


// ========================================================================
//
// Decode Filter
//
// ========================================================================

// nFilterBits should be a power of 2!
typedef COUNTING_FILTER_IFC#(t_ENTRY, DECODE_FILTER_STATE#(t_ENTRY))
    DECODE_FILTER#(type t_ENTRY, numeric type nFilterBits);

// State passed from test() to set() methods.  Because of the messy opaque
// type above derived from DECODE_FILTER_STATE Bluespec only permits this to
// be bits.
typedef Bit#(TAdd#(1, SizeOf#(t_ENTRY)))
    DECODE_FILTER_STATE#(type t_ENTRY);


//
// Decode filter with one bit corresponding to one or more entries.
// Insert and remove methods may both be called in the same cycle.
//
module mkSizedDecodeFilter
    // interface:
    (DECODE_FILTER#(t_ENTRY, nFilterBits))
    provisos (Bits#(t_ENTRY, t_ENTRY_SZ),
              Alias#(Bit#(TLog#(nFilterBits)), t_FILTER_IDX));

    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
       action
       if (cf_verbosity > fromInteger(level)) begin
          $display("(%0d) ", $time, msg);
       end
       endaction
    endfunction

    if (valueOf(t_ENTRY_SZ) < valueOf(TLog#(nFilterBits)))
    begin
        t_ENTRY dummy = ?;
        error("mkSizedDecodeFilter:  filter is larger than needed: " +
              integerToString(valueOf(nFilterBits)) + " entries for a " +
              printType(typeOf(dummy)));
    end

    // The filter is implemented as a pair of bit vectors.  Bits in the "in"
    // vector are toggled when an entry is added to the active set.  Bits in
    // the "out" vector are toggled when an entry is removed from the active
    // set.  An entry is active when an in bit differs from an out bit.
    RegFile#(Bit#(TLog#(nFilterBits)), Bit#(1)) fvIn <- mkRegFileFull;
    RegFile#(Bit#(TLog#(nFilterBits)), Bit#(1)) fvOut <- mkRegFileFull;

    Reg#(Bool) ready <- mkReg(False);
    Reg#(Bit#(TLog#(nFilterBits))) initIdx <- mkReg(0);
    
    rule init (! ready);
        fvIn.upd(initIdx, 0);
        fvOut.upd(initIdx, 0);

        ready <= (initIdx == maxBound);
        initIdx <= initIdx + 1;
    endrule


    RWire#(Tuple2#(Bit#(1), t_FILTER_IDX)) insertId <- mkRWire();
    RWire#(t_FILTER_IDX) removeId <- mkRWire();


    function t_FILTER_IDX filterIdx(t_ENTRY e);
        return truncateNP(pack(e));
    endfunction

    (* fire_when_enabled, no_implicit_conditions *)
    rule updateInFilter (ready &&& insertId.wget() matches tagged Valid {.fvIn_cur, .id});
        fvIn.upd(id, fvIn_cur ^ 1);
    endrule

    (* fire_when_enabled, no_implicit_conditions *)
    rule updateOutFilter (ready &&& removeId.wget() matches tagged Valid .id);
        fvOut.upd(id, fvOut.sub(id) ^ 1);
    endrule


    method Maybe#(DECODE_FILTER_STATE#(t_ENTRY)) test(t_ENTRY newEntry) if (ready);
        let id = filterIdx(newEntry);
        let fvIn_val = fvIn.sub(id);

        let state = pack(tuple2(fvIn_val, newEntry));
        return (fvIn_val == fvOut.sub(id)) ? tagged Valid state : tagged Invalid;
    endmethod

    method Action set(DECODE_FILTER_STATE#(t_ENTRY) newEntry) if (ready);
        Tuple2#(Bit#(1), t_ENTRY) upd_state = unpack(newEntry);
        match {.fvIn_cur, .entry} = upd_state;
        let id = filterIdx(entry);

        insertId.wset(tuple2(fvIn_cur, id));
        dbprint(3, $format("    Decode filter SET %0d OK, idx=%0d", entry, id));
    endmethod

    method Action remove(t_ENTRY oldEntry) if (ready);
        let id = filterIdx(oldEntry);
        removeId.wset(id);
        dbprint(3, $format("    Decode filter REMOVE %0d, idx=%0d", oldEntry, id));
    endmethod

    method Bool notSet(t_ENTRY entry) if (ready);
        let id = filterIdx(entry);
        return (fvIn.sub(id) == fvOut.sub(id));
    endmethod

    method Action reset() if (ready);
        ready <= False;
        initIdx <= 0;
    endmethod

    method Action set_verbosity (int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule



// ========================================================================
//
// Counting Bloom Filter
//
// ========================================================================


typedef COUNTING_FILTER_IFC#(t_ENTRY, BLOOM_FILTER_STATE#(nFilterBits))
    COUNTING_BLOOM_FILTER#(type t_ENTRY,
                           numeric type nFilterBits,
                           numeric type nCounterBits);

// State passed from test() to set() methods.
typedef Vector#(4, Bit#(TLog#(nFilterBits)))
    BLOOM_FILTER_STATE#(numeric type nFilterBits);

//
// Counting Bloom filter up to 256 bits.
//
module mkCountingBloomFilter
    // interface:
    (COUNTING_BLOOM_FILTER#(t_ENTRY, nFilterBits, nCounterBits))
    provisos (Bits#(t_ENTRY, t_ENTRY_SZ),
              Alias#(Bit#(TLog#(nFilterBits)), t_FILTER_IDX),

              // nFilterBits must be <= 256 and a power of 2.
              Add#(TLog#(nFilterBits), a__, 8),
              Add#(nFilterBits, 0, TExp#(TLog#(nFilterBits))),

              Alias#(Vector#(4, t_FILTER_IDX), t_FILTER_HASHES),
              Alias#(BLOOM_FILTER_STATE#(nFilterBits), t_FILTER_STATE));

    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
       action
       if (cf_verbosity > fromInteger(level)) begin
          $display("(%0d) ", $time, msg);
       end
       endaction
    endfunction

    // The counters associated with each hash are stored independently in
    // separate LUTRAMs.  This allows us to use memories with a single
    // write port that are much more efficient than LUT-based vectors.
    // Like the decode filter, counter RAMs are separated into "in"
    // and "out" vectors in order to double the write bandwidth while
    // still using RAMS with one write port.  "In" is updated by the
    // set() method and "out" by remove().
    Vector#(4, RegFile#(t_FILTER_IDX, Bit#(nCounterBits))) bfIn <- replicateM(mkRegFileFull);
    Vector#(4, RegFile#(t_FILTER_IDX, Bit#(nCounterBits))) bfOut <- replicateM(mkRegFileFull);

    // bfUpd is used to delay updates to bfIn by a cycle in order to reduce
    // timing pressure.
    Reg#(Maybe#(t_FILTER_HASHES)) bfUpd <- mkRegU();

    // Insert and remove requests are passed on wires to internal rules
    // to control the use of LUTRAM ports.
    RWire#(t_FILTER_HASHES) insertEntryW <- mkRWire();
    RWire#(t_ENTRY) removeEntryW <- mkRWire();

    //
    // computeHashes --
    //     Calculate the Bloom filter hash values for an entry.
    //
    function t_FILTER_HASHES computeHashes(t_ENTRY entryId);
        //
        // Map however many entry bits there are to 32 bits.  This hash function
        // is a compromise for FPGA area.  It works well for current functional
        // memory set sizes.  We may need to revisit it later.
        //
        Vector#(TDiv#(32, t_ENTRY_SZ), t_ENTRY) entry_rep = replicate(entryId);
        Bit#(32) idx32 = truncateNP(pack(entry_rep));

        // Get four 8 bit hashes.  The optimal number is probably 5 or 6 but
        // the FPGA area required is too large.
        t_FILTER_HASHES hash = newVector();
        hash[0] = truncate(idx32[7:0]);
        hash[1] = truncate(hash8a(idx32[15:8]));
        hash[2] = truncate(hash8b(idx32[23:16]));
        hash[3] = truncate(hash8c(idx32[31:24]));
    
        return hash;
    endfunction

    // bfInVal is the sum of bfIn and any updates pending in bfUpd.
    function bfInVal(Integer position, t_FILTER_IDX hash);
        Bit#(1) bf_upd = 0;
        if (bfUpd matches tagged Valid .u &&&
            u[position] == hash)
        begin
            bf_upd = 1;
        end

        return bfIn[position].sub(hash) + zeroExtendNP(bf_upd);
    endfunction

    function counterIsZero(Integer position, t_FILTER_IDX hash);
        return (bfInVal(position, hash) == bfOut[position].sub(hash));
    endfunction

    // Would a counter overflow if incremented?
    function counterWouldOverflow(Integer position, t_FILTER_IDX hash);
        return (bfInVal(position, hash) + 1 == bfOut[position].sub(hash));
    endfunction

    function Bool isTrue(Bool b) = b;

    //
    // An entry is not set in the filter if any hash bucket is zero.
    //
    function Bool entryNotSet(t_FILTER_HASHES hashes);
        let not_set = zipWith(counterIsZero, genVector(), hashes);
        return any(isTrue, not_set);
    endfunction

    function Bool entryWouldCauseOverflow(t_FILTER_HASHES hashes);
        let would_overflow = zipWith(counterWouldOverflow, genVector(), hashes);
        return any(isTrue, would_overflow);
    endfunction


    Reg#(Bool) ready <- mkReg(False);
    Reg#(t_FILTER_IDX) initIdx <- mkReg(0);
    
    rule init (! ready);
        for (Integer i = 0; i < 4; i = i + 1)
        begin
            bfIn[i].upd(initIdx, 0);
            bfOut[i].upd(initIdx, 0);
        end

        bfUpd <= tagged Invalid;
        ready <= (initIdx == maxBound);
        initIdx <= initIdx + 1;
    endrule

    //
    // Add an entry to the filter.
    //
    (* fire_when_enabled, no_implicit_conditions *)
    rule insertEntry (ready &&& bfUpd matches tagged Valid .hashes);
        for (Integer i = 0; i < 4; i = i + 1)
        begin
            bfIn[i].upd(hashes[i], 1 + bfIn[i].sub(hashes[i]));
        end
    endrule

    (* fire_when_enabled, no_implicit_conditions *)
    rule recordInsertEntry (ready);
        bfUpd <= insertEntryW.wget();
    endrule

    //
    // Remove an entry from the filter.
    //
    (* fire_when_enabled, no_implicit_conditions *)
    rule removeEntry (ready &&& removeEntryW.wget() matches tagged Valid .oldEntry);
        let hashes = computeHashes(oldEntry);

        // Check to ensure that we aren't underflowing an entry.
        if (entryNotSet(hashes))
        begin
            $display("Counting Bloom Filter at %m, has underflowed while trying to remove %h %0d: h0=%0d, h1=%0d, h2=%0d, h3=%0d", oldEntry, oldEntry, hashes[0], hashes[1], hashes[2], hashes[3]);
            $finish;
        end

        for (Integer i = 0; i < 4; i = i + 1)
        begin           
            bfOut[i].upd(hashes[i], 1 + bfOut[i].sub(hashes[i]));
        end
    endrule


    method Maybe#(t_FILTER_STATE) test(t_ENTRY newEntry) if (ready);
        let hashes = computeHashes(newEntry);

        if (entryNotSet(hashes) && ! entryWouldCauseOverflow(hashes))
        begin
            // May insert
            return tagged Valid hashes;
        end
        else
        begin
            // Can't insert.
            return tagged Invalid;
        end

    endmethod

    method Action set(t_FILTER_STATE stateUpdate) if (ready);
        t_FILTER_HASHES hashes = stateUpdate;
        insertEntryW.wset(hashes);

        dbprint(3, $format("    Bloom filter SET: h0=%0d, h1=%0d, h2=%0d, h3=%0d", hashes[0], hashes[1], hashes[2], hashes[3]));
    endmethod

    method Action remove(t_ENTRY oldEntry) if (ready);
        removeEntryW.wset(oldEntry);

        dbprint(3, $format("    Bloom filter REMOVE %0d (0x%x)", oldEntry, oldEntry));
    endmethod

    method Bool notSet(t_ENTRY entry) if (ready);
        let hashes = computeHashes(entry);
        return entryNotSet(hashes);
    endmethod

    method Action reset() if (ready);
        ready <= False;
        initIdx <= 0;
    endmethod

    method Action set_verbosity(int verbosity);
       cf_verbosity <= verbosity;
    endmethod
endmodule
