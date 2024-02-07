/**
 * @file avalon_if.sv
 *
 * @author Mani Magnusson
 * @date   2023
 *
 * @brief Avalon Interface Definition
 */

`default_nettype none

interface AVALON_IF #(
    parameter int ADDRESS_BITWIDTH    = 0, // Legal values 1-64
    parameter int BYTEENABLE_BITWIDTH = 0, // Legal values 2, 4, 8, 16, 32, 64, 128
    parameter int READDATA_BITWIDTH   = 0, // Legal values 8, 16, 32, 64, 128, 256, 512, 1024
    parameter int WRITEDATA_BITWIDTH  = 0  // Legal values 8, 16, 32, 64, 128, 256, 512, 1024
);
    // SECTION: Signals

    var logic       [ADDR_BITWIDTH-1:0] address;
    var logic [BYTEENABLE_BITWIDTH-1:0] byteenable;
    var logic                           read;
    var logic                           write;
    var logic                           waitrequest;
    var logic   [READDATA_BITWIDTH-1:0] readdata;
    var logic                     [1:0] response;
    var logic  [WRITEDATA_BITWIDTH-1:0] writedata;

    // SECTION: Modports

    modport Host (
        
        output address,
        output byteenable,
        output read,
        output write,
        output writedata,
        input readdata,
        input waitrequest,
        input response
        
    );


    modport Agent (

        input address,
        input byteenable,
        input read,
        input write,
        input writedata,
        output readdata,
        output waitrequest,
        output response

    );


    modport Monitor (

        input address,
        input byteenable,
        input read,
        input write,
        input writedata,
        input readdata,
        input waitrequest,
        input response

    );
endinterface

`default_nettype wire