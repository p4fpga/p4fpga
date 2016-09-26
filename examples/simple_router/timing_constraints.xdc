create_clock -name sfp_refclk_p -period 6.400 [get_ports {sfp_refclk_p}]

######################################################################################################
# TIMING CONSTRAINTS
######################################################################################################

set_clock_groups -asynchronous -group [get_clocks {userclk2}] -group [get_clocks {sfp_refclk_p}]
set_clock_groups -asynchronous -group [get_clocks sys_clk] -group [get_clocks sfp_refclk_p]
set_clock_groups -asynchronous -group [get_clocks sfp_refclk_p] -group [get_clocks tile_0_lMemoryTest_phys_phy0/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_gth_10gbaser_i/gthe2_i/RXOUTCLK]
set_clock_groups -asynchronous -group [get_clocks sfp_refclk_p] -group [get_clocks tile_0_lMemoryTest_phys_phy1/inst/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_gth_10gbaser_i/gthe2_i/RXOUTCLK]
set_clock_groups -asynchronous -group [get_clocks sfp_refclk_p] -group [get_clocks tile_0_lMemoryTest_phys_phy2/inst/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_gth_10gbaser_i/gthe2_i/RXOUTCLK]
set_clock_groups -asynchronous -group [get_clocks sfp_refclk_p] -group [get_clocks tile_0_lMemoryTest_phys_phy3/inst/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_gth_10gbaser_i/gthe2_i/RXOUTCLK]

set_false_path -from [get_clocks pci_refclk] -to [get_clocks sys_clk]
set_false_path -from [get_clocks pci_refclk] -to [get_clocks sfp_refclk_p]

# questionable?
#set_output_delay 3 -clock [get_clocks pci_refclk] [get_ports]
#set_input_delay -clock [get_clocks pci_refclk] 1 [all_inputs]
#set_false_path -through [get_nets {host_pcieHostTop_ep7/pcie_ep/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/cpllPDInst/*}]
#set_false_path -through [get_nets {host_pcieHostTop_ep7/pcie_ep/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/cpllPDInst/*}]
#set_false_path -through [get_nets {host_pcieHostTop_ep7/pcie_ep/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/cpllPDInst/*}]
#set_false_path -through [get_nets {host_pcieHostTop_ep7/pcie_ep/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/cpllPDInst/*}]
#set_false_path -through [get_nets {host_pcieHostTop_ep7/pcie_ep/inst/gt_top_i/pipe_wrapper_i/pipe_lane[4].gt_wrapper_i/cpllPDInst/*}]
#set_false_path -through [get_nets {host_pcieHostTop_ep7/pcie_ep/inst/gt_top_i/pipe_wrapper_i/pipe_lane[5].gt_wrapper_i/cpllPDInst/*}]
#set_false_path -through [get_nets {host_pcieHostTop_ep7/pcie_ep/inst/gt_top_i/pipe_wrapper_i/pipe_lane[6].gt_wrapper_i/cpllPDInst/*}]
#set_false_path -through [get_nets {host_pcieHostTop_ep7/pcie_ep/inst/gt_top_i/pipe_wrapper_i/pipe_lane[7].gt_wrapper_i/cpllPDInst/*}]

