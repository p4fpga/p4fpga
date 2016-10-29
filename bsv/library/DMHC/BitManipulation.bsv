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

/*** Some bit manipulation functions, add more as you like...
These functions are used to compose hash functions in the higher level modules

Author: Udit Dhawan
	IC Group, University of Pennsylvania
***/


//f1 = bit reverse...
function Bit#(TLog#(TMul#(c, num_entries))) f1(G_Addr#(c, num_entries) tag);
	Bit#(TLog#(TMul#(c, num_entries))) ret_val;
	let tag_bits = pack(tag);

	for (Integer i=0; i<valueOf(SizeOf#(G_Addr#(c, num_entries))); i=i+1)
		ret_val[i] = tag_bits[valueOf(SizeOf#(G_Addr#(c, num_entries)))-1-i];

	return ret_val;
endfunction

//f2 = pairwise bit-swap
function Bit#(TLog#(TMul#(c, num_entries))) f2(Bit#(TLog#(TMul#(c, num_entries))) tag);
	Bit#(TLog#(TMul#(c, num_entries))) ret_val = 0;
	let tag_bits = pack(tag);

	for (Integer i=0; i<valueOf(TLog#(TMul#(c, num_entries)))-1; i=i+2)
	begin
		ret_val[i] = tag_bits[i+1];
		ret_val[i+1] = tag_bits[i];
	end

	return unpack(ret_val);
endfunction

//f3 =  swap lower-half with upper half
function Bit#(TLog#(TMul#(c, num_entries))) f3(Bit#(TLog#(TMul#(c, num_entries))) tag);
	Bit#(TLog#(TMul#(c, num_entries))) ret_val=0;
	let tag_bits = pack(tag);

	for (Integer i=valueOf(TLog#(TMul#(c, num_entries)))/2; i<valueOf(TLog#(TMul#(c, num_entries))); i=i+1)
	begin
		ret_val[i-valueOf(TLog#(TMul#(c, num_entries)))/2] = tag_bits[i];
	end

	for (Integer j=0; j<valueOf(TLog#(TMul#(c, num_entries)))/2; j=j+1)
	begin
		ret_val[j] = tag_bits[valueOf(TLog#(TMul#(c, num_entries)))/2+j-1];
	end

	return unpack(ret_val);
endfunction

//f4 = swap lower half with upper half with bit-reversal
function Bit#(TLog#(TMul#(c, num_entries))) f4(Bit#(TLog#(TMul#(c, num_entries))) key);
	Bit#(TLog#(TMul#(c, num_entries))) ret_val=0;
	let key_bits = pack(key);

	for (Integer i=0; i<valueOf(TLog#(TMul#(c, num_entries)))-1; i=i+2)
	begin
		ret_val[i] = key[valueOf(TLog#(TMul#(c, num_entries)))-i-1];
		ret_val[i+1] = key[i];
	end

	return unpack(ret_val);
endfunction
