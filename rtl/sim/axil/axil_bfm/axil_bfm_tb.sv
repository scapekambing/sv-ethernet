/**
 * @file axil_bfm_tb.sv
 *
 * @author Mani Magnusson
 * @date   2023
 *
 * @brief AXI4-Lite bus functional testbench
 */

 /* TODO:
 *  - Add tests with variable response and protection fields
*/

`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

import axil_bfm::*;

module axil_bfm_tb ();
    parameter [31:0] AWADDR = 0;
    parameter [31:0] WDATA = 0;
    parameter [31:0] ARADDR = 0;
    parameter [31:0] RDATA = 0;
    parameter bit USE_RANDOM_WAIT = 0;

    // SECTION: Signals

    logic clk;
    logic reset;

    AXIL_IF axil_if();

    // SECTION: Modules

    AXIL_Master_BFM master_bfm;
    AXIL_Slave_BFM slave_bfm;

    // SECTION: Test Logic

    always begin
        #5ns; // Sets the clock to 100 MHz
        clk = !clk;
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 1'b0;
            master_bfm = new(axil_if.Master, USE_RANDOM_WAIT);
            slave_bfm = new(axil_if.Slave, USE_RANDOM_WAIT);
            master_bfm.reset_task();
            slave_bfm.reset_task();
        end

        `TEST_CASE("Write_transfer") begin
            logic [31:0] awaddr_out;
            logic [31:0] wdata_out;
            logic [3:0] strobe_out;
            logic [2:0] awprot_out;
            logic [1:0] bresp_out;
            fork
                begin
                    master_bfm.write(clk, AWADDR, axil_if.AXI_PROT_UNPRIVILEGED_NONSECURE_DATA, WDATA, '1, 0, bresp_out);
                end
                begin
                    slave_bfm.write(clk, awaddr_out, wdata_out, strobe_out, awprot_out, axil_if.AXI_RESP_OKAY);
                end
            join
            $display("AWADDR: 0x%0H, WDATA: 0x%0H", awaddr_out, wdata_out);
            @(posedge clk);
            `CHECK_EQUAL(awaddr_out, AWADDR);
            `CHECK_EQUAL(wdata_out, WDATA);
            `CHECK_EQUAL(awprot_out, axil_if.AXI_PROT_UNPRIVILEGED_NONSECURE_DATA);
            `CHECK_EQUAL(bresp_out, axil_if.AXI_RESP_OKAY);
        end

        `TEST_CASE("Read transfer") begin
            logic [31:0] araddr_out;
            logic [2:0] arprot_out;
            logic [31:0] rdata_out;
            logic [1:0] rresp_out;
            fork
                begin
                    master_bfm.read(clk, ARADDR, axil_if.AXI_PROT_UNPRIVILEGED_NONSECURE_DATA, rdata_out, rresp_out);
                end
                begin
                    slave_bfm.artransfer(clk, araddr_out, arprot_out);
                    // Let's just say this is the data at the address requested
                    slave_bfm.rtransfer(clk, RDATA, axil_if.AXI_RESP_OKAY);
                end
            join
            @(posedge clk);
            `CHECK_EQUAL(araddr_out, ARADDR);
            `CHECK_EQUAL(arprot_out, axil_if.AXI_PROT_UNPRIVILEGED_NONSECURE_DATA);
            `CHECK_EQUAL(rdata_out, RDATA);
            `CHECK_EQUAL(rresp_out, axil_if.AXI_RESP_OKAY);
        end

        // Should not be necessary
        //`TEST_CASE_CLEANUP begin
        //    master_bfm.reset_task();
        //    slave_bfm.reset_task();
        //end
   end

   `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
