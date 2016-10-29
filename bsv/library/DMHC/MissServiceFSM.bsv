/* Implementing LDV-1hop policy... */
/** **/

function Tuple2#(G_Slot#(num_entries, key_width, value_width), Bit#(TLog#(k))) find_ldv(Vector#(k, Reg#(G_Slot#(num_entries, key_width, value_width))) gslots);
	G_Slot#(num_entries, key_width, value_width) min_gslot = gslots[0];
	Bit#(TLog#(k)) min_g_index = unpack(0);

	for(Integer i=1; i<valueof(k); i=i+1) begin
		if(gslots[i].degree < min_gslot.degree) begin
			min_g_index = fromInteger(i);
			min_gslot = gslots[i];
		end
	end

	return tuple2(min_gslot, min_g_index);
endfunction


Stmt ldv_n = 
seq
	par
	action
		//get the tag slot to be repaired
		let mslot_tmp = m_table.a.read;
		mslot_to_repair <= mslot_tmp;
	endaction
	endpar

	par
	action
		//evictee_hvals now has repairee hash vals...
		Vector#(k, G_Addr#(c,num_entries)) hash_vals;
		for(Integer i=0; i<valueof(k); i=i+1) begin
			hash_vals[i] <- hash_units[i].compute_hash(mslot_to_repair.key);
			repair_hvals[i] <= hash_vals[i];
		end
	endaction
	endpar

	par 
	action	//get repairee g slots
		Vector#(k, G_Slot#(num_entries, key_width, value_width)) g_slots;
	
		for(Integer i=0; i<valueof(k); i=i+1) begin
			g_slots[i] <- hash_units[i].get_gslot();
			repair_gslots[i] <= g_slots[i];
		end
	endaction
	endpar

	par
	action
		let tmp = find_ldv(repair_gslots);
		repair_gslot <= tpl_1(tmp);
		repair_g_index <= tpl_2(tmp);
	endaction
	endpar

	par	//compute slot_xor ^ mslot_address
	action	//assign it to the ldv
		G_Slot#(num_entries, key_width, value_width) tmp_gslot = unpack(0);
		Vector#(k, G_Slot#(num_entries, key_width, value_width)) tmp_gslots;

		for(Integer j=0; j<valueof(k); j=j+1) begin	
			tmp_gslots[j] = repair_gslots[j];
		end

		for(Integer j=0; j<valueof(k); j=j+1) begin	
			if(fromInteger(j) != repair_g_index) begin
			`ifdef FLAT
				tmp_gslot.key = tmp_gslot.key ^ repair_gslots[j].key;
				tmp_gslot.value = tmp_gslot.value ^ repair_gslots[j].value;
			`elsif FAST_VALUE
				tmp_gslot.value = tmp_gslot.value ^ repair_gslots[j].value;
			`endif
				tmp_gslot.maddr = tmp_gslot.maddr ^ repair_gslots[j].maddr;
				tmp_gslots[j].mslot = victim_mslot_addr;
			end
		end

	`ifdef FLAT
		tmp_gslot.key = tmp_gslot.key ^ mslot_to_repair.key;
		tmp_gslot.value = tmp_gslot.value ^ mslot_to_repair.value;
	`elsif FAST_VALUE
		tmp_gslot.value = tmp_gslot.value ^ mslot_to_repair.value;
	`endif
		tmp_gslot.maddr = tmp_gslot.maddr ^ victim_mslot_addr;
		tmp_gslot.degree = 1;


		tmp_gslots[repair_g_index] = tmp_gslot;
		for(Integer j=0; j<valueof(k); j=j+1) begin	
			repair_gslots[j] <= tmp_gslots[j];
		end
	endaction
	endpar

	par
	action	// update all the gslots in their respective hash units
		for(Integer j=0; j<valueof(k); j=j+1) begin
			hash_units[j].set_gslot(repair_hvals[j], repair_gslots[j]);
		end
	endaction
	endpar

	par
	action
		miss_service <= False;
		inited <= True;
		stage <= 0;
	endaction
	endpar
endseq;
FSM ldvn <- mkFSM(ldv_n);
//FSM ldvn <- mkFSMWithPred(ldv_n, nHOP);


Stmt miss_server = 
seq
	par
	action	//get the (key,value) to be evicted
		let mslot_to_evict = m_table.a.read;
		evictee_mslot <= mslot_to_evict;
	endaction
	endpar

	par	//compute hashes on the evictee...
	action	
		Vector#(k, G_Addr#(c,num_entries)) hash_vals;
		for(Integer i=0; i<valueof(k); i=i+1) begin
			hash_vals[i] <- hash_units[i].compute_hash(evictee_mslot.key);
			evictee_hvals[i] <= hash_vals[i];
		end
	endaction
	endpar

	par	
	action	//read out the g slots of the eviction candidate
		Vector#(k, G_Slot#(num_entries, key_width, value_width)) g_slots;

		for(Integer i=0; i<valueof(k); i=i+1) begin
			g_slots[i] <- hash_units[i].get_gslot();
			evictee_gslots[i] <= g_slots[i];
		end
	endaction
	endpar

	par	//cleanup evictee's gslots...
	action
		if(evictee_mslot.valid==1) begin	//if evictee is valid, then clean up its g slots...
			for(Integer i=0; i<valueof(k); i=i+1) begin 
				if((evictee_gslots[i].degree==1) || (evictee_gslots[i].degree==0)) begin
					evictee_gslots[i] <= unpack(0);
				end
				else begin
					evictee_gslots[i].degree <= evictee_gslots[i].degree - 1;
				end
			end
		end
	endaction
	endpar

	par
	action
		for(Integer i=0; i<valueof(k); i=i+1) begin 
			hash_units[i].set_gslot(evictee_hvals[i], evictee_gslots[i]);
		end
	endaction
	endpar

	par
	action	// compute the hash on the new key...
		Vector#(k, G_Addr#(c,num_entries)) hash_vals;
		for(Integer i=0; i<valueof(k); i=i+1) begin
			hash_vals[i] <- hash_units[i].compute_hash(new_mslot.key);
			new_hvals[i] <= hash_vals[i];
		end
	endaction
	endpar

	par
	action	//read out the g slots to be used by the new key
		Vector#(k, G_Slot#(num_entries, key_width, value_width)) g_slots;
		for(Integer i=0; i<valueof(k); i=i+1) begin
			g_slots[i] <- hash_units[i].get_gslot();
			new_gslots[i] <= g_slots[i];
		end
	endaction
	endpar

	par
	action	//find the lowest degree victim G slot
		let tmp = find_ldv(new_gslots);
		victim_gslot <= tpl_1(tmp);
		victim_g_index <= tpl_2(tmp);
		victim_mslot_addr <= tpl_1(tmp).mslot;
	endaction
	endpar

	par	//compute slot_xor ^ mslot_counter	
	action	//assign it to the ldv
		G_Slot#(num_entries, key_width, value_width) tmp_gslot = unpack(0);
		Vector#(k, G_Slot#(num_entries, key_width, value_width)) tmp_gslots;

		for(Integer j=0; j<valueof(k); j=j+1) begin	
			tmp_gslots[j] = new_gslots[j];
		end


		for(Integer j=0; j<valueof(k); j=j+1) begin	
			if(fromInteger(j) != victim_g_index) begin
			`ifdef FLAT
				tmp_gslot.key = tmp_gslot.key ^ new_gslots[j].key;
				tmp_gslot.value = tmp_gslot.value ^ new_gslots[j].value;
			`elsif FAST_VALUE
				tmp_gslot.value = tmp_gslot.value ^ new_gslots[j].value;
			`endif
				tmp_gslot.maddr = tmp_gslot.maddr ^ new_gslots[j].maddr;
				tmp_gslots[j].degree = tmp_gslots[j].degree+1;
				tmp_gslots[j].mslot = mslot_counter;
			end
		end

	`ifdef FLAT
		tmp_gslot.key = tmp_gslot.key ^ new_mslot.key;
		tmp_gslot.value = tmp_gslot.value ^ new_mslot.value;
	`elsif FAST_VALUE
		tmp_gslot.value = tmp_gslot.value ^ new_mslot.value;
	`endif
		tmp_gslot.maddr = tmp_gslot.maddr ^ mslot_counter;
		tmp_gslot.mslot = mslot_counter;
		tmp_gslot.degree = 1;

		tmp_gslots[victim_g_index] = tmp_gslot;
		for(Integer j=0; j<valueof(k); j=j+1) begin	
			new_gslots[j] <= tmp_gslots[j];
		end

	endaction
	endpar

	par
	action	// update all the gslots in their respective hash units
		for(Integer j=0; j<valueof(k); j=j+1) begin
			hash_units[j].set_gslot(new_hvals[j], new_gslots[j]);
		end
	endaction
	endpar
         
	par
	action	//write to the mslot as well
		m_table.b.put(True, mslot_counter, new_mslot);
		mslot_counter <= mslot_counter + 1;
	endaction
	endpar

	par 
	action
	//incoming entry inserted...
	//stop here for LDV0...
	//try repairing the victim_mslot for LDV1 strategy...
		if(victim_gslot.degree==0) begin
			miss_service <= False;
			inited <= True;
			stage <= 0;
			$display("[%d]: new (key,value) inserted at slot %d\n", $time, mslot_counter-1);
		end
		else begin
			m_table.a.put(False, victim_mslot_addr, ?);
			ldvn.start;
		end
	endaction
	endpar

endseq;
FSM mslot_replacement <- mkFSM(miss_server);
