/**
 * @file udp_output_header_if.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief UDP Output Header (from Ethernet to FPGA) Interface Definition
 */

 `default_nettype none

interface UDP_OUTPUT_HEADER_IF # (
    // No parameters
);
    var logic           hdr_valid;
    var logic           hdr_ready;

    var logic [47:0]    eth_dest_mac;
    var logic [47:0]    eth_src_mac;
    var logic [15:0]    eth_type;

    var logic [3:0]     ip_version;
    var logic [3:0]     ip_ihl;
    var logic [5:0]     ip_dscp;
    var logic [1:0]     ip_ecn;
    var logic [15:0]    ip_length;
    var logic [15:0]    ip_identification;
    var logic [2:0]     ip_flags;
    var logic [12:0]    ip_fragment_offset;
    var logic [7:0]     ip_ttl;
    var logic [7:0]     ip_protocol;
    var logic [15:0]    ip_header_checksum;
    var logic [31:0]    ip_source_ip;
    var logic [31:0]    ip_dest_ip;

    var logic [15:0]    source_port;
    var logic [15:0]    dest_port;
    var logic [15:0]    length;
    var logic [15:0]    checksum;

    // FPGA side port
    modport Input (
        input hdr_valid,
        output hdr_ready,

        input eth_dest_mac,
        input eth_src_mac,
        input eth_type,

        input ip_version,
        input ip_ihl,
        input ip_dscp,
        input ip_ecn,
        input ip_length,
        input ip_identification,
        input ip_flags,
        input ip_fragment_offset,
        input ip_ttl,
        input ip_protocol,
        input ip_header_checksum,
        input ip_source_ip,
        input ip_dest_ip,

        input source_port,
        input dest_port,
        input length,
        input checksum
    );

    // Ethernet side port
    modport Output (
        output hdr_valid,
        input hdr_ready,

        output eth_dest_mac,
        output eth_src_mac,
        output eth_type,

        output ip_version,
        output ip_ihl,
        output ip_dscp,
        output ip_ecn,
        output ip_length,
        output ip_identification,
        output ip_flags,
        output ip_fragment_offset,
        output ip_ttl,
        output ip_protocol,
        output ip_header_checksum,
        output ip_source_ip,
        output ip_dest_ip,

        output source_port,
        output dest_port,
        output length,
        output checksum
    );

    // Monitor side port
    modport Monitor (
        input hdr_valid,
        input hdr_ready,

        input eth_dest_mac,
        input eth_src_mac,
        input eth_type,

        input ip_version,
        input ip_ihl,
        input ip_dscp,
        input ip_ecn,
        input ip_length,
        input ip_identification,
        input ip_flags,
        input ip_fragment_offset,
        input ip_ttl,
        input ip_protocol,
        input ip_header_checksum,
        input ip_source_ip,
        input ip_dest_ip,

        input source_port,
        input dest_port,
        input length,
        input checksum
    );
endinterface

 `default_nettype wire