/**
 * @file example_tb.sv
 *
 * @author Alex Lao <lao.alex.512@gmail.com>
 * @date   2022
 *
 * @brief Example RTL module testbench written in SystemVerilog
 */

`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

module example_tb ();
    parameter bit INVERTER = 0;

    // SECTION: Signals

    logic clk;

    logic dut_in;
    logic dut_out;

    // SECTION: Modules

    example #(
        .INVERTER ( INVERTER )
    ) DUT (
        .in  ( dut_in  ),
        .out ( dut_out )
    );

    // SECTION: Test Logic

    always begin
        #5;
        clk <= !clk;
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 1'b0;
        end

        `TEST_CASE("test_zero") begin
            dut_in = 1'b0;
            @(posedge clk);
            `CHECK_EQUAL(dut_out, INVERTER);
        end

        `TEST_CASE("test_one") begin
            dut_in = 1'b1;
            @(posedge clk);
            `CHECK_EQUAL(dut_out, !INVERTER);
        end
   end

   `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
