/**
 * @file axis_bfm_tb.sv
 *
 * @author Mani Magnusson
 * @date   2023
 *
 * @brief AXI-Stream bus functional testbench
 */

/* TODO:
 *  - Write Python code
 *  - Test everything
 *  - Implement back-to-back transfers (needs BFM modifications)
 */

`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

import axis_bfm::*;

module axis_bfm_tb ();
    parameter int AXIS_TDATA_WIDTH      = 8;
    parameter int AXIS_TID_WIDTH        = 0;
    parameter int AXIS_TDEST_WIDTH      = 0;
    parameter int AXIS_TUSER_WIDTH      = 0;
    parameter bit AXIS_TKEEP_ENABLE     = '0;
    parameter bit AXIS_TWAKEUP_ENABLE   = '0;

    localparam int AXIS_TSTRB_WIDTH = AXIS_TDATA_WIDTH / 8;
    localparam int AXIS_TKEEP_WIDTH = AXIS_TDATA_WIDTH / 8;

    parameter [AXIS_TDATA_WIDTH-1:0]                                TDATA   = 0;
    parameter [(AXIS_TSTRB_WIDTH > 0 ? AXIS_TSTRB_WIDTH : 1)-1:0]   TSTRB   = 0;
    parameter [(AXIS_TKEEP_WIDTH > 0 ? AXIS_TKEEP_WIDTH : 1)-1:0]   TKEEP   = 0;
    parameter bit                                                   TLAST   = 0;
    parameter [(AXIS_TID_WIDTH > 0 ? AXIS_TID_WIDTH : 1)-1:0]       TID     = 0;
    parameter [(AXIS_TDEST_WIDTH > 0 ? AXIS_TDEST_WIDTH : 1)-1:0]   TDEST   = 0;
    parameter [(AXIS_TUSER_WIDTH > 0 ? AXIS_TUSER_WIDTH : 1)-1:0]   TUSER   = 0;
    parameter bit                                                   TWAKEUP = 0;

    parameter bit USE_RANDOM_WAIT = 1'b0;

    logic clk,
    logic reset,

    AXIS_IF # (
        .TDATA_WIDTH(AXIS_TDATA_WIDTH),
        .TID_WIDTH(AXIS_TID_WIDTH),
        .TDEST_WIDTH(AXIS_TDEST_WIDTH),
        .TUSER_WIDTH(AXIS_TUSER_WIDTH),
        .TKEEP_ENABLE(AXIS_TKEEP_ENABLE),
        .TWAKEUP_ENABLE(AXIS_TWAKEUP_ENABLE)
    ) axis_if();

    AXIS_Master_BFM master_bfm;
    AXIS_Slave_BFM slave_bfm;

    always begin
        #5ns;
        clk = !clk;
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 1'b0;
            master_bfm = new(axis_if.Transmitter);
            slave_bfm = new(axis_if.Receiver);
            master_bfm.reset_task();
            slave_bfm.reset_task();
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

            fork
                begin
                    master_bfm.transfer(clk, TDATA, '0, '0, 1'b0, '0, '0, '0, 1'b0);
                end
                begin
                    slave_bfm.transfer(clk, tdata_out, tstrb_out, tkeep_out, tlast_out, tid_out, tdest_out, tuser_out, twakeup_out);
                end
            join

            $display("TDATA: 0x%0H", tdata_out);

            @ (posedge clk);
            `CHECK_EQUAL(tdata_out, TDATA);
        end

        `TEST_CASE("Last_transfer") begin
            logic [AXIS_TDATA_WIDTH-1:0] tdata_out;
            logic [AXIS_TSTRB_WIDTH-1:0] tstrb_out;
            logic [AXIS_TKEEP_WIDTH-1:0] tkeep_out;
            logic tlast_out;
            logic [AXIS_TID_WIDTH-1:0] tid_out;
            logic [AXIS_TDEST_WIDTH-1:0] tdest_out;
            logic [AXIS_TUSER_WIDTH-1:0] tuser_out;
            logic twakeup_out;

            fork
                begin
                    master_bfm.transfer(clk, TDATA, '0, '0, 1'b1, '0, '0, '0, 1'b0);
                end
                begin
                    slave_bfm.transfer(clk, tdata_out, tstrb_out, tkeep_out, tlast_out, tid_out, tdest_out, tuser_out, twakeup_out);
                end
            join

            $display("TDATA: 0x%0H, TLAST: 0x%0H", tdata_out, tlast_out);

            @ (posedge clk);
            `CHECK_EQUAL(tdata_out, TDATA);
            `CHECK_EQUAL(tlast_out, 1'b1);
        end

        `TEST_CASE("Full_transfer") begin
            logic [AXIS_TDATA_WIDTH-1:0] tdata_out;
            logic [AXIS_TSTRB_WIDTH-1:0] tstrb_out;
            logic [AXIS_TKEEP_WIDTH-1:0] tkeep_out;
            logic tlast_out;
            logic [AXIS_TID_WIDTH-1:0] tid_out;
            logic [AXIS_TDEST_WIDTH-1:0] tdest_out;
            logic [AXIS_TUSER_WIDTH-1:0] tuser_out;
            logic twakeup_out;

            fork
                begin
                    master_bfm.transfer(clk, TDATA, TSTRB, TKEEP, TLAST, TID, TDEST, TUSER, TWAKEUP);
                end
                begin
                    slave_bfm.transfer(clk, tdata_out, tstrb_out, tkeep_out, tlast_out, tid_out, tdest_out, tuser_out, twakeup_out);
                end
            join
            
            // TODO: Implement the display call
            //$display("TDATA: 0x%0H, TLAST: 0x%0H", tdata_out, tlast_out);

            @ (posedge clk);
            `CHECK_EQUAL(tdata_out, TDATA);
            `CHECK_EQUAL(tstrb_out, TSTRB);
            `CHECK_EQUAL(tkeep_out, TKEEP);
            `CHECK_EQUAL(tlast_out, TLAST);
            `CHECK_EQUAL(tid_out, TID);
            `CHECK_EQUAL(tdest_out, TDEST);
            `CHECK_EQUAL(tuser_out, TUSER);
            `CHECK_EQUAL(twakeup_out, TWAKEUP);
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire