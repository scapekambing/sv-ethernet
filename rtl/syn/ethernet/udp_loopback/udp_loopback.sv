/**
 * @file udp_loopback.sv
 * 
 * @author Mani Magnusson
 * @date   2024
 * 
 * @brief UDP message loopback for testing of the eth stack
 */

`default_nettype none

module udp_loopback # (
    parameter bit [15:0] UDP_PORT = 1234
) (
    input var logic clk,
    input var logic reset,

    input var logic [31:0] local_ip,

    UDP_TX_HEADER_IF.Source udp_tx_header_if,
    AXIS_IF.Transmitter udp_tx_payload_if,

    UDP_RX_HEADER_IF.Sink udp_rx_header_if,
    AXIS_IF.Receiver udp_rx_payload_if
);
    var logic match;
    var logic match_n;
    var logic match_reg = 1'b0;
    var logic match_reg_n = 1'b0;

    assign match = udp_rx_header_if.dest_port == UDP_PORT;
    assign match_n = !match;

    always_ff @ (posedge clk) begin
        if (reset) begin
            match_reg <= 1'b0;
            match_reg_n <= 1'b0;
        end else begin
            if (udp_rx_payload_if.tvalid) begin
                if ((!match_reg && !match_reg_n) || (udp_rx_payload_if.tvalid && udp_rx_payload_if.tready && udp_rx_payload_if.tlast)) begin
                    match_reg <= match;
                    match_reg_n <= match_n;
                end
            end else begin
                match_reg <= 1'b0;
                match_reg_n <= 1'b0;
            end
        end
    end

    assign udp_tx_header_if.hdr_valid = udp_rx_header_if.hdr_valid && match;
    assign udp_rx_header_if.hdr_ready = (udp_tx_header_if.hdr_ready && match) || !match;
    assign udp_tx_header_if.ip_dscp = 0;
    assign udp_tx_header_if.ip_ecn = 0;
    assign udp_tx_header_if.ip_ttl = 64;
    assign udp_tx_header_if.ip_source_ip = local_ip;
    assign udp_tx_header_if.ip_dest_ip = udp_rx_header_if.ip_source_ip;
    assign udp_tx_header_if.source_port = udp_rx_header_if.dest_port;
    assign udp_tx_header_if.dest_port = udp_rx_header_if.source_port;
    assign udp_tx_header_if.length = udp_rx_header_if.length;
    assign udp_tx_header_if.checksum = 0;

    assign udp_tx_payload_if.tdata = udp_rx_payload_if.tdata;
    assign udp_tx_payload_if.tvalid = udp_rx_payload_if.tvalid && match_reg;
    assign udp_rx_payload_if.tready = (udp_tx_payload_if.tready && match_reg) || match_reg_n;
    assign udp_tx_payload_if.tlast = udp_rx_payload_if.tlast;
    assign udp_tx_payload_if.tuser = udp_rx_payload_if.tuser;
endmodule

`default_nettype wire