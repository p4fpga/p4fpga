/*
 * Copyright  (c) 2011, 2012, 2013 University of Pennsylvania
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without a
 * written agreement is hereby granted, provided that the above copyright
 * notice and this paragraph and the following two paragraphs appear in
 * all copies.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF PENNSYLVANIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF PENNSYLVANIA
 * HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF PENNSYLVANIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON
 * AN "AS IS" BASIS, AND THE UNIVERSITY OF PENNSYLVANIA HAS NO OBLIGATIONS TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

/* A fully parameterized dMHC Implementation ***/
/*	       parameterized by:
				- dMHC type, <TYPE>, defined as a macro
				- number of entries, N
				- num hash functions, k
				- sparsity factor, c
				- key width, Kw
				- data width, Dw

Assuming Virtex6 style 36kb BRAMs in 32x1024 mode,
	BRAMs consumed = k*(ceil((Kw+Dw+2log2(N)+2)/32) * ceil(cN/1024))
			 + (ceil((Kw+Dw)/32) * ceil(N/1024))

Author: Udit Dhawan IC Group, University of Pennsylvania
*/

package DMHC;

import GetPut::*;
import FIFO::*;
import Vector::*;
import HashUnit::*;
import BRAMCore::*;
import StmtFSM::*;

interface DMHCIfc#(numeric type num_entries, numeric type k, numeric type c, numeric type key_width, numeric type value_width);
	method Bool is_enabled();
	method Action flush();
	method Action lookup_key(Key#(key_width) key);
	method Value#(value_width) get_value();
	method Bool is_hit();
	method Action new_key_value(Key#(key_width) k, Value#(value_width) v);
endinterface

typedef Bit#(key_width) Key#(numeric type key_width);
typedef Bit#(value_width) Value#(numeric type value_width);
typedef Bit#(TLog#(TMul#(c, num_entries))) G_Addr#(numeric type c, numeric type num_entries);
typedef Bit#(TLog#(num_entries)) M_Addr#(numeric type num_entries);

typedef struct {
	Value#(value_width) value;
	M_Addr#(num_entries) maddr;	//mtable address for the current key-value
	M_Addr#(num_entries) mslot;	//address of the key that most recently used this g_slot
	Bit#(2) degree;
} G_Slot#(numeric type num_entries, numeric type key_width, numeric type value_width) deriving (Bits, Eq, Bounded);
typedef struct {
	Bit#(1) valid;
	Key#(key_width) key;
	Value#(value_width) value;
	//Bit#(16) hit_count;
} M_Slot#(numeric type key_width, numeric type value_width) deriving (Bits, Eq, Bounded);

module mkDMHC(DMHCIfc#(num_entries, k, c, key_width, value_width))
	provisos(Add#(a__, TLog#(TMul#(c, num_entries)), key_width));

	`include "BitManipulation.bsv"
	`include "HashFns.bsv"
  	`include "Primes.bsv"

	/*************** MODULE INSTANTIATIONS ******************/
	Vector#(k, HashUnitIfc#(Key#(key_width), G_Slot#(num_entries, key_width, value_width), G_Addr#(c, num_entries))) hash_units;
	Vector#(k, function G_Addr#(c, num_entries) hash(Key#(key_width) abc)) hashes;
	hashes[0] = hash0;
	hashes[1] = hash1;
	hashes[2] = hash2;
	hashes[3] = hash3;	//define more hashes if need k>4
	for(Integer i=0; i<valueof(k); i=i+1) begin
		hash_units[i] <- mkHashUnit(hashes[i]);//, primes[i]);
	end

	BRAM_DUAL_PORT#(M_Addr#(num_entries), M_Slot#(key_width, value_width)) m_table <- mkBRAMCore2(valueOf(num_entries), False);

	Reg#(Bool) inited <- mkReg(False);
	Reg#(Bit#(2)) stage <- mkReg(0);
	Reg#(Bool) miss_service <- mkReg(False);
	
	Reg#(M_Addr#(num_entries)) mslot_counter <- mkReg(0);

	Wire#(Bool) is_hit_wire <- mkDWire(False);

	//Wire#(Key#(key_width)) rec_key <- mkBypassWire;
	Wire#(Value#(value_width)) rec_value <- mkDWire(unpack(0));

	//registers and state for replacement...	
	Reg#(M_Slot#(key_width, value_width)) evictee_mslot <- mkRegU;
	Vector#(k, Reg#(G_Addr#(c,num_entries))) evictee_hvals <- replicateM(mkRegU);
	Vector#(k, Reg#(G_Slot#(num_entries, key_width, value_width))) evictee_gslots <- replicateM(mkRegU);

	Reg#(M_Slot#(key_width, value_width)) repair_mslot <- mkRegU;
	Vector#(k, Reg#(G_Addr#(c,num_entries))) repair_hvals <- replicateM(mkRegU);
	Vector#(k, Reg#(G_Slot#(num_entries, key_width, value_width))) repair_gslots <- replicateM(mkRegU);
	Reg#(Bit#(TLog#(k))) repair_g_index <- mkRegU;
	Reg#(G_Slot#(num_entries, key_width, value_width)) repair_gslot <- mkRegU;

	Reg#(M_Slot#(key_width, value_width)) new_mslot <- mkRegU;
	Vector#(k, Reg#(G_Addr#(c,num_entries))) new_hvals <- replicateM(mkRegU);
	Vector#(k, Reg#(G_Slot#(num_entries, key_width, value_width))) new_gslots <- replicateM(mkRegU);
	Reg#(G_Slot#(num_entries, key_width, value_width)) victim_gslot <- mkRegU;
	Reg#(Bit#(TLog#(k))) victim_g_index <- mkRegU;
	Reg#(M_Slot#(key_width, value_width)) victim_mslot <- mkRegU;
	Reg#(M_Addr#(num_entries)) victim_mslot_addr <- mkRegU;
	Reg#(M_Slot#(key_width, value_width)) mslot_to_repair <- mkRegU;

    FIFO#(Key#(key_width)) stage1_ff <- mkFIFO;
    FIFO#(Key#(key_width)) stage2_ff <- mkFIFO;

	`include "MissServiceFSM.bsv"

	/*** rules ***/
	// always inited the g and m tables to zeros before starting
    // g tables larger than m table...
    rule init_tables(!inited);
       if(mslot_counter < ~0) begin
          m_table.b.put(True, mslot_counter, unpack(0));
          mslot_counter <= mslot_counter + 1;
       end
       else begin
          let gtables_ready = hash_units[0].is_ready;
          if(gtables_ready) begin
             inited <= True;
             m_table.b.put(True, ~0, unpack(0));
             mslot_counter <= 0;
          end
       end
    endrule

    // change FSM to pipeline fifo
	rule lookup_gtables if (inited);
       let req <- toGet(stage1_ff).get;
		Vector#(k, G_Slot#(num_entries, key_width, value_width)) g_slots;
		for(Integer i=0; i<valueof(k); i=i+1) begin
			g_slots[i] <- hash_units[i].get_gslot();
		end
		M_Addr#(num_entries) re_maddr = unpack(0);
		Value#(value_width) re_value = unpack(0);
		for(Integer j=0; j<valueof(k); j=j+1) begin
			re_maddr = re_maddr ^ g_slots[j].maddr;
			re_value = re_value ^ g_slots[j].value;
		end
		rec_value <= re_value;
		$display("[%d]: mslot addr: %d", $time, re_maddr);
		m_table.a.put(False, re_maddr, ?);
        stage2_ff.enq(req);
	endrule

    // latency of 2
    rule lookup_mtable if (inited);
       let req <- toGet(stage2_ff).get;
       let mslot = m_table.a.read;
       $display("[%d]: mslot.key: %d, mslot.value: %d", $time, mslot.key, mslot.value);
       //check if there was a hit...
       if(req == mslot.key) begin
          is_hit_wire <= True;
       end
       else begin
          is_hit_wire <= False;
       end
    endrule

   /** methods **/	
   method Bool is_enabled();
       return inited;
   endmethod

   // lookup key
   method Action lookup_key(Key#(key_width) key) if (inited);
      stage1_ff.enq(key);
      for(Integer i=0; i<valueof(k); i=i+1) begin
         let tmp <- hash_units[i].compute_hash(key);
      end
   endmethod

   //for a {flat, fast-value dMHC}, you get the value in the cycle after you give the input key. this is not latched, so has to be read in the next cycle. for the two-level dmhc, you get the value 2 cycles after the key input. this synchronization is left to the module instantiating this module.
   method Value#(value_width) get_value();
      return rec_value;
   endmethod

   method Bool is_hit();
      return is_hit_wire;
   endmethod

   method Action new_key_value(Key#(key_width) k, Value#(value_width) v) if (inited);
      // disable table when inserting new entry ??
      if(!miss_service) begin
         new_mslot <= unpack(pack({1, k, v}));
         //start the replacement FSM...
         miss_service <= True;
         m_table.b.put(False, mslot_counter, ?);
         mslot_replacement.start;
      end
   endmethod
endmodule

endpackage
