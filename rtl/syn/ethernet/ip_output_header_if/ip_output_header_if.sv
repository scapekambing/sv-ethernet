/**
 * @file ip_output_header_if.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief IP Output Header (from Ethernet to FPGA) Interface Definition
 */

 `default_nettype none

interface IP_OUTPUT_HEADER_IF # (
    // No parameters
);
    var logic           hdr_valid;
    var logic           hdr_ready;
    
    var logic [47:0]    eth_dest_mac;
    var logic [47:0]    eth_src_mac;
    var logic [15:0]    eth_type;

    var logic [3:0]     version;
    var logic [3:0]     ihl;
    var logic [5:0]     dscp;
    var logic [1:0]     ecn;
    var logic [15:0]    length;
    var logic [15:0]    identification;
    var logic [2:0]     flags;
    var logic [12:0]    fragment_offset;
    var logic [7:0]     ttl;
    var logic [7:0]     protocol;
    var logic [15:0]    header_checksum;
    var logic [31:0]    source_ip;
    var logic [31:0]    dest_ip;

    // FPGA side port
    modport Input (
        input hdr_valid,
        output hdr_ready,

        input dest_mac,
        input src_mac,
        input eth_type,
        input version,
        input ihl,
        input dscp,
        input ecn,
        input length,
        input identification,
        input flags,
        input fragment_offset,
        input ttl,
        input protocol,
        input header_checksum,
        input source_ip,
        input dest_ip
    );

    // Ethernet side port
    modport Output (
        output hdr_valid,
        input hdr_ready,

        output dest_mac,
        output src_mac,
        output eth_type,
        output version,
        output ihl,
        output dscp,
        output ecn,
        output length,
        output identification,
        output flags,
        output fragment_offset,
        output ttl,
        output protocol,
        output header_checksum,
        output source_ip,
        output dest_ip
    );

    // Monitor side
    modport Monitor (
        input hdr_valid,
        input hdr_ready,

        input dest_mac,
        input src_mac,
        input eth_type,
        input version,
        input ihl,
        input dscp,
        input ecn,
        input length,
        input identification,
        input flags,
        input fragment_offset,
        input ttl,
        input protocol,
        input header_checksum,
        input source_ip,
        input dest_ip
    );
endinterface

 `default_nettype wire