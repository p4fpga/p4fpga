source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

proc generate_mac_core {core_version ip_name mode} {
    global ipdir boardname partname
    set arg_list [list]

    if { $mode == "simulation"} {
        set file_set "SIM_VERILOG"
    } else {
        set file_set "SYNTH_VERILOG"
    }

    lappend arg_list "--project-directory=$ipdir/$boardname"
    lappend arg_list "--output-directory=$ipdir/$boardname/$mode/$ip_name"
    lappend arg_list "--file-set=$file_set"
    lappend arg_list "--language=VERILOG"
    lappend arg_list "--system-info=DEVICE_FAMILY=STRATIXV"
    lappend arg_list "--system-info=DEVICE=$partname"
    lappend arg_list "--report-file=spd:$ipdir/$boardname/$mode/$ip_name.spd"
    lappend arg_list "--report-file=qip:$ipdir/$boardname/$mode/$ip_name.qip"
    lappend arg_list "--output-name=$ip_name"
    lappend arg_list "--component-param=STARTING_CHANNEL_NUMBER=0"
    lappend arg_list "--component-param=CHOOSE_MDIO_2_WIRE_SERIAL_INT=1"
    lappend arg_list "--component-param=PHY_IP=2"
    lappend arg_list "--component-param=PREAMBLE_PASSTHROUGH=true"
    lappend arg_list "--component-param=CHOOSE_FIFO=0"
    lappend arg_list "--component-param=INTERFACE_TYPE=Soft XAUI"
    lappend arg_list "--component-param=EN_SYNCE_SUPPORT=0"
    lappend arg_list "--component-param=USE_CONTROL_AND_STATUS_PORTS=0"
    lappend arg_list "--component-param=EXTERNAL_PMA_CTRL_RECONF=0"
    lappend arg_list "--component-param=RECOVERED_CLK_OUT=0"
    lappend arg_list "--component-param=NUMBER_OF_INTERFACES=1"
    lappend arg_list "--component-param=RECONFIG_INTERFACES=1"
    lappend arg_list "--component-param=USE_RX_RATE_MATCH=0"
    lappend arg_list "--component-param=TX_TERMINATION=OCT_100_OHMS"
    lappend arg_list "--component-param=TX_VOD_SELECTION=4"
    lappend arg_list "--component-param=TX_PREEMP_PRETAP=0"
    lappend arg_list "--component-param=TX_PREEMP_PRETAP_INV=false"
    lappend arg_list "--component-param=TX_PREEMP_TAP_1=0"
    lappend arg_list "--component-param=TX_PREEMP_TAP_2=0"
    lappend arg_list "--component-param=TX_PREEMP_TAP_2_INV=false"
    lappend arg_list "--component-param=RX_COMMON_MODE=0.82v"
    lappend arg_list "--component-param=RX_TERMINATION=OCT_100_OHMS"
    lappend arg_list "--component-param=RX_EQ_DC_GAIN=0"
    lappend arg_list "--component-param=RX_EQ_CTRL=0"
    lappend arg_list "--component-param=PLL_EXTERNAL_ENABLE=0"
    catch { eval [concat [list exec ip-generate --component-name=altera_eth_10g_design_example] $arg_list] } temp
    puts $temp
    if { $mode == "simulation" } {
        catch { eval [concat [list exec ip-make-simscript --spd=$ipdir/$boardname/$mode/$ip_name.spd --compile-to-work] --output-directory=$ipdir/$boardname/$mode/$ip_name/] } temp
        puts $temp
    }
}

if {[info exists ALTERA]} {
    regexp {[\.0-9]+} $quartus(version) core_version
    puts $core_version

    if {[info exists SYNTHESIS]} {
        puts "Generate synthesis model.."
        generate_mac_core $core_version mac_10gbe synthesis
    }

    if {[info exists SIMULATION]} {
        puts "Generate simulation model.."
        generate_mac_core $core_version mac_10gbe simulation
    }
}

if {[info exists XILINX]} {
    puts "Generate synthesis model.."
    if {[version -short] >= "2016.1"} {
        set ten_gig_mac_version 15.1
    } else {
        set ten_gig_mac_version 15.0
    }
    connectal_synth_ip ten_gig_eth_mac $ten_gig_mac_version ten_gig_eth_mac_0 [list \
        CONFIG.Management_Interface {true} \
        CONFIG.Statistics_Gathering {true} \
        CONFIG.Physical_Interface {Internal} \
        CONFIG.Low_Latency_32_bit_MAC {64bit} \
        CONFIG.SupportLevel {0} \
        ]
}

