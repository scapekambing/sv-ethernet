/**
 * @file udp_complete_wrapper.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief Wrapper for udp_complete.v from Alex Forencich
 */

`default_nettype none

module udp_complete_wrapper # (
   parameter int       ARP_CACHE_ADDR_WIDTH = 9,
   parameter int       ARP_REQUEST_RETRY_COUNT = 4,
   parameter longint   ARP_REQUEST_RETRY_INTERVAL = 125000000 * 2,
   parameter longint   ARP_REQUEST_TIMEOUT = 125000000 * 30,
   parameter bit       UDP_CHECKSUM_GEN_ENABLE = 1,
   parameter int       UDP_CHECKSUM_PAYLOAD_FIFO_DEPTH = 2048,
   parameter int       UDP_CHECKSUM_HEADER_FIFODEPTH = 8
) (
   input var logic clk,
   input var logic reset

   /* Ethernet frame input */
   ETH_HEADER_IF.Receiver input_eth_header_if,
   AXIS_IF.Receiver input_eth_payload_if,

   /* Ethernet frame output */
   ETH_HEADER_IF.Transmitter output_eth_header_if,
   AXIS_IF.Transmitter output_eth_payload_if,

   /* IP input */
   IP_INPUT_HEADER_IF.Input ip_input_header_if,
   AXIS_IF.Receiver ip_input_payload_if,

   /* IP output */
   IP_OUTPUT_HEADER_IF.Output ip_output_header_if,
   AXIS_IF.Transmitter ip_output_payload_if,

   /* UDP input */
   UDP_INPUT_HEADER_IF.Input udp_input_header_if,
   AXIS_IF.Receiver udp_input_payload_if,

   /* UDP output */
   UDP_OUTPUT_HEADER_IF.Output udp_output_header_if,
   AXIS_IF.Transmitter udp_output_payload_if,

   /* Status */
   output var logic ip_rx_busy,
   output var logic ip_tx_busy,
   output var logic udp_rx_busy,
   output var logic udp_tx_busy,

   output var logic ip_rx_error_header_early_termination,
   output var logic ip_rx_error_payload_early_termination,
   output var logic ip_rx_error_invalid_header,
   output var logic ip_rx_error_invalid_checksum,

   output var logic ip_tx_error_payload_early_termination,
   output var logic ip_tx_error_arp_failed,

   output var logic udp_rx_error_header_early_termination,
   output var logic udp_rx_error_payload_early_termination,

   output var logic udp_tx_error_payload_early_termination,

   /* Configuration */
   input var logic [47:0]  local_mac,
   input var logic [31:0]  local_ip,
   input var logic [31:0]  gateway_ip,
   input var logic [31:0]  subnet_mask,
   input var logic         clear_arp_cache
);

   udp_complete udp_complete_inst (
      .clk(clk),
      .rst(reset),

      .s_eth_hdr_valid(input_eth_header_if.hdr_valid),
      .s_eth_hdr_ready(input_eth_header_if.hdr_ready),
      .s_eth_dest_mac(input_eth_header_if.dest_mac),
      .s_eth_src_mac(input_eth_header_if.src_mac),
      .s_eth_type(input_eth_header_if.eth_type),
      .s_eth_payload_axis_tdata(input_eth_payload_if.tdata),
      .s_eth_payload_axis_tvalid(input_eth_payload_if.tvalid),
      .s_eth_payload_axis_tready(input_eth_payload_if.tready),
      .s_eth_payload_axis_tlast(input_eth_payload_if.tlast),
      .s_eth_payload_axis_tuser(input_eth_payload_if.tuser),

      .m_eth_hdr_valid(output_eth_header_if.hdr_valid),
      .m_eth_hdr_ready(output_eth_header_if.hdr_ready),
      .m_eth_dest_mac(output_eth_header_if.dest_mac),
      .m_eth_src_mac(output_eth_header_if.src_mac),
      .m_eth_type(output_eth_header_if.type),
      .m_eth_payload_axis_tdata(output_eth_payload_if.tdata),
      .m_eth_payload_axis_tvalid(output_eth_payload_if.tvalid),
      .m_eth_payload_axis_tready(output_eth_payload_if.tready),
      .m_eth_payload_axis_tlast(output_eth_payload_if.tlast),
      .m_eth_payload_axis_tuser(output_eth_payload_if.tuser),

      .s_ip_hdr_valid(ip_input_header_if.hdr_valid),
      .s_ip_hdr_ready(ip_input_header_if.hdr_ready),
      .s_ip_dscp(ip_input_header_if.dscp),
      .s_ip_ecn(ip_input_header_if.ecn),
      .s_ip_length(ip_input_header_if.length),
      .s_ip_ttl(ip_input_header_if.ttl),
      .s_ip_protocol(ip_input_header_if.protocol),
      .s_ip_source_ip(ip_input_header_if.source_ip),
      .s_ip_dest_ip(ip_input_header_if.dest_ip),
      .s_ip_payload_axis_tdata(ip_input_payload_if.tdata),
      .s_ip_payload_axis_tvalid(ip_input_payload_if.tvalid),
      .s_ip_payload_axis_tready(ip_input_payload_if.tready),
      .s_ip_payload_axis_tlast(ip_input_payload_if.tlast),
      .s_ip_payload_axis_tuser(ip_input_payload_if.tuser),

      .m_ip_hdr_valid(ip_output_header_if.hdr_valid),
      .m_ip_hdr_ready(ip_output_header_if.hdr_ready),
      .m_ip_eth_dest_mac(ip_output_header_if.eth_dest_mac),
      .m_ip_eth_src_mac(ip_output_header_if.eth_src_mac),
      .m_ip_eth_type(ip_output_header_if.eth_type),
      .m_ip_version(ip_output_header_if.version),
      .m_ip_ihl(ip_output_header_if.ihl),
      .m_ip_dscp(ip_output_header_if.dscp),
      .m_ip_ecn(ip_output_header_if.ecn),
      .m_ip_length(ip_output_header_if.length),
      .m_ip_identification(ip_output_header_if.identification),
      .m_ip_flags(ip_output_header_if.flags),
      .m_ip_fragment_offset(ip_output_header_if.fragment_offset),
      .m_ip_ttl(ip_output_header_if.ttl),
      .m_ip_protocol(ip_output_header_if.protocol),
      .m_ip_header_checksum(ip_output_header_if.header_checksum),
      .m_ip_source_ip(ip_output_header_if.source_ip),
      .m_ip_dest_ip(ip_output_header_if.dest_ip),
      .m_ip_payload_axis_tdata(ip_output_payload_if.tdata),
      .m_ip_payload_axis_tvalid(ip_output_payload_if.tvalid),
      .m_ip_payload_axis_tready(ip_output_payload_if.tready),
      .m_ip_payload_axis_tlast(ip_output_payload_if.tlast),
      .m_ip_payload_axis_tuser(ip_output_payload_if.tuser),

      .s_udp_hdr_valid(udp_input_header_if.hdr_valid),
      .s_udp_hdr_ready(udp_input_header_if.hdr_ready),
      .s_udp_ip_dscp(udp_input_header_if.ip_dscp),
      .s_udp_ip_ecn(udp_input_header_if.ip_ecn),
      .s_udp_ip_ttl(udp_input_header_if.ip_ttl),
      .s_udp_ip_source_ip(udp_input_header_if.ip_source_ip),
      .s_udp_ip_dest_ip(udp_input_header_if.ip_dest_ip),
      .s_udp_source_port(udp_input_header_if.source_port),
      .s_udp_dest_port(udp_input_header_if.dest_port),
      .s_udp_length(udp_input_header_if.length),
      .s_udp_checksum(udp_input_header_if.checksum),
      .s_udp_payload_axis_tdata(udp_input_payload_if.tdata),
      .s_udp_payload_axis_tvalid(udp_input_payload_if.tvalid),
      .s_udp_payload_axis_tready(udp_input_payload_if.tready),
      .s_udp_payload_axis_tlast(udp_input_payload_if.tlast),
      .s_udp_payload_axis_tuser(udp_input_payload_if.tuser),

      .m_udp_hdr_valid(udp_output_header_if.hdr_valid),
      .m_udp_hdr_ready(udp_output_header_if.hdr_ready),
      .m_udp_eth_dest_mac(udp_output_header_if.eth_dest_mac),
      .m_udp_eth_src_mac(udp_output_header_if.eth_src_mac),
      .m_udp_eth_type(udp_output_header_if.eth_type),
      .m_udp_ip_version(udp_output_header_if.ip_version),
      .m_udp_ip_ihl(udp_output_header_if.ip_ihl),
      .m_udp_ip_dscp(udp_output_header_if.ip_dscp),
      .m_udp_ip_ecn(udp_output_header_if.ip_ecn),
      .m_udp_ip_length(udp_output_header_if.ip_length),
      .m_udp_ip_identificatioin(udp_output_header_if.ip_identification),
      .m_udp_ip_flags(udp_output_header_if.ip_flags),
      .m_udp_ip_fragment_offset(udp_output_header_if.ip_fragment_offset),
      .m_udp_ip_ttl(udp_output_header_if.ip_ttl),
      .m_udp_ip_protocol(udp_output_header_if.ip_protocol),
      .m_udp_ip_header_checksum(udp_output_header_if.ip_header_checksum),
      .m_udp_ip_source_ip(udp_output_header_if.ip_source_ip),
      .m_udp_ip_dest_ip(udp_output_header_if.ip_dest_ip),
      .m_udp_source_port(udp_output_header_if.source_port),
      .m_udp_dest_port(udp_output_header_if.dest_port),
      .m_udp_length(udp_output_header_if.length),
      .m_udp_checksum(udp_output_header_if.checksum),
      .m_udp_payload_axis_tdata(udp_output_payload_if.tdata),
      .m_udp_payload_axis_tvalid(udp_output_payload_if.tvalid),
      .m_udp_payload_axis_tready(udp_output_payload_if.tready),
      .m_udp_payload_axis_tlast(udp_output_payload_if.tlast),
      .m_udp_payload_axis_tuser(udp_output_payload_if.tuser),

      .ip_rx_busy(ip_rx_busy),
      .ip_tx_busy(ip_tx_busy),
      .udp_rx_busy(udp_rx_busy),
      .udp_tx_busy(udp_tx_busy),
      
      .ip_rx_error_header_early_termination(ip_rx_error_header_early_termination),
      .ip_rx_error_payload_early_termination(ip_rx_error_payload_early_termination),
      .ip_rx_error_invalid_header(ip_rx_error_invalid_header),
      .ip_rx_error_invalid_checksum(ip_rx_error_invalid_checksum),
      
      .ip_tx_error_payload_early_termination(ip_tx_error_payload_early_termination),
      .ip_tx_error_arp_failed(ip_tx_error_arp_failed),
      
      .udp_rx_error_header_early_termination(udp_rx_error_header_early_termination),
      .udp_rx_error_payload_early_termination(udp_rx_error_payload_early_termination),

      .udp_tx_error_payload_early_termination(udp_tx_error_payload_early_termination),

      .local_mac(local_mac),
      .local_ip(local_ip),
      .gateway_ip(gateway_ip),
      .subnet_mask(subnet_mask),
      .clear_arp_cache(clear_arp_cache)
   );

endmodule

`default_nettype wire