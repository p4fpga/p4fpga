source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

if {[info exists USE_ALTERA_PLL_PMA]} {
   fpgamake_altera_ipcore_qsys ../../hw/qsys/pll_pma.qsys 14.0 pll_pma
}
