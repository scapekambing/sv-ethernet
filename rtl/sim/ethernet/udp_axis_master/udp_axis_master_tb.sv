/**
 * @file udp_axis_master.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief UDP to AXI-Stream master with packet ID
*/

/* TODO:
 *
 */

`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

import axis_bfm::*;
import udp_tx_header_bfm::*;
import udp_rx_header_bfm::*;

module udp_axis_master_tb ();
    parameter int UDP_SOURCE_PORT = 8891;
    parameter int UDP_DEST_PORT = 4321;
    parameter int AXIS_OUT_TDATA_WIDTH = 32;

    logic clk;
    logic reset;

    UDP_TX_HEADER_IF udp_tx_header_if();
    AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_tx_payload_if();

    UDP_RX_HEADER_IF udp_rx_header_if();
    AXIS_IF # (.TUSER_WIDTH(1), .TKEEP_ENABLE(0)) udp_rx_payload_if();

    AXIS_IF # (.TDATA_WIDTH(AXIS_OUT_TDATA_WIDTH), .TUSER_WIDTH(1)) axis_out_if();

    udp_axis_master # (
        .UDP_PORT(UDP_DEST_PORT)
    ) udp_axis_master_inst (
        .clk(clk),
        .reset(reset),
        
        .udp_tx_header_if(udp_tx_header_if),
        .udp_tx_payload_if(udp_tx_payload_if),

        .udp_rx_header_if(udp_rx_header_if),
        .udp_rx_payload_if(udp_rx_payload_if),

        .out_axis_if(axis_out_if)
    );

    UDP_TX_HEADER_SLAVE_BFM udp_tx_header_bfm;
    AXIS_Slave_BFM # (.user_width(1)) udp_tx_payload_bfm;

    UDP_RX_HEADER_MASTER_BFM udp_rx_header_bfm;
    AXIS_Master_BFM # (.user_width(1)) udp_rx_payload_bfm;

    AXIS_Slave_BFM # (
        .data_width(AXIS_OUT_TDATA_WIDTH),
        .keep_enable(1),
        .user_width(1)
    ) axis_out_bfm;

    always begin
        #5ns;
        clk = !clk;
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 1'b0;
            reset = 1'b1;

            udp_tx_header_bfm   = new(udp_tx_header_if);
            udp_tx_payload_bfm  = new(udp_tx_payload_if);
            udp_rx_header_bfm   = new(udp_rx_header_if);
            udp_rx_payload_bfm  = new(udp_rx_payload_if);
            axis_out_bfm        = new(axis_out_if);

            udp_tx_header_bfm.reset_task();
            udp_tx_payload_bfm.reset_task();
            udp_rx_header_bfm.reset_task();
            udp_rx_payload_bfm.reset_task();
            axis_out_bfm.reset_task();

            @ (posedge clk);
            reset = 1'b0;
            @ (posedge clk);
        end

        `TEST_CASE("wrong_port") begin
            udp_rx_header_bfm.simple_transfer(clk, UDP_SOURCE_PORT, UDP_DEST_PORT+1, 12, 0);
            
            udp_rx_payload_bfm.transfer(.clk(clk), .data(8'h25));
            udp_rx_payload_bfm.transfer(.clk(clk), .data(8'h00));
            udp_rx_payload_bfm.transfer(.clk(clk), .data(8'h30));
            udp_rx_payload_bfm.transfer(.clk(clk), .data(8'hA0), .last(1'b1));

            @ (posedge clk);

            `CHECK_EQUAL(udp_axis_master_inst.state, udp_axis_master_inst.STATE_RX_HEADER)
        end

        //`TEST_CASE("single_transfer") begin
        //end
    end
endmodule

`default_nettype wire