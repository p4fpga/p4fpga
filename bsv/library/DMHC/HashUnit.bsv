// BSV Module for a Hash function for the  dMHC architecture.

package HashUnit;

import BRAMCore::*;

//interface definition
interface HashUnitIfc#(type key_type, type gslot_type, type gaddr_type);
	method Action flush();
	method Bool is_ready();
	method ActionValue#(gaddr_type) compute_hash(key_type key);
	method ActionValue#(gslot_type) get_gslot();
	method Action set_gslot (gaddr_type gaddr, gslot_type gslot);
endinterface

//(* synthesize *) 	/*** cannot synthesize a parameteric module ***/
module mkHashUnit#(function gaddr_type hash_fn(key_type key)) 
	(HashUnitIfc#(key_type, gslot_type, gaddr_type))
	provisos(Bitwise#(gaddr_type), Bits#(gaddr_type, a__), Bits#(gslot_type, b__), Arith#(gaddr_type), Eq#(gaddr_type));

	BRAM_DUAL_PORT#(gaddr_type, gslot_type) g_table <- mkBRAMCore2(2 ** valueof(SizeOf#(gaddr_type)), False);

	Reg#(gaddr_type) gslot_counter <- mkReg(0);
	Reg#(Bool) init <- mkReg(False);
	Reg#(Bool) is_miss <- mkReg(False);

        rule init_table(!init);
		g_table.b.put(True, gslot_counter, unpack(0));
		if(gslot_counter == unpack(~0))
		begin
			init <= True;
		end
		else begin
			gslot_counter <= gslot_counter + 1;
		end
        endrule


	/** methods **/
	method Action flush();
                gslot_counter <= 0;
		init <= False;
	endmethod

	method Bool is_ready();
		return init;
	endmethod

	method ActionValue#(gaddr_type) compute_hash(key_type key);
		gaddr_type hash_val = hash_fn(key);
		g_table.a.put(False, hash_val, ?);

		return hash_val;
	endmethod

	method ActionValue#(gslot_type) get_gslot();
		return  g_table.a.read;
	endmethod

	method Action set_gslot (gaddr_type gaddr, gslot_type gslot) if (init);
		g_table.b.put(True, gaddr, gslot);
	endmethod

endmodule
endpackage
