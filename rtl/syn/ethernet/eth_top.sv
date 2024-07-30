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

   AXIL_IF.Master axil_if,

   input var logic [47:0] local_mac,
   input var logic [31:0] local_ip,
   input var logic [31:0] gateway_ip,
   input var logic [31:0] subnet_mask,
   input var logic clear_arp_cache,

   input var logic screamer_enable,

   input var logic [2:0] udp_payload_selection
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

   UDP_TX_HEADER_IF udp_tx_header_if();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_tx_payload_if();

   UDP_RX_HEADER_IF udp_rx_header_if();
   AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_rx_payload_if();

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

      .tx_axis_if(mii_tx_axis_if.Receiver),
      .rx_axis_if(mii_rx_axis_if.Transmitter),

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

      .mii_axis_if(mii_tx_axis_if.Transmitter),

      .eth_header_in_if(tx_eth_header_if.Receiver),
      .eth_payload_in_if(tx_eth_payload_if.Receiver),

      .busy(eth_tx_busy)
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

      .busy(eth_rx_busy),
      .error_header_early_termination()
   );

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

      .udp_tx_header_if(udp_tx_header_if.Sink),
      .udp_tx_payload_if(udp_tx_payload_if.Receiver),

      .udp_rx_header_if(udp_rx_header_if.Source),
      .udp_rx_payload_if(udp_rx_payload_if.Transmitter),

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

   udp_mux_wrapper # (
      .S_COUNT(3)
   ) udp_mux_inst (
      .clk(clk),
      .reset(reset),

      .udp_tx_header_if_sink(udp_tx_header_if_mux),
      .udp_tx_payload_if_sink(udp_tx_payload_if_mux),
      .udp_tx_header_if_source(udp_tx_header_if),
      .udp_tx_payload_if_source(udp_tx_payload_if),

      .enable(1'b1),
      .select(udp_payload_selection)
   );

   udp_demux_wrapper # (
      .M_COUNT(3)
   ) udp_demux_inst (
      .clk(clk),
      .reset(reset),
      
      .udp_rx_header_if_source(udp_rx_header_if_mux),
      .udp_rx_payload_if_source(udp_rx_payload_if_mux),
      .udp_rx_header_if_sink(udp_rx_header_if),
      .udp_rx_payload_if_sink(udp_rx_payload_if),
      
      .enable(1'b1),
      .drop(1'b0),
      .select(udp_payload_selection)
   );

   udp_spam # (
      // Using defaults
   ) udp_spam_inst (
      .clk(clk),
      .reset(reset),

      .udp_tx_header_if(udp_tx_header_if_mux[2]),
      .udp_tx_payload_if(udp_tx_payload_if_mux[2]),
      .udp_rx_header_if(udp_rx_header_if_mux[2]),
      .udp_rx_payload_if(udp_rx_payload_if_mux[2]),

      .enable(screamer_enable)
   );

   udp_loopback # (
      // Using defaults
   ) udp_loopback_inst (
      .clk(clk),
      .reset(reset),
      .local_ip(local_ip),

      .udp_tx_header_if(udp_tx_header_if_mux[1]),
      .udp_tx_payload_if(udp_tx_payload_if_mux[1]),
      .udp_rx_header_if(udp_rx_header_if_mux[1]),
      .udp_rx_payload_if(udp_rx_payload_if_mux[1])
   );
   
   udp_axil_bridge # (
      // Using default values
   ) udp_axil_bridge_inst (
      .clk(clk),
      .reset(reset),

      .udp_tx_header_if(udp_tx_header_if_mux[0]),
      .udp_tx_payload_if(udp_tx_payload_if_mux[0]),

      .udp_rx_header_if(udp_rx_header_if_mux[0]),
      .udp_rx_payload_if(udp_rx_payload_if_mux[0]),

      .axil_if(axil_if)
   );
   
   
   /*
   var logic         eth_rx_valid;
   var logic         eth_rx_ready;
   var logic [47:0]  eth_rx_src_mac;
   var logic [47:0]  eth_rx_dest_mac;
   var logic [15:0]  eth_rx_type;

   var logic         eth_rx_tvalid;
   var logic         eth_rx_tready;
   var logic [7:0]   eth_rx_tdata;

   var logic         ip_rx_hdr_valid;
   var logic         ip_rx_hdr_ready;
   var logic [47:0]  ip_rx_eth_dest_mac;
   var logic [47:0]  ip_rx_eth_src_mac;
   var logic [15:0]  ip_rx_eth_type;
   var logic [3:0]   ip_rx_version;
   var logic [3:0]   ip_rx_ihl;
   var logic [5:0]   ip_rx_dscp;
   var logic [1:0]   ip_rx_ecn;
   var logic [15:0]  ip_rx_length;
   var logic [15:0]  ip_rx_identification;
   var logic [2:0]   ip_rx_flags;
   var logic [12:0]  ip_rx_fragment_offset;
   var logic [7:0]   ip_rx_ttl;
   var logic [7:0]   ip_rx_protocol;
   var logic [15:0]  ip_rx_header_checksum;
   var logic [31:0]  ip_rx_source_ip;
   var logic [31:0]  ip_rx_dest_ip;

   var logic         ip_rx_tvalid;
   var logic         ip_rx_tready;
   var logic [7:0]   ip_rx_tdata;

   var logic         udp_rx_tvalid;
   var logic         udp_rx_tready;
   var logic [7:0]   udp_rx_tdata;

   var logic         ip_tx_hdr_valid;
   var logic         ip_tx_hdr_ready;

   var logic         udp_tx_hdr_valid;
   var logic         udp_tx_hdr_ready;
   
   always_ff @ (posedge clk) begin
      eth_rx_valid            <= rx_eth_header_if.valid;
      eth_rx_ready            <= rx_eth_header_if.ready;
      eth_rx_src_mac          <= rx_eth_header_if.src_mac;
      eth_rx_dest_mac         <= rx_eth_header_if.dest_mac;
      eth_rx_type             <= rx_eth_header_if.eth_type;

      eth_rx_tvalid           <= rx_eth_payload_if.tvalid;
      eth_rx_tready           <= rx_eth_payload_if.tready;
      eth_rx_tdata            <= rx_eth_payload_if.tdata;

      ip_rx_hdr_valid         <= ip_output_header_if.hdr_valid;
      ip_rx_hdr_ready         <= ip_output_header_if.hdr_ready;
      ip_rx_eth_dest_mac      <= ip_output_header_if.eth_dest_mac;
      ip_rx_eth_src_mac       <= ip_output_header_if.eth_src_mac;
      ip_rx_eth_type          <= ip_output_header_if.eth_type;
      ip_rx_version           <= ip_output_header_if.version;
      ip_rx_ihl               <= ip_output_header_if.ihl;
      ip_rx_dscp              <= ip_output_header_if.dscp;
      ip_rx_ecn               <= ip_output_header_if.ecn;
      ip_rx_length            <= ip_output_header_if.length;
      ip_rx_identification    <= ip_output_header_if.identification;
      ip_rx_flags             <= ip_output_header_if.flags;
      ip_rx_fragment_offset   <= ip_output_header_if.fragment_offset;
      ip_rx_ttl               <= ip_output_header_if.ttl;
      ip_rx_protocol          <= ip_output_header_if.protocol;
      ip_rx_header_checksum   <= ip_output_header_if.header_checksum;
      ip_rx_source_ip         <= ip_output_header_if.source_ip;
      ip_rx_dest_ip           <= ip_output_header_if.dest_ip;

      ip_rx_tvalid            <= ip_output_payload_if.tvalid;
      ip_rx_tready            <= ip_output_payload_if.tready;
      ip_rx_tdata             <= ip_output_payload_if.tdata;

      udp_rx_tvalid           <= udp_rx_payload_if.tvalid;
      udp_rx_tready           <= udp_rx_payload_if.tready;
      udp_rx_tdata            <= udp_rx_payload_if.tdata;

      ip_tx_hdr_valid         <= ip_input_header_if.hdr_valid;
      ip_tx_hdr_ready         <= ip_input_header_if.hdr_ready;

      udp_tx_hdr_valid        <= udp_tx_header_if.hdr_valid;
      udp_tx_hdr_ready        <= udp_tx_header_if.hdr_ready;
   end

   ila_eth ila_eth_inst (
	   .clk(clk), // input wire clk

	   .probe0(eth_rx_valid), // input wire [0:0]  probe0  
	   .probe1(eth_rx_ready), // input wire [0:0]  probe1 
	   .probe2(eth_rx_src_mac), // input wire [47:0]  probe2 
	   .probe3(eth_rx_dest_mac), // input wire [47:0]  probe3 
	   .probe4(eth_rx_type), // input wire [15:0]  probe4 
	   .probe5(eth_rx_tvalid), // input wire [0:0]  probe5 
	   .probe6(eth_rx_tready), // input wire [0:0]  probe6 
	   .probe7(eth_rx_tdata), // input wire [7:0]  probe7 
	   .probe8(ip_rx_hdr_valid), // input wire [0:0]  probe8 
	   .probe9(ip_rx_hdr_ready), // input wire [0:0]  probe9 
	   .probe10(ip_rx_eth_dest_mac), // input wire [47:0]  probe10 
	   .probe11(ip_rx_eth_src_mac), // input wire [47:0]  probe11 
	   .probe12(ip_rx_eth_type), // input wire [15:0]  probe12 
	   .probe13(ip_rx_version), // input wire [3:0]  probe13 
	   .probe14(ip_rx_ihl), // input wire [3:0]  probe14 
	   .probe15(ip_rx_dscp), // input wire [5:0]  probe15 
	   .probe16(ip_rx_ecn), // input wire [1:0]  probe16 
	   .probe17(ip_rx_length), // input wire [15:0]  probe17 
	   .probe18(ip_rx_identification), // input wire [15:0]  probe18 
	   .probe19(ip_rx_flags), // input wire [2:0]  probe19 
	   .probe20(ip_rx_fragment_offset), // input wire [12:0]  probe20 
	   .probe21(ip_rx_ttl), // input wire [7:0]  probe21 
	   .probe22(ip_rx_protocol), // input wire [7:0]  probe22 
	   .probe23(ip_rx_header_checksum), // input wire [15:0]  probe23 
	   .probe24(ip_rx_source_ip), // input wire [31:0]  probe24 
	   .probe25(ip_rx_dest_ip), // input wire [31:0]  probe25 
	   .probe26(ip_rx_tvalid), // input wire [0:0]  probe26 
	   .probe27(ip_rx_tready), // input wire [0:0]  probe27 
	   .probe28(ip_rx_tdata), // input wire [7:0]  probe28 
	   .probe29(udp_rx_tvalid), // input wire [0:0]  probe29 
	   .probe30(udp_rx_tready), // input wire [0:0]  probe30 
	   .probe31(udp_rx_tdata), // input wire [7:0]  probe31 
	   .probe32(ip_tx_hdr_valid), // input wire [0:0]  probe32 
	   .probe33(ip_tx_hdr_ready), // input wire [0:0]  probe33 
	   .probe34(udp_tx_hdr_valid), // input wire [0:0]  probe34 
	   .probe35(udp_tx_hdr_ready), // input wire [0:0]  probe35 
	   .probe36(bad_fcs), // input wire [0:0]  probe36 
	   .probe37(eth_tx_busy), // input wire [0:0]  probe37 
	   .probe38(eth_rx_busy), // input wire [0:0]  probe38 
	   .probe39(fifo_overflow), // input wire [0:0]  probe39 
	   .probe40(1'b0), // input wire [0:0]  probe40 
	   .probe41(1'b0), // input wire [0:0]  probe41 
	   .probe42(1'b0), // input wire [0:0]  probe42 
	   .probe43(1'b0), // input wire [0:0]  probe43 
	   .probe44(1'b0), // input wire [0:0]  probe44 
	   .probe45(1'b0), // input wire [0:0]  probe45 
	   .probe46(1'b0), // input wire [0:0]  probe46 
	   .probe47(1'b0) // input wire [0:0]  probe47
    );
    */

endmodule

`default_nettype wire