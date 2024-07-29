


`default_nettype none

module udp_spam # (
    //
) (
    input var logic clk,
    input var logic reset,

    UDP_TX_HEADER_IF.Source udp_tx_header_if,
    AXIS_IF.Transmitter udp_tx_payload_if,

    UDP_RX_HEADER_IF.Sink udp_rx_header_if,
    AXIS_IF.Receiver udp_rx_payload_if,

    input var logic enable
);
    assign udp_rx_header_if.hdr_ready = 1'b1;
    assign udp_rx_payload_if.tready = 1'b1;

    assign udp_tx_header_if.hdr_valid = enable;
    assign udp_tx_header_if.ip_dscp = 0;
    assign udp_tx_header_if.ip_ecn = 0;
    assign udp_tx_header_if.ip_ttl = 64;
    assign udp_tx_header_if.ip_source_ip = {8'd192, 8'd168, 8'd1, 8'd128};
    assign udp_tx_header_if.ip_dest_ip = {8'd192, 8'd168, 8'd1, 8'd2};
    assign udp_tx_header_if.dest_port = 5678;
    assign udp_tx_header_if.source_port = 1234;
    assign udp_tx_header_if.length = 1;
    assign udp_tx_header_if.checksum = 0;

    assign udp_tx_payload_if.tvalid = enable;
    assign udp_tx_payload_if.tdata = 8'd69;
    assign udp_tx_payload_if.tlast = 1'b1;
    assign udp_tx_payload_if.tuser = 1'b0;
endmodule

`default_nettype wire