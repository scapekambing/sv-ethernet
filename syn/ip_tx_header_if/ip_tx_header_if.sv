/**
 * @file ip_tx_header_if.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief IP TX Header (from FPGA to Ethernet) Interface Definition
 */


`default_nettype none

interface IP_TX_HEADER_IF # (
    // No parameters
);
    var logic           hdr_valid;
    var logic           hdr_ready;
    
    var logic [5:0]     dscp;
    var logic [1:0]     ecn;
    var logic [15:0]    length;
    var logic [7:0]     ttl;
    var logic [7:0]     protocol;
    var logic [31:0]    source_ip;
    var logic [31:0]    dest_ip;

    // Ethernet side port
    modport Slave (
        input hdr_valid,
        output hdr_ready,

        input dscp,
        input ecn,
        input length,
        input ttl,
        input protocol,
        input source_ip,
        input dest_ip
    );
    
    // FPGA side port
    modport Master (
        output hdr_valid,
        input hdr_ready,

        output dscp,
        output ecn,
        output length,
        output ttl,
        output protocol,
        output source_ip,
        output dest_ip
    );

    modport Observer (
        input hdr_valid,
        input hdr_ready,

        input dscp,
        input ecn,
        input length,
        input ttl,
        input protocol,
        input source_ip,
        input dest_ip
    );
endinterface

`default_nettype wire