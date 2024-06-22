

`timescale 1ns / 1ps
`default_nettype none

`include "vunit_defines.svh"

import axil_bfm::*;

module axil_ram_wrapper_tb ();
    parameter bit PIPELINE_OUTPUT = 1'b0;

    parameter int ADDR_WIDTH = 16;
    parameter int DATA_WIDTH = 32;

    parameter [ADDR_WIDTH-1:0] ADDRESS_1 = 132;
    parameter [ADDR_WIDTH-1:0] ADDRESS_2 = 78;

    parameter [DATA_WIDTH-1:0] DATA_1 = 88943;
    parameter [DATA_WIDTH-1:0] DATA_2 = 1332;
    
    parameter bit USE_RANDOM_WAIT = 1'b0;

    logic clk;
    logic reset;

    AXIL_IF # (
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) axil_if();

    axil_ram_wrapper # (
        .PIPELINE_OUTPUT(PIPELINE_OUTPUT)
    ) axil_ram_wrapper_inst (
        .clk(clk),
        .reset(reset),
        .axil_if(axil_if)
    );

    AXIL_Master_BFM # (
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) axil_bfm;

    always begin
        #5ns;
        clk = !clk;
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 1'b0;
            reset = 1'b1;

            axil_bfm = new(axil_if, USE_RANDOM_WAIT);
            axil_bfm.reset_task();

            @ (posedge clk);
            reset = 1'b0;
            @ (posedge clk);
        end

        `TEST_CASE("simple_write_read") begin
            logic [DATA_WIDTH-1:0] data;
            axil_bfm.simple_write(clk, ADDRESS_1, DATA_1);
            axil_bfm.simple_write(clk, ADDRESS_2, DATA_2);

            axil_bfm.simple_read(clk, ADDRESS_1, data);
            $display("First: 0x%H", data);
            `CHECK_EQUAL(data, DATA_1, "First read");

            axil_bfm.simple_read(clk, ADDRESS_2, data);
            $display("First: 0x%H", data);
            `CHECK_EQUAL(data, DATA_2, "Second read");
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire