/**
 * @file udp_tx_header_if.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief UDP TX Header (from logic to PHY) Interface Definition
 */

 `default_nettype none

interface UDP_TX_HEADER_IF # (
    // No parameters
);
     var logic          hdr_valid;
     var logic          hdr_ready;

     var logic [5:0]    ip_dscp;
     var logic [1:0]    ip_ecn;
     var logic [7:0]    ip_ttl;
     var logic [31:0]   ip_source_ip;
     var logic [31:0]   ip_dest_ip;

     var logic [15:0]   source_port;
     var logic [15:0]   dest_port;
     var logic [15:0]   length;
     var logic [15:0]   checksum;

     // Logic side port
     modport Source (
        output hdr_valid,
        input hdr_ready,

        output ip_dscp,
        output ip_ecn,
        output ip_ttl,
        output ip_source_ip,
        output ip_dest_ip,

        output source_port,
        output dest_port,
        output length,
        output checksum
     );

     // PHY side port
     modport Sink (
        input hdr_valid,
        output hdr_ready,

        input ip_dscp,
        input ip_ecn,
        input ip_ttl,
        input ip_source_ip,
        input ip_dest_ip,

        input source_port,
        input dest_port,
        input length,
        input checksum
     );

     // Monitor side port
     modport Monitor (
        input hdr_valid,
        input hdr_ready,

        input ip_dscp,
        input ip_ecn,
        input ip_ttl,
        input ip_source_ip,
        input ip_dest_ip,

        input source_port,
        input dest_port,
        input length,
        input checksum
     );
endinterface

 `default_nettype wire