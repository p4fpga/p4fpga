source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

proc create_altera_10gber_phy {core_version ip_name channels mode} {
    global ipdir boardname partname
    set arg_list [list]

    if { $mode == "simulation"} {
        set file_set "SIM_VERILOG"
    } else {
        set file_set "QUARTUS_SYNTH"
    }

    lappend arg_list "--output-name=$ip_name"
    lappend arg_list "--project-directory=$ipdir/$boardname"
    lappend arg_list "--output-directory=$ipdir/$boardname/$mode/$ip_name"
    lappend arg_list "--file-set=$file_set"
    lappend arg_list "--language=VERILOG"
	lappend arg_list "--system-info=DEVICE_FAMILY=StratixV"
    lappend arg_list "--system-info=DEVICE=$partname"
    lappend arg_list "--report-file=spd:$ipdir/$boardname/$mode/$ip_name.spd"
    lappend arg_list "--report-file=qip:$ipdir/$boardname/$mode/$ip_name.qip"
	lappend arg_list "--component-param=num_channels=$channels"
	lappend arg_list "--component-param=operation_mode=duplex"
	lappend arg_list "--component-param=external_pma_ctrl_config=0"
	lappend arg_list "--component-param=control_pin_out=0"
	lappend arg_list "--component-param=recovered_clk_out=0"
	lappend arg_list "--component-param=pll_locked_out=0"
	lappend arg_list "--component-param=gui_pll_type=CMU"
	lappend arg_list "--component-param=ref_clk_freq=644.53125MHz"
	lappend arg_list "--component-param=pma_mode=40"
	lappend arg_list "--component-param=starting_channel_number=0"
	lappend arg_list "--component-param=sys_clk_in_hz=150000000"
	lappend arg_list "--component-param=rx_use_coreclk=0"
	lappend arg_list "--component-param=gui_embedded_reset=1"
	lappend arg_list "--component-param=latadj=0"
	lappend arg_list "--component-param=high_precision_latadj=1"
	lappend arg_list "--component-param=tx_termination=OCT_100_OHMS"
	lappend arg_list "--component-param=tx_vod_selection=7"
	lappend arg_list "--component-param=tx_preemp_pretap=0"
	lappend arg_list "--component-param=tx_preemp_pretap_inv=0"
	lappend arg_list "--component-param=tx_preemp_tap_1=15"
	lappend arg_list "--component-param=tx_preemp_tap_2=0"
	lappend arg_list "--component-param=tx_preemp_tap_2_inv=0"
	lappend arg_list "--component-param=rx_common_mode=0.82v"
	lappend arg_list "--component-param=rx_termination=OCT_100_OHMS"
	lappend arg_list "--component-param=rx_eq_dc_gain=0"
	lappend arg_list "--component-param=rx_eq_ctrl=0"
	lappend arg_list "--component-param=mgmt_clk_in_hz=150000000"

    catch { eval [concat [list exec ip-generate --component-name=altera_xcvr_10gbaser] $arg_list] } temp
    if { $mode == "simulation" } {
        catch { eval [concat [list exec ip-make-simscript --spd=$ipdir/$boardname/$mode/$ip_name.spd --compile-to-work] --output-directory=$ipdir/$boardname/$mode/$ip_name/] } temp
        puts $temp
    }
}

proc generate_xilinx_10g_pcs_pma_shared {core_version ip_name mode} {
    global ipdir boardname partname
    connectal_synth_ip ten_gig_eth_pcs_pma $core_version $ip_name [list CONFIG.MDIO_Management {true} CONFIG.base_kr {BASE-R} CONFIG.TransceiverControl {false} CONFIG.SupportLevel {1}]
}

proc generate_xilinx_10g_pcs_pma_non_shared {core_version ip_name mode} {
    global ipdir boardname partname
    connectal_synth_ip ten_gig_eth_pcs_pma $core_version $ip_name [list CONFIG.MDIO_Management {true} CONFIG.base_kr {BASE-R} CONFIG.TransceiverControl {false} CONFIG.SupportLevel {0}]
}

if {[info exists ALTERA]} {
    regexp {[\.0-9]+} $quartus(version) core_version

    if {[info exists NUMBER_OF_ALTERA_PORTS]} {
        set portCount $NUMBER_OF_ALTERA_PORTS
    } else {
        set portCount 4
    }

    if {[info exists SYNTHESIS]} {
        puts "Generate synthesis model.."
        create_altera_10gber_phy $core_version altera_xcvr_10gbaser_wrapper $portCount synthesis
    }

    if {[info exists SIMULATION]} {
        puts "Generate simulation model.."
        create_altera_10gber_phy $core_version altera_xcvr_10gbaser_wrapper $portCount simulation
    }
}

if {[info exists XILINX]} {
    puts "Generate synthesis model..."
    generate_xilinx_10g_pcs_pma_shared 6.0 ten_gig_eth_pcs_pma_shared synthesis
    generate_xilinx_10g_pcs_pma_non_shared 6.0 ten_gig_eth_pcs_pma_non_shared synthesis
}
