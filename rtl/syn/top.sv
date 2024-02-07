`timescale 1ns / 1ps
`default_nettype none

module top #(
    /* PARAMETERS */
) (
    input           CLK100MHZ   ,
    input           btn         ,
    output logic    led
);
    example example(
        .clk(CLK100MHZ),
        .led(led)
    );
endmodule