/**
 * @file axis_fifo_wrapper_tb.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief axis_fifo_wrapper testbench
 */

/* TODO:
 *  - Implement back-to-back transfers (needs BFM modifications)
 */

`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

import axis_bfm::*;

module axis_fifo_wrapper_tb ();
    parameter int AXIS_TDATA_WIDTH      = 8;
    parameter int AXIS_TID_WIDTH        = 0;
    parameter int AXIS_TDEST_WIDTH      = 0;
    parameter int AXIS_TUSER_WIDTH      = 0;
    parameter bit AXIS_TKEEP_ENABLE     = '0;
    
    localparam bit AXIS_TWAKEUP_ENABLE   = '0;

    localparam int AXIS_TSTRB_WIDTH = AXIS_TDATA_WIDTH / 8;
    localparam int AXIS_TKEEP_WIDTH = AXIS_TDATA_WIDTH / 8;

    parameter [AXIS_TDATA_WIDTH-1:0]                                TDATA   = 0;
    parameter [(AXIS_TSTRB_WIDTH > 0 ? AXIS_TSTRB_WIDTH : 1)-1:0]   TSTRB   = 0;
    parameter [(AXIS_TKEEP_WIDTH > 0 ? AXIS_TKEEP_WIDTH : 1)-1:0]   TKEEP   = 0;
    parameter bit                                                   TLAST   = 0;
    parameter [(AXIS_TID_WIDTH > 0 ? AXIS_TID_WIDTH : 1)-1:0]       TID     = 0;
    parameter [(AXIS_TDEST_WIDTH > 0 ? AXIS_TDEST_WIDTH : 1)-1:0]   TDEST   = 0;
    parameter [(AXIS_TUSER_WIDTH > 0 ? AXIS_TUSER_WIDTH : 1)-1:0]   TUSER   = 0;

    parameter bit USE_RANDOM_WAIT = 1'b0;

    localparam int DEPTH = 4096;

    logic clk;
    logic reset;

    logic                   pause_req;
    logic                   pause_ack;
    logic [$clog2(DEPTH):0] status_depth;
    logic [$clog2(DEPTH):0] status_depth_commit;
    logic                   status_overflow;
    logic                   status_bad_frame;
    logic                   status_good_frame;

    AXIS_IF # (
        .TDATA_WIDTH(AXIS_TDATA_WIDTH),
        .TID_WIDTH(AXIS_TID_WIDTH),
        .TDEST_WIDTH(AXIS_TDEST_WIDTH),
        .TUSER_WIDTH(AXIS_TUSER_WIDTH),
        .TKEEP_ENABLE(AXIS_TKEEP_ENABLE),
        .TWAKEUP_ENABLE(AXIS_TWAKEUP_ENABLE)
    ) axis_if_in();

    AXIS_IF # (
        .TDATA_WIDTH(AXIS_TDATA_WIDTH),
        .TID_WIDTH(AXIS_TID_WIDTH),
        .TDEST_WIDTH(AXIS_TDEST_WIDTH),
        .TUSER_WIDTH(AXIS_TUSER_WIDTH),
        .TKEEP_ENABLE(AXIS_TKEEP_ENABLE),
        .TWAKEUP_ENABLE(AXIS_TWAKEUP_ENABLE)
    ) axis_if_out();

    axis_fifo_wrapper # (
        .DEPTH(DEPTH)
    ) axis_fifo_inst (
        .clk(clk),
        .reset(reset),
        .in_axis_if(axis_if_in),
        .out_axis_if(axis_if_out),
        .pause_req(pause_req),
        .pause_ack(pause_ack),
        .status_depth(status_depth),
        .status_depth_commit(status_depth_commit),
        .status_overflow(status_overflow),
        .status_bad_frame(status_bad_frame),
        .status_good_frame(status_good_frame)
    );

    AXIS_Master_BFM # (
        .data_width(AXIS_TDATA_WIDTH),
        .id_width(AXIS_TID_WIDTH),
        .dest_width(AXIS_TDEST_WIDTH),
        .user_width(AXIS_TUSER_WIDTH),
        .keep_enable(AXIS_TKEEP_ENABLE),
        .wakeup_enable(AXIS_TWAKEUP_ENABLE)
    ) master_bfm;

    AXIS_Slave_BFM # (
        .data_width(AXIS_TDATA_WIDTH),
        .id_width(AXIS_TID_WIDTH),
        .dest_width(AXIS_TDEST_WIDTH),
        .user_width(AXIS_TUSER_WIDTH),
        .keep_enable(AXIS_TKEEP_ENABLE),
        .wakeup_enable(AXIS_TWAKEUP_ENABLE)
    ) slave_bfm;

    always begin
        #5ns;
        clk = !clk;
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 1'b0;
            reset = 1'b1;

            master_bfm = new(axis_if_in);
            slave_bfm = new(axis_if_out);
            master_bfm.reset_task();
            slave_bfm.reset_task();

            @ (posedge clk);
            reset = 1'b0;
            @ (posedge clk);
        end

        `TEST_CASE("Simple_transfer") begin
            logic [AXIS_TDATA_WIDTH-1:0] tdata_out;
            logic [AXIS_TSTRB_WIDTH-1:0] tstrb_out;
            logic [AXIS_TKEEP_WIDTH-1:0] tkeep_out;
            logic tlast_out;
            logic [AXIS_TID_WIDTH-1:0] tid_out;
            logic [AXIS_TDEST_WIDTH-1:0] tdest_out;
            logic [AXIS_TUSER_WIDTH-1:0] tuser_out;
            logic twakeup_out;

            master_bfm.transfer(clk, TDATA, '0, '0, 1'b1, '0, '0, '0, 1'b0);
            slave_bfm.transfer(clk, tdata_out, tstrb_out, tkeep_out, tlast_out, tid_out, tdest_out, tuser_out, twakeup_out);

            @ (posedge clk);
            $display("TDATA: 0x%0H", tdata_out);
            `CHECK_EQUAL(tdata_out, TDATA);
        end

        `TEST_CASE("Simple_two_transfers") begin
            logic [AXIS_TDATA_WIDTH-1:0] tdata_out;
            logic [AXIS_TSTRB_WIDTH-1:0] tstrb_out;
            logic [AXIS_TKEEP_WIDTH-1:0] tkeep_out;
            logic tlast_out;
            logic [AXIS_TID_WIDTH-1:0] tid_out;
            logic [AXIS_TDEST_WIDTH-1:0] tdest_out;
            logic [AXIS_TUSER_WIDTH-1:0] tuser_out;
            logic twakeup_out;

            master_bfm.transfer(clk, TDATA, '0, '0, 1'b0, '0, '0, '0, 1'b0);
            master_bfm.transfer(clk, TDATA+1, '0, '0, 1'b1, '0, '0, '0, 1'b0);
            slave_bfm.transfer(clk, tdata_out, tstrb_out, tkeep_out, tlast_out, tid_out, tdest_out, tuser_out, twakeup_out);

            @ (posedge clk);
            $display("TDATA: 0x%0H, TLAST: 0x%0H", tdata_out, tlast_out);
            `CHECK_EQUAL(tdata_out, TDATA);
            `CHECK_EQUAL(tlast_out, 1'b0);

            slave_bfm.transfer(clk, tdata_out, tstrb_out, tkeep_out, tlast_out, tid_out, tdest_out, tuser_out, twakeup_out);

            @ (posedge clk);
            $display("TDATA: 0x%0H, TLAST: 0x%0H", tdata_out, tlast_out);
            `CHECK_EQUAL(tdata_out, TDATA+1);
            `CHECK_EQUAL(tlast_out, 1'b1);
        end

        `TEST_CASE("Full_round") begin
            logic [AXIS_TDATA_WIDTH-1:0] tdata_out;
            logic [AXIS_TSTRB_WIDTH-1:0] tstrb_out;
            logic [AXIS_TKEEP_WIDTH-1:0] tkeep_out;
            logic tlast_out;
            logic [AXIS_TID_WIDTH-1:0] tid_out;
            logic [AXIS_TDEST_WIDTH-1:0] tdest_out;
            logic [AXIS_TUSER_WIDTH-1:0] tuser_out;
            logic twakeup_out;

            master_bfm.transfer(clk, TDATA, TSTRB, TKEEP, 1'b0, TID, TDEST, TUSER, 1'b0);
            master_bfm.transfer(clk, TDATA+1, TSTRB, TKEEP, 1'b1, TID, TDEST, TUSER, 1'b0);
            slave_bfm.transfer(clk, tdata_out, tstrb_out, tkeep_out, tlast_out, tid_out, tdest_out, tuser_out, twakeup_out);

            @ (posedge clk);
            $display("TDATA: 0x%0H, TLAST: 0x%0H", tdata_out, tlast_out);
            `CHECK_EQUAL(tdata_out, TDATA);
            `CHECK_EQUAL(tid_out, TID);
            `CHECK_EQUAL(tdest_out, TDEST);
            `CHECK_EQUAL(tuser_out, TUSER);
            `CHECK_EQUAL(tlast_out, 1'b0);

            slave_bfm.transfer(clk, tdata_out, tstrb_out, tkeep_out, tlast_out, tid_out, tdest_out, tuser_out, twakeup_out);

            @ (posedge clk);
            $display("TDATA: 0x%0H, TLAST: 0x%0H", tdata_out, tlast_out);
            `CHECK_EQUAL(tdata_out, TDATA+1);
            `CHECK_EQUAL(tid_out, TID);
            `CHECK_EQUAL(tdest_out, TDEST);
            `CHECK_EQUAL(tuser_out, TUSER);
            `CHECK_EQUAL(tlast_out, 1'b1);
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire