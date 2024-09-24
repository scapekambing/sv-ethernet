/**
 * @file udp_switch_tb.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief Port-based UDP switch testbench
*/

`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

import axis_bfm::*;
import udp_rx_header_bfm::*;

module udp_switch_tb ();
    parameter int PORT_COUNT = 2;
    parameter bit [15:0] PORTS [2] = {1234, 4321};

    logic clk;
    logic reset;

    UDP_TX_HEADER_IF udp_tx_header_if_sink [PORT_COUNT]();
    AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_tx_payload_if_sink [PORT_COUNT]();

    UDP_RX_HEADER_IF udp_rx_header_if_source [PORT_COUNT]();
    AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_rx_payload_if_source [PORT_COUNT]();

    UDP_TX_HEADER_IF udp_tx_header_if_source();
    AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_tx_payload_if_source();

    UDP_RX_HEADER_IF udp_rx_header_if_sink();
    AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_rx_payload_if_sink();

    udp_switch # (
        .PORT_COUNT(PORT_COUNT),
        .PORTS(PORTS)
    ) udp_switch_inst (
        .clk(clk),
        .reset(reset),

        .udp_tx_header_if_sink(udp_tx_header_if_sink),
        .udp_tx_payload_if_sink(udp_tx_payload_if_sink),
        .udp_rx_header_if_source(udp_rx_header_if_source),
        .udp_rx_payload_if_source(udp_rx_payload_if_source),
        .udp_tx_header_if_source(udp_tx_header_if_source),
        .udp_tx_payload_if_source(udp_tx_payload_if_source),
        .udp_rx_header_if_sink(udp_rx_header_if_sink),
        .udp_rx_payload_if_sink(udp_rx_payload_if_sink)
    );

    UDP_RX_HEADER_MASTER_BFM udp_rx_header_bfm;

    always begin
        #5ns;
        clk = !clk;
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 1'b0;
            reset = 1'b1;
            udp_rx_header_bfm = new(udp_rx_header_if_sink);
            udp_rx_header_bfm.reset_task();

            @ (posedge clk);
            reset = 1'b0;
            @ (posedge clk);
        end

        `TEST_CASE("no_match") begin
            udp_rx_header_bfm.simple_transfer(clk, 8852, PORTS[1]+1, 12, 0);
            `CHECK_EQUAL(udp_switch_inst.select, 0);
        end

        `TEST_CASE("port_match") begin
            udp_rx_header_bfm.simple_transfer(clk, 8852, PORTS[1], 12, 0);
            `CHECK_EQUAL(udp_switch_inst.select, 1);
        end
    end

    `WATCHDOG(10us);
endmodule

`default_nettype wire