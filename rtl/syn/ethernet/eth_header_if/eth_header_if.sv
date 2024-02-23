/**
 * @file eth_header_if.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief Ethernet Header Interface Definition
 */

 `default_nettype none

interface ETH_HEADER_IF # (
    // No parameters
);
    var logic           valid;
    var logic           ready;
    var logic [47:0]    src_mac;
    var logic [47:0]    dest_mac;
    var logic [15:0]    eth_type;

    // The transmitter outputs ethernet headers
    modport Transmitter (
        output valid,
        input ready,

        output src_mac,
        output dest_mac,
        output eth_type
    );

    // The receiver takes ethernet headers as inputs
    modport Receiver (
        input valid,
        output ready,

        input src_mac,
        input dest_mac,
        input eth_type
    );

    modport Monitor (
        input valid,
        input ready,

        input src_mac,
        input dest_mac,
        input eth_type
    );

endinterface

 `default_nettype wire