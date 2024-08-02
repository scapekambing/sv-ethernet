

`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

import axis_bfm::*;
import udp_tx_header_bfm::*;
import udp_rx_header_bfm::*;

module udp_loopback_tb ();
    parameter bit [15:0] UDP_PORT = 1234;
    parameter bit [31:0] LOCAL_IP = {8'd192, 8'd168, 8'd1, 8'd128};

    logic clk;
    logic reset;

    UDP_TX_HEADER_IF udp_tx_header_if();
    AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_tx_payload_if();

    UDP_RX_HEADER_IF udp_rx_header_if();
    AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_rx_payload_if();

    udp_loopback # (
        .UDP_PORT(UDP_PORT)
    ) udp_loopback_inst (
        .clk(clk),
        .reset(reset),
        
        .local_ip(LOCAL_IP),

        .udp_tx_header_if(udp_tx_header_if),
        .udp_tx_payload_if(udp_tx_payload_if),
        .udp_rx_header_if(udp_rx_header_if),
        .udp_rx_payload_if(udp_rx_payload_if)
    );

    UDP_TX_HEADER_SLAVE_BFM udp_tx_header_bfm;
    AXIS_Slave_BFM # (.user_width(1)) udp_tx_payload_bfm;

    UDP_RX_HEADER_MASTER_BFM udp_rx_header_bfm;
    AXIS_Master_BFM # (.user_width(1)) udp_rx_payload_bfm;

    always begin
        #5ns;
        clk = !clk;
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 1'b0;
            reset = 1'b1;

            udp_tx_header_bfm = new(udp_tx_header_if);
            udp_tx_payload_bfm =  new(udp_tx_payload_if);
            udp_rx_header_bfm = new(udp_rx_header_if);
            udp_rx_payload_bfm =  new(udp_rx_payload_if);

            udp_tx_header_bfm.reset_task();
            udp_tx_payload_bfm.reset_task();
            udp_rx_header_bfm.reset_task();
            udp_rx_payload_bfm.reset_task();

            @ (posedge clk);
            reset = 1'b0;
            @ (posedge clk);
        end

        `TEST_CASE("Single transfer") begin
            logic [5:0] ip_dscp;
            logic [1:0] ip_ecn;
            logic [7:0] ip_ttl;
            logic [31:0] ip_source_ip;
            logic [31:0] ip_dest_ip;
            logic [15:0] source_port;
            logic [15:0] dest_port;
            logic [15:0] length;
            logic [15:0] checksum;

            logic [7:0] txdata;
            logic [1:0] txstrb;
            logic [1:0] txkeep;
            logic       txlast;
            logic       txid;
            logic       txdest;
            logic       txuser;
            logic       txwakeup;

            fork
                begin
                    udp_rx_header_bfm.simple_transfer(clk, 5678, 1234, 8*1, 0);
                end

                begin
                    udp_rx_payload_bfm.transfer(.clk(clk), .data(8'h20));
                    udp_rx_payload_bfm.transfer(.clk(clk), .data(8'h21));
                    udp_rx_payload_bfm.transfer(.clk(clk), .data(8'h22));
                    udp_rx_payload_bfm.transfer(.clk(clk), .data(8'h23));
                    udp_rx_payload_bfm.transfer(.clk(clk), .data(8'h24));
                    udp_rx_payload_bfm.transfer(.clk(clk), .data(8'h25));
                    udp_rx_payload_bfm.transfer(.clk(clk), .data(8'h26));
                    udp_rx_payload_bfm.transfer(.clk(clk), .data(8'h27), .last(1'b1));
                end

                begin
                    udp_tx_header_bfm.transfer(
                        clk,
                        ip_dscp,
                        ip_ecn,
                        ip_ttl,
                        ip_source_ip,
                        ip_dest_ip,
                        source_port,
                        dest_port,
                        length,
                        checksum
                    );

                    `CHECK_EQUAL(ip_dscp, 0);
                    `CHECK_EQUAL(ip_ecn, 0);
                    `CHECK_EQUAL(ip_ttl, 64);
                    `CHECK_EQUAL(ip_dest_ip, {8'd192, 8'd168, 8'd1, 8'd152});
                    `CHECK_EQUAL(ip_source_ip, LOCAL_IP);
                    `CHECK_EQUAL(dest_port, 5678);
                    `CHECK_EQUAL(source_port, 1234);
                    `CHECK_EQUAL(length, 8);
                    `CHECK_EQUAL(checksum, 0);
                end

                begin
                    for (int i = 0; i < 8; i++) begin
                        udp_tx_payload_bfm.transfer(
                            clk,
                            txdata,
                            txstrb,
                            txkeep,
                            txlast,
                            txid,
                            txdest,
                            txuser,
                            txwakeup
                        );
                        `CHECK_EQUAL(txdata, 8'h20 + i);
                        `CHECK_EQUAL(txlast, 1'(i == 7));
                        `CHECK_EQUAL(txuser, 0);
                    end
                end
            join

        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire