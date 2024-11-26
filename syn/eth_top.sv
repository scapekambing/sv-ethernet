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
   parameter string TARGET = "GENERIC",
   parameter int PORT_COUNT = 1,
   parameter bit [15:0] PORTS [PORT_COUNT] = {1234}
) (
   input var logic clk,
   input var logic reset,

   MII_IF.MAC mii_if,

   AXIS_IF.Slave mii_tx_axis_if,
   AXIS_IF.Master mii_rx_axis_if,

   UDP_TX_HEADER_IF udp_tx_header_if_mux [PORT_COUNT]();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_tx_payload_if_mux [PORT_COUNT]();
   UDP_RX_HEADER_IF udp_rx_header_if_mux [PORT_COUNT]();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_rx_payload_if_mux [PORT_COUNT]();

   input var logic [47:0] local_mac,
   input var logic [31:0] local_ip,
   input var logic [31:0] gateway_ip,
   input var logic [31:0] subnet_mask,
   input var logic clear_arp_cache
);
   localparam int AXIS_TDATA_WIDTH = 8;
   localparam bit AXIS_TKEEP_ENABLE = AXIS_TDATA_WIDTH > 8;

   /* Interfaces */
   AXIS_IF # (
      .TDATA_WIDTH(AXIS_TDATA_WIDTH),
      .TUSER_WIDTH(1),
      .TKEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) eth_tx_payload_if();

   AXIS_IF # (
      .TDATA_WIDTH(AXIS_TDATA_WIDTH),
      .TUSER_WIDTH(1),
      .TKEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) eth_rx_payload_if();
   
   ETH_HEADER_IF eth_tx_header_if();

   ETH_HEADER_IF eth_rx_header_if();

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

   udp_switch # (
      .PORT_COUNT(PORT_COUNT),
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

endmodule

`default_nettype wire