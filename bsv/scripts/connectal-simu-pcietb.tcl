source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"
source "$connectaldir/scripts/connectal-synth-pcie.tcl"

#proc fpgamake_altera_sim_ipcore {core_name core_version ip_name params} {
#    global ipdir boardname partname
#
#    exec -ignorestderr -- ip-generate \
#            --project-directory=$ipdir/$boardname                            \
#            --output-directory=$ipdir/$boardname/synthesis                   \
#            --file-set=SIM_VERILOG                                           \
#            --report-file=html:$ipdir/$boardname/$ip_name.html               \
#            --report-file=sopcinfo:$ipdir/$boardname/$ip_name.sopcinfo       \
#            --report-file=cmp:$ipdir/$boardname/$ip_name.cmp                 \
#            --report-file=qip:$ipdir/$boardname/synthesis/$ip_name.qip       \
#            --report-file=svd:$ipdir/$boardname/synthesis/$ip_name.svd       \
#            --report-file=regmap:$ipdir/$boardname/synthesis/$ip_name.regmap \
#            --report-file=xml:$ipdir/$boardname/$ip_name.xml                 \
#            --system-info=DEVICE_FAMILY=StratixV                             \
#            --system-info=DEVICE=$partname                                   \
#            --system-info=DEVICE_SPEEDGRADE=2_H2                             \
#            {*}$params                                                       \
#            --component-name=$core_name                                      \
#            --output-name=$ip_name
#}

proc create_altera_pcietb {core_name core_version ip_name} {
    set maxlinkwidth {x8}
	set params [ dict create ]
	dict set params lane_mask_hwtcl                      $maxlinkwidth
	dict set params gen123_lane_rate_mode_hwtcl          "Gen2 (5.0 Gbps)"
	dict set params port_type_hwtcl                      "Native endpoint"
	dict set params pll_refclk_freq_hwtcl                "100 MHz"
	dict set params apps_type_hwtcl                      2
	dict set params serial_sim_hwtcl                     0
	dict set params enable_pipe32_sim_hwtcl              0
	dict set params enable_tl_only_sim_hwtcl             0
	dict set params deemphasis_enable_hwtcl              "false"
	dict set params pld_clk_MHz                          1250
	dict set params millisecond_cycle_count_hwtcl        124250
	dict set params use_crc_forwarding_hwtcl             0
	dict set params ecrc_check_capable_hwtcl             0
	dict set params ecrc_gen_capable_hwtcl               0
	dict set params enable_pipe32_phyip_ser_driver_hwtcl 0

	set component_parameters {}
	foreach item [dict keys $params] {
		set val [dict get $params $item]
		lappend component_parameters --component-parameter=$item=$val
	}
    #fpgamake_altera_sim_ipcore $core_name $core_version $ip_name $component_parameters
    connectal_altera_simu_ip $core_name $core_version $ip_name $component_parameters
}

create_altera_pcietb altera_pcie_tbed 14.0 altera_pcie_testbench
create_pcie_sv_hip_ast SIMULATION
create_pcie_reconfig SIMULATION
create_pcie_xcvr_reconfig SIMULATION alt_xcvr_reconfig 14.0 alt_xcvr_reconfig_wrapper 10
