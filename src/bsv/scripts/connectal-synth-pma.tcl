source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

if {[info exists NUMBER_OF_ALTERA_PORTS]} {
   puts "Generate 1-port PMA"
   fpgamake_altera_ipcore_qsys $connectaldir/../sonic-lite/hw/qsys/sv_10g_pma_1.qsys 14.0 sv_10g_pma
} else {
   puts "Generate 4-port PMA"
   fpgamake_altera_ipcore_qsys $connectaldir/../sonic-lite/hw/qsys/sv_10g_pma.qsys 14.0 sv_10g_pma
}
