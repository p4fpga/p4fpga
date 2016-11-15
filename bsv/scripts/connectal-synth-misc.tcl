source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

#if {[info exists USE_ALTERA_CLKCTRL]} {
   fpgamake_altera_ipcore_qsys $connectaldir/../sonic-lite/hw/qsys/altera_clkctrl.qsys 14.0 altera_clkctrl
#}
