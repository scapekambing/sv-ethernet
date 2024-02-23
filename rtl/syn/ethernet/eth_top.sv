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
   ) mii_tx_axis_if();

   AXIS_IF # (
      .TDATA_WIDTH(AXIS_TDATA_WIDTH),
      .TUSER_WIDTH(1),
      .TKEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) rx_eth_payload_if();

   ETH_HEADER_IF rx_eth_header_if();

   AXIS_IF # (
      .TDATA_WIDTH(AXIS_TDATA_WIDTH),
      .TUSER_WIDTH(1),
      .TKEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) mii_rx_axis_if();

   AXIS_IF # (
      .TDATA_WIDTH(AXIS_TDATA_WIDTH),
      .TUSER_WIDTH(1),
      .TKEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) tx_eth_payload_if();

   ETH_HEADER_IF tx_eth_header_if();

   UDP_INPUT_HEADER_IF udp_input_header_if();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_input_payload_if();

   UDP_OUTPUT_HEADER_IF udp_output_header_if();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_output_payload_if();

   /* Modules */

   eth_mac_mii_fifo_wrapper # (
      .TARGET(TARGET)
   ) eth_mac_mii_fifo_wrapper_inst (
      .clk(clk),
      .reset(reset),
      .phy_reset(reset),

      .tx_axis_if(mii_tx_axis_if.Receiver),
      .rx_axis_if(mii_rx_axis_if.Transmitter),

      .mii_if(mii_if),

      .tx_error_underflow(),
      .tx_fifo_overflow(),
      .tx_fifo_bad_frame(),
      .tx_fifo_good_frame(),
      
      .rx_error_bad_frame(),
      .rx_error_bad_fcs(),
      .rx_fifo_overflow(),
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

      .mii_axis_if(mii_tx_axis_if.Transmitter),

      .eth_header_in_if(tx_eth_header_if.Receiver),
      .eth_payload_in_if(tx_eth_payload_if.Receiver),

      .busy()
   );

   eth_axis_rx_wrapper # (
      .DATA_WIDTH(AXIS_TDATA_WIDTH),
      .KEEP_ENABLE(AXIS_TKEEP_ENABLE)
   ) eth_axis_rx_wrapper_inst (
      .clk(clk),
      .reset(reset),

      .mii_axis_if(mii_rx_axis_if.Receiver),
   
      .eth_header_out_if(rx_eth_header_if.Transmitter),
      .eth_payload_out_if(rx_eth_payload_if.Transmitter),

      .busy(),
      .error_header_early_termination()
   );

   // Unused interfaces
   IP_INPUT_HEADER_IF ip_input_header_if();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) ip_input_payload_if();
   IP_OUTPUT_HEADER_IF ip_output_header_if();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) ip_output_payload_if();

   // Driving necessary signals to allow operation with unused interfaces
   assign ip_input_header_if.hdr_valid = '0;
   assign ip_input_payload_if.tvalid = '0;
   assign ip_output_header_if.hdr_ready = '1;
   assign ip_output_payload_if.tready = '1;

   // UDP loopback
   var logic match = udp_input_header_if.dest_port == 1234;
   var logic match_reg = '0;
   var logic match_reg_n = '0;

   always_ff @ (posedge clk) begin
      if (reset) begin
         match_reg <= '0;
         match_reg_n <= '0;
      end else begin
         if (udp_input_payload_if.tvalid) begin
            if ((!match_reg) || (udp_input_payload_if.tvalid && udp_input_payload_if.tready && udp_input_payload_if.tlast)) begin
               match_reg <= match;
               match_reg_n <= !match;
            end
         end else begin
            match_reg <= '0;
            match_reg_n <= '0;
         end
      end
   end

   assign udp_input_header_if.hdr_valid = udp_input_header_if.hdr_valid && match;
   assign udp_output_header_if.hdr_ready = (tx_eth_header_if.ready && match) || !match;
   assign udp_input_header_if.ip_dscp = 0;
   assign udp_input_header_if.ip_ecn = 0;
   assign udp_input_header_if.ip_ttl = 64;
   assign udp_input_header_if.ip_source_ip = local_ip;
   assign udp_input_header_if.ip_dest_ip = udp_input_header_if.ip_source_ip;
   assign udp_input_header_if.source_port = udp_input_header_if.dest_port;
   assign udp_input_header_if.dest_port = udp_input_header_if.source_port;
   assign udp_input_header_if.length = udp_input_header_if.length;
   assign udp_input_header_if.checksum = 0;

   assign udp_output_payload_if.tdata = udp_input_payload_if.tdata;
   assign udp_output_payload_if.tvalid = udp_input_payload_if.tvalid && match_reg;
   assign udp_input_payload_if.tready = (udp_output_payload_if.tready && match_reg) || match_reg_n;
   assign udp_output_payload_if.tlast = udp_input_payload_if.tlast;
   assign udp_output_payload_if.tuser = udp_input_payload_if.tuser;

   // Skipping IP
   udp_complete_wrapper # (
      // Using default values
   ) udp_complete_wapper_inst (
      .clk(clk),
      .reset(reset),

      .input_eth_header_if(rx_eth_header_if.Receiver),
      .input_eth_payload_if(rx_eth_payload_if.Receiver),

      .output_eth_header_if(tx_eth_header_if.Transmitter),
      .output_eth_payload_if(tx_eth_payload_if.Transmitter),

      .ip_input_header_if(ip_input_header_if.Input),
      .ip_input_payload_if(ip_input_payload_if.Receiver),

      .ip_output_header_if(ip_output_header_if.Output),
      .ip_output_payload_if(ip_output_payload_if.Transmitter),

      .udp_input_header_if(udp_input_header_if.Input),
      .udp_input_payload_if(udp_input_payload_if.Receiver),

      .udp_output_header_if(udp_output_header_if.Output),
      .udp_output_payload_if(udp_output_payload_if.Transmitter),

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

endmodule

`default_nettype wire