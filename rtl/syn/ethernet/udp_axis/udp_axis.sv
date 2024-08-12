/**
 * @file udp_axis.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief UDP to AXI-Stream (receiver) with packet ID
*/

`default_nettype none

module udp_axis # (
    parameter bit [15:0] UDP_PORT = 4321,
    parameter int FIFO_DEPTH = 4096
) (
    input var logic clk,
    input var logic reset,

    UDP_TX_HEADER_IF.Source udp_tx_header_if,
    AXIS_IF.Transmitter udp_tx_payload_if,

    UDP_RX_HEADER_IF.Sink udp_rx_header_if,
    AXIS_IF.Receiver udp_rx_payload_if,

    AXIS_IF.Transmitter axis_if
);

var logic [31:0] source_ip;
var logic [31:0] dest_ip;
var logic [15:0] source_port;
var logic [15:0] dest_port;
var logic [15:0] frame_length;

endmodule