/************************************************************************************************
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
 ***********************************************************************************************/

/***
Hash functions for computing the hash on the input key, add more as you need

Author: Udit Dhawan
	IC Group, University of Pennsylvania
***/


function G_Addr#(c, num_entries) hash0(Key#(key_width) key);
	Integer num_key_parts = valueof(TDiv#(key_width, TLog#(TMul#(c, num_entries))));

	G_Addr#(c, num_entries) hash_val = 0;
	G_Addr#(c, num_entries) key_part = 0;

	G_Addr#(c, num_entries) mask = (1<<valueOf(TLog#(TMul#(c, num_entries)))) - 1;

	Integer temp = 0;

	for(Integer i=0; i<num_key_parts; i=i+1) begin	
		key_part = unpack(truncate(pack(key>>temp))) & mask;
		temp = temp + valueOf(TLog#(TMul#(c, num_entries)));
		hash_val = hash_val ^ f1(key_part);
	end

	return hash_val;
endfunction

function G_Addr#(c, num_entries) hash1(Key#(key_width) key);
	Integer num_key_parts = valueof(TDiv#(key_width, TLog#(TMul#(c, num_entries))));

	G_Addr#(c, num_entries) hash_val = 0;
	G_Addr#(c, num_entries) key_part = 0;

	G_Addr#(c, num_entries) mask = (1<<valueOf(TLog#(TMul#(c, num_entries)))) - 1;

	Integer temp = 0;

	for(Integer i=0; i<num_key_parts; i=i+1) begin	
		key_part = unpack(truncate(pack(key>>temp))) & mask;
		temp = temp + valueOf(TLog#(TMul#(c, num_entries)));
		hash_val = hash_val ^ f2(key_part);
	end

	return hash_val;
endfunction

function G_Addr#(c, num_entries) hash2(Key#(key_width) key);
	Integer num_key_parts = valueof(TDiv#(key_width, TLog#(TMul#(c, num_entries))));

	G_Addr#(c, num_entries) hash_val = 0;
	G_Addr#(c, num_entries) key_part = 0;

	G_Addr#(c, num_entries) mask = (1<<valueOf(TLog#(TMul#(c, num_entries)))) - 1;

	Integer temp = 0;

	for(Integer i=0; i<num_key_parts; i=i+1) begin	
		key_part = unpack(truncate(pack(key>>temp))) & mask;
		temp = temp + valueOf(TLog#(TMul#(c, num_entries)));
		hash_val = hash_val ^ f3(key_part);
	end

	return hash_val;
endfunction

function G_Addr#(c, num_entries) hash3(Key#(key_width) key);
	Integer num_key_parts = valueof(TDiv#(key_width, TLog#(TMul#(c, num_entries))));

	G_Addr#(c, num_entries) hash_val = 0;
	G_Addr#(c, num_entries) key_part = 0;

	G_Addr#(c, num_entries) mask = (1<<valueOf(TLog#(TMul#(c, num_entries)))) - 1;

	Integer temp = 0;

	for(Integer i=0; i<num_key_parts; i=i+1) begin	
		key_part = unpack(truncate(pack(key>>temp))) & mask;
		temp = temp + valueOf(TLog#(TMul#(c, num_entries)));
		hash_val = hash_val ^ f4(key_part);
	end

	return hash_val;
endfunction
