/**
 * @file axi-stream_if.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief AXI-Stream Interface Definition
 */

`default_nettype none

interface AXIS_IF # (
    parameter int TDATA_WIDTH     = 8,
    parameter int TID_WIDTH       = 0,
    parameter int TDEST_WIDTH     = 0,
    parameter int TUSER_WIDTH     = 0,
    parameter bit TKEEP_ENABLE    = '1,
    parameter bit TWAKEUP_ENABLE  = '0
);
    localparam int TSTRB_WIDTH = TDATA_WIDTH / 8;
    localparam int TKEEP_WIDTH = TDATA_WIDTH / 8;

    var logic                                           tvalid;
    var logic                                           tready;
    var logic [(TDATA_WIDTH > 0 ? TDATA_WIDTH : 1)-1:0] tdata;  // Ensure bit width doesn't become negative
    var logic [(TSTRB_WIDTH > 0 ? TSTRB_WIDTH : 1)-1:0] tstrb;  // Ensure bit width doesn't become negative
    var logic [(TKEEP_WIDTH > 0 ? TKEEP_WIDTH : 1)-1:0] tkeep;  // Ensure bit width doesn't become negative
    var logic                                           tlast;
    var logic [(TID_WIDTH > 0 ? TID_WIDTH : 1)-1:0]     tid;    // Ensure bit width doesn't become negative
    var logic [(TDEST_WIDTH > 0 ? TDEST_WIDTH : 1)-1:0] tdest;  // Ensure bit width doesn't become negative
    var logic [(TUSER_WIDTH > 0 ? TUSER_WIDTH : 1)-1:0] tuser;  // Ensure bit width doesn't become negative
    var logic                                           twakeup;

    modport Transmitter (
        output tvalid,
        input tready,

        output tdata,
        output tstrb,
        output tkeep,
        output tlast,
        output tid,
        output tdest,
        output tuser,
        output twakeup
    );

    modport Receiver (
        input tvalid,
        output tready,

        input tdata,
        input tstrb,
        input tkeep,
        input tlast,
        input tid,
        input tdest,
        input tuser,
        input twakeup
    );

    modport Monitor (
        input tvalid,
        input tready,

        input tdata,
        input tstrb,
        input tkeep,
        input tlast,
        input tid,
        input tdest,
        input tuser,
        input twakeup
    );

endinterface

`default_nettype wire