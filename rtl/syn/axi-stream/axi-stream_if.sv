/**
 * @file axi-stream_if.sv
 *
 * @author Mani Magnusson
 * @date   2023
 *
 * @brief AXI-Stream Interface Definition
 */

`default_nettype none

interface AXIS_IF # (
  parameter TDATA_WIDTH   = 32,
  parameter TID_WIDTH     = ??,
  parameter TDEST_WIDTH   = ??,
  parameter TUSER_WIDTH   = ??
);
    // Signals
    var logic                       tvalid;
    var logic                       tready;
    var logic [TDATA_WIDTH-1:0]     tdata;
    var logic [(TDATA_WIDTH/8)-1:0] tstrb;
    var logic [(TDATA_WIDTH/8)-1:0] tkeep;
    var logic                       tlast;
    var logic [TID_WIDTH-1:0]       tid;
    var logic [TDEST_WIDTH-1:0]     tdest;
    var logic [TUSER WIDTH-1:0]     tuser;
    var logic                       twakeup;

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
        input tsrb,
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
    )

endinterface

`default_nettype wire