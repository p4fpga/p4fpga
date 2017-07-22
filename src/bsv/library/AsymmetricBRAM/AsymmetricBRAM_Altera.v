//
// Copyright (c) 2013 Alexandre Joannou
// Copyright (c) 2014 A. Theodore Markettos
// All rights reserved.
//
// This software was developed by SRI International and the University of
// Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-10-C-0237
// ("CTSRD"), as part of the DARPA CRASH research programme.
//
// @BERI_LICENSE_HEADER_START@
//
// Licensed to BERI Open Systems C.I.C. (BERI) under one or more contributor
// license agreements.  See the NOTICE file distributed with this work for
// additional information regarding copyright ownership.  BERI licenses this
// file to you under the BERI Hardware-Software License, Version 1.0 (the
// "License"); you may not use this file except in compliance with the
// License.  You may obtain a copy of the License at:
//
//   http://www.beri-open-systems.org/legal/license-1-0.txt
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.
//
// @BERI_LICENSE_HEADER_END@
//

////////////////////////////////////////////////////////////////////////////////////
//                     mwm20k.v Altera's M20K mixed width RAM                     //
//                                                                                //
//    Author: Ameer M. Abdelhadi (ameer@ece.ubc.ca, ameer.abdelhadi@gmail.com)    //
//   SRAM-based BCAM ; The University of British Columbia (UBC), September 2014   //
////////////////////////////////////////////////////////////////////////////////////

// M20K Block Mixed-Width Configurations (Simple Dual-Port RAM Mode)
//  --------------------------------------------------------------------------------
// |     Write | 16384 | 8192 | 4096 | 4096 | 2048 | 2048 | 1024 | 1024 | 512 | 512 |
// | Read      | X 1   | X 2  | X 4  | X 5  | X 8  | X 10 | X 16 | X 20 | X32 | X40 |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// |16384 X 1  |  Yes  | Yes  | Yes  |      | Yes  |      | Yes  |      | Yes |     |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 8192 X 2  |  Yes  | Yes  | Yes  |      | Yes  |      | Yes  |      | Yes |     |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 4096 X 4  |  Yes  | Yes  | Yes  |      | Yes  |      | Yes  |      | Yes |     |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 4096 X 5  |       |      |      | Yes  |      | Yes  |      | Yes  |     | Yes |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 2048 X 8  | Yes   | Yes  | Yes  |      | Yes  |      | Yes  |      | Yes |     |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 2048 X 10 |       |      |      | Yes  |      | Yes  |      | Yes  |     | Yes |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 1024 X 16 | Yes   | Yes  | Yes  |      | Yes  |      | Yes  |      | Yes |     |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 1024 X 20 |       |      |      | Yes  |      | Yes  |      | Yes  |     | Yes |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// |  512 X 32 | Yes   | Yes  | Yes  |      | Yes  |      | Yes  |      | Yes |     |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// |  512 X 40 |       |      |      | Yes  |      | Yes  |      | Yes  |     | Yes |
//  --------------------------------------------------------------------------------

module AsymmetricBRAM_Altera(
	CLK,
	RADDR,
	RDATA,
	REN,
	WADDR,
	WDATA,
	WEN
);
	parameter	PIPELINED   = 'd 0;
	parameter	FORWARDING  = 'd 0;
	parameter	WADDR_WIDTH = 'd 0;
	parameter	WDATA_WIDTH = 'd 0;
	parameter	RADDR_WIDTH = 'd 0;
	parameter	RDATA_WIDTH = 'd 0;
	parameter	MEMSIZE     = 'd 1;
	parameter	REGISTERED  = (PIPELINED  == 0) ? "UNREGISTERED":"CLOCK0";
	input   CLK;
	input	[RADDR_WIDTH-1:0]   RADDR;
	output	[RDATA_WIDTH-1:0]   RDATA;
	input	REN;
	input	[WADDR_WIDTH-1:0]   WADDR;
	input	[WDATA_WIDTH-1:0]   WDATA;
	input   WEN;
	
  // Altera's M20K mixed width RAM instantiation
  altsyncram #( .address_aclr_b                     ("CLEAR0"           ),
                .address_reg_b                      ("CLOCK0"           ),
                .clock_enable_input_a               ("BYPASS"           ),
                .clock_enable_input_b               ("BYPASS"           ),
                .clock_enable_output_b              ("BYPASS"           ),
                .intended_device_family             ("Stratix V"        ),
                .lpm_type                           ("altsyncram"       ),
                .numwords_a                         (MEMSIZE            ),
                .numwords_b                         (MEMSIZE/(RDATA_WIDTH/WDATA_WIDTH)),
                .operation_mode                     ("DUAL_PORT"        ),
                .outdata_aclr_b                     ("NONE"             ),
                .outdata_reg_b                      ("UNREGISTERED"     ),
                .power_up_uninitialized             ("FALSE"            ),
                .ram_block_type                     ("M20K"             ),
                .read_during_write_mode_mixed_ports ("OLD_DATA"         ),
                .widthad_a                          (WADDR_WIDTH        ),
                .widthad_b                          (RADDR_WIDTH        ),
                .width_a                            (WDATA_WIDTH        ),
                .width_b                            (RDATA_WIDTH        ),
                .width_byteena_a                    (1                  ))
  altsyncm20k ( .aclr0                              (1'b0               ),
                .address_a                          (WADDR              ),
                .clock0                             (CLK                ),
                .data_a                             (WDATA              ),
                .wren_a                             (WEN                ),
                .address_b                          (RADDR              ),
                .q_b                                (RDATA              ),
                .aclr1                              (1'b0               ),
                .addressstall_a                     (1'b0               ),
                .addressstall_b                     (1'b0               ),
                .byteena_a                          (1'b1               ),
                .byteena_b                          (1'b1               ),
                .clock1                             (1'b1               ),
                .clocken0                           (1'b1               ),
                .clocken1                           (1'b1               ),
                .clocken2                           (1'b1               ),
                .clocken3                           (1'b1               ),
                .data_b                             ({RDATA_WIDTH{1'b1}}),
                .eccstatus                          (                   ),
                .q_a                                (                   ),
                .rden_a                             (1'b1               ),
                .rden_b                             (1'b1               ),
                .wren_b                             (1'b0               ));

endmodule

