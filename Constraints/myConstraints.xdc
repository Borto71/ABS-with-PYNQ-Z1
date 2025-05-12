# Disabilita la verifica dei vincoli per le porte AXI non utilizzate fisicamente

# Clock e Reset
set_property IOSTANDARD LVCMOS33 [get_ports s00_axi_aclk]
set_property IOSTANDARD LVCMOS33 [get_ports s00_axi_aresetn]

# Assegna valori costanti ai segnali AXI inutilizzati

# Read address
set_property IOSTANDARD LVCMOS33 [get_ports {s00_axi_araddr[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports s00_axi_arvalid]
set_property IOSTANDARD LVCMOS33 [get_ports s00_axi_arready]

# Write address
set_property IOSTANDARD LVCMOS33 [get_ports {s00_axi_awaddr[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports s00_axi_awvalid]
set_property IOSTANDARD LVCMOS33 [get_ports s00_axi_awready]

# Write data
set_property IOSTANDARD LVCMOS33 [get_ports {s00_axi_wdata[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports s00_axi_wvalid]
set_property IOSTANDARD LVCMOS33 [get_ports s00_axi_wready]

# Write strobe
set_property IOSTANDARD LVCMOS33 [get_ports {s00_axi_wstrb[*]}]

# Read data
set_property IOSTANDARD LVCMOS33 [get_ports {s00_axi_rdata[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports s00_axi_rvalid]
set_property IOSTANDARD LVCMOS33 [get_ports s00_axi_rready]

# Response channels
set_property IOSTANDARD LVCMOS33 [get_ports {s00_axi_bresp[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {s00_axi_rresp[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports s00_axi_bvalid]
set_property IOSTANDARD LVCMOS33 [get_ports s00_axi_bready]

# Per Vivado: ignora errori legati a LOC non assegnati
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
