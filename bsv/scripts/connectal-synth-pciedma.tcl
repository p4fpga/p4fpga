source "board.tcl"
source "$connectaldir/scripts/connectal-synth-ip.tcl"

if {[info exists USE_ALTERA_PCIE_DMA]} {
   fpgamake_altera_ipcore_qsys ../../hw/qsys/pcie_dma.qsys 14.0 pcie_dma
}
