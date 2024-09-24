/**
 * @file eth_top.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief Top module of Ethernet stack
 */

`default_nettype none

module eth_top # (
   parameter string TARGET = "GENERIC"
) (
   input var logic clk,
   input var logic reset,

   MII_IF.MAC mii_if,

   AXIS_IF.Master axis_dac_if,

   input var logic [47:0] local_mac,
   input var logic [31:0] local_ip,
   input var logic [31:0] gateway_ip,
   input var logic [31:0] subnet_mask,
   input var logic clear_arp_cache,

   input var logic screamer_enable
);
   localparam int AXIS_TDATA_WIDTH = 8;
   localparam bit AXIS_TKEEP_ENABLE = AXIS_TDATA_WIDTH > 8;

   /* Interfaces */

   AXIS_IF # (
      .TDATA_WIDTH(AXIS_TDATA_WIDTH),
      .TUSER_WIDTH(1),
      .TKEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) mii_tx_axis_if();

   AXIS_IF # (
      .TDATA_WIDTH(AXIS_TDATA_WIDTH),
      .TUSER_WIDTH(1),
      .TKEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) eth_rx_payload_if();

   ETH_HEADER_IF eth_rx_header_if();

   AXIS_IF # (
      .TDATA_WIDTH(AXIS_TDATA_WIDTH),
      .TUSER_WIDTH(1),
      .TKEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) mii_rx_axis_if();

   AXIS_IF # (
      .TDATA_WIDTH(AXIS_TDATA_WIDTH),
      .TUSER_WIDTH(1),
      .TKEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) eth_tx_payload_if();

   ETH_HEADER_IF eth_tx_header_if();

   UDP_TX_HEADER_IF udp_tx_header_if();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_tx_payload_if();

   UDP_RX_HEADER_IF udp_rx_header_if();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_rx_payload_if();

   // Unused interfaces
   IP_TX_HEADER_IF ip_tx_header_if();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) ip_tx_payload_if();
   IP_RX_HEADER_IF ip_rx_header_if();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) ip_rx_payload_if();

   // Driving necessary signals to allow operation with unused interfaces
   assign ip_tx_header_if.hdr_valid = '0;
   assign ip_tx_payload_if.tvalid = '0;
   assign ip_rx_header_if.hdr_ready = '1;
   assign ip_rx_payload_if.tready = '1;

   /* Modules */

   var logic bad_fcs;
   var logic eth_tx_busy;
   var logic eth_rx_busy;
   var logic fifo_overflow;

   eth_mac_mii_fifo_wrapper # (
      .TARGET(TARGET)
   ) eth_mac_mii_fifo_wrapper_inst (
      .clk(clk),
      .reset(reset),
      .phy_reset(reset),

      .tx_axis_if(mii_tx_axis_if.Slave),
      .rx_axis_if(mii_rx_axis_if.Master),

      .mii_if(mii_if),

      .tx_error_underflow(),
      .tx_fifo_overflow(),
      .tx_fifo_bad_frame(),
      .tx_fifo_good_frame(),
      
      .rx_error_bad_frame(),
      .rx_error_bad_fcs(bad_fcs),
      .rx_fifo_overflow(fifo_overflow),
      .rx_fifo_bad_frame(),
      .rx_fifo_good_frame(),

      .cfg_ifg(8'd12),
      .cfg_tx_enable(1'b1),
      .cfg_rx_enable(1'b1)
   );

   eth_axis_tx_wrapper # (
      .DATA_WIDTH(AXIS_TDATA_WIDTH),
      .KEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) eth_axis_tx_wrapper_inst (
      .clk(clk),
      .reset(reset),

      .mii_axis_if(mii_tx_axis_if.Master),

      .eth_tx_header_if(eth_tx_header_if.Slave),
      .eth_tx_payload_if(eth_tx_payload_if.Slave),

      .busy(eth_tx_busy)
   );

   eth_axis_rx_wrapper # (
      .DATA_WIDTH(AXIS_TDATA_WIDTH),
      .KEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) eth_axis_rx_wrapper_inst (
      .clk(clk),
      .reset(reset),

      .mii_axis_if(mii_rx_axis_if.Slave),
   
      .eth_rx_header_if(eth_rx_header_if.Master),
      .eth_rx_payload_if(eth_rx_payload_if.Master),

      .busy(eth_rx_busy),
      .error_header_early_termination()
   );

   udp_complete_wrapper # (
      // Using default values
   ) udp_complete_wapper_inst (
      .clk(clk),
      .reset(reset),

      .eth_rx_header_if(eth_rx_header_if.Slave),
      .eth_rx_payload_if(eth_rx_payload_if.Slave),

      .eth_tx_header_if(eth_tx_header_if.Master),
      .eth_tx_payload_if(eth_tx_payload_if.Master),

      .ip_tx_header_if(ip_tx_header_if.Slave),
      .ip_tx_payload_if(ip_tx_payload_if.Slave),

      .ip_rx_header_if(ip_rx_header_if.Master),
      .ip_rx_payload_if(ip_rx_payload_if.Master),

      .udp_tx_header_if(udp_tx_header_if.Sink),
      .udp_tx_payload_if(udp_tx_payload_if.Slave),

      .udp_rx_header_if(udp_rx_header_if.Source),
      .udp_rx_payload_if(udp_rx_payload_if.Master),

      .ip_rx_busy(),
      .ip_tx_busy(),
      .udp_rx_busy(),
      .udp_tx_busy(),
      .ip_rx_error_header_early_termination(),
      .ip_rx_error_payload_early_termination(),
      .ip_rx_error_invalid_header(),
      .ip_rx_error_invalid_checksum(),
      .ip_tx_error_payload_early_termination(),
      .ip_tx_error_arp_failed(),
      .udp_rx_error_header_early_termination(),
      .udp_rx_error_payload_early_termination(),
      .udp_tx_error_payload_early_termination(),

      .local_mac(local_mac),
      .local_ip(local_ip),
      .gateway_ip(gateway_ip),
      .subnet_mask(subnet_mask),
      .clear_arp_cache(clear_arp_cache)
   );

   UDP_TX_HEADER_IF udp_tx_header_if_mux [3]();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_tx_payload_if_mux [3]();
   UDP_RX_HEADER_IF udp_rx_header_if_mux [3]();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_rx_payload_if_mux [3]();

   localparam bit [15:0] PORTS [3] = {1230, 1231, 1232};

   udp_switch # (
      .PORT_COUNT(3),
      .PORTS(PORTS)
   ) udp_switch_inst (
      .clk(clk),
      .reset(reset),

      .udp_tx_header_if_sink(udp_tx_header_if_mux),
      .udp_tx_payload_if_sink(udp_tx_payload_if_mux),
      .udp_rx_header_if_source(udp_rx_header_if_mux),
      .udp_rx_payload_if_source(udp_rx_payload_if_mux),

      .udp_tx_header_if_source(udp_tx_header_if),
      .udp_tx_payload_if_source(udp_tx_payload_if),
      .udp_rx_header_if_sink(udp_rx_header_if),
      .udp_rx_payload_if_sink(udp_rx_payload_if)
   );

   udp_axis_master # (
      .UDP_PORT(PORTS[0])
   ) udp_axis_master_inst (
      .clk(clk),
      .reset(reset),
      
      .udp_tx_header_if(udp_tx_header_if_mux[0]),
      .udp_tx_payload_if(udp_tx_payload_if_mux[0]),

      .udp_rx_header_if(udp_rx_header_if_mux[0]),
      .udp_rx_payload_if(udp_rx_payload_if_mux[0]),

      .out_axis_if(axis_dac_if)
   );

   udp_loopback # (
      .UDP_PORT(PORTS[1])
   ) udp_loopback_inst (
      .clk(clk),
      .reset(reset),
      .local_ip(local_ip),

      .udp_tx_header_if(udp_tx_header_if_mux[1]),
      .udp_tx_payload_if(udp_tx_payload_if_mux[1]),
      .udp_rx_header_if(udp_rx_header_if_mux[1]),
      .udp_rx_payload_if(udp_rx_payload_if_mux[1])
   );

   udp_spam # (
      .UDP_PORT(PORTS[2])
   ) udp_spam_inst (
      .clk(clk),
      .reset(reset),

      .udp_tx_header_if(udp_tx_header_if_mux[2]),
      .udp_tx_payload_if(udp_tx_payload_if_mux[2]),
      .udp_rx_header_if(udp_rx_header_if_mux[2]),
      .udp_rx_payload_if(udp_rx_payload_if_mux[2]),

      .enable(screamer_enable)
   );

endmodule

`default_nettype wire