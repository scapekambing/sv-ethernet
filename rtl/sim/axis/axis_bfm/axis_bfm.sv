/**
 * @file axis_bfm.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief AXI-Stream bus functional model
 */

/* TODO:
 *  - Implement back-to-back transfers
 */

`timescale 1ns / 1ps
`default_nettype none

package axis_bfm;
class AXIS_Slave_BFM # (
    parameter int data_width    = 8,
    parameter int id_width      = 0,
    parameter int dest_width    = 0,
    parameter int user_width    = 0,
    parameter bit keep_enable   = 1'b0,
    parameter bit wakeup_enable = 1'b0
);
    localparam int strobe_width = data_width / 8;
    localparam int keep_width   = data_width / 8;

    typedef virtual AXIS_IF # (
        .TDATA_WIDTH(data_width),
        .TID_WIDTH(id_width),
        .TDEST_WIDTH(dest_width),
        .TUSER_WIDTH(user_width),
        .TKEEP_ENABLE(keep_enable),
        .TWAKEUP_ENABLE(wakeup_enable)
    ) v_axis_if_t;

    v_axis_if_t axis_if;

    function new(v_axis_if_t axis_if_in);
        this.axis_if = axis_if_in;
    endfunction

    task automatic reset_task();
        this.axis_if.tready = 1'b0;
    endtask

    task automatic transfer(
        ref var logic clk,
        output var logic [data_width-1:0] data,
        output var logic [strobe_width-1:0] strobe,
        output var logic [keep_width-1:0] keep,
        output var logic last,
        output var logic [id_width-1:0] id,
        output var logic [dest_width-1:0] dest,
        output var logic [user_width-1:0] user,
        output var logic wakeup
    );
        this.axis_if.tready = 1'b1;

        do begin
            @ (posedge clk);
        end while (this.axis_if.tvalid === 1'b0);
        
        data = this.axis_if.tdata;
        strobe = this.axis_if.tstrb;
        keep = this.axis_if.tkeep;
        last = this.axis_if.tlast;
        id = this.axis_if.tid;
        dest = this.axis_if.tdest;
        user = this.axis_if.tuser;
        wakeup = this.axis_if.twakeup;

        this.axis_if.tready = 1'b0;
    endtask

    task automatic simple_transfer(
        ref var logic clk,
        output var logic [data_width-1:0] data
    );
        var logic [strobe_width-1:0] strobe;
        var logic [keep_width-1:0] keep;
        var logic last;
        var logic [id_width-1:0] id;
        var logic [dest_width-1:0] dest;
        var logic [user_width-1:0] user;
        var logic wakeup;

        transfer(
            .clk(clk),
            .data(data),
            .strobe(strobe),
            .keep(keep),
            .last(last),
            .id(id),
            .dest(dest),
            .user(user),
            .wakeup(wakeup)
        );
    endtask
endclass

class AXIS_Master_BFM # (
    parameter int data_width    = 8,
    parameter int id_width      = 0,
    parameter int dest_width    = 0,
    parameter int user_width    = 0,
    parameter bit keep_enable   = 1'b0,
    parameter bit wakeup_enable = 1'b0
);
    localparam int strobe_width = data_width / 8;
    localparam int keep_width   = data_width / 8;
    
    typedef virtual AXIS_IF # (
        .TDATA_WIDTH(data_width),
        .TID_WIDTH(id_width),
        .TDEST_WIDTH(dest_width),
        .TUSER_WIDTH(user_width),
        .TKEEP_ENABLE(keep_enable),
        .TWAKEUP_ENABLE(wakeup_enable)
    ) v_axis_if_t;

    v_axis_if_t axis_if;

    function new(v_axis_if_t axis_if_in);
        this.axis_if = axis_if_in;
    endfunction

    task automatic reset_task();
        this.axis_if.tvalid = '0;

        this.axis_if.tdata = '0;
        this.axis_if.tstrb = '0;
        this.axis_if.tkeep = '0;
        this.axis_if.tlast = '0;
        this.axis_if.tid = '0;
        this.axis_if.tdest = '0;
        this.axis_if.tuser = '0;
        this.axis_if.twakeup = '0;
    endtask

    task automatic transfer(
        ref var logic clk,
        input var logic [data_width-1:0] data = '0,
        input var logic [strobe_width-1:0] strobe = '0,
        input var logic [keep_width-1:0] keep = '0,
        input var logic last = '0,
        input var logic [id_width-1:0] id = '0,
        input var logic [dest_width-1:0] dest = '0,
        input var logic [user_width-1:0] user = '0,
        input var logic wakeup = '0
    );
        this.axis_if.tdata = data;
        this.axis_if.tstrb = strobe;
        this.axis_if.tkeep = keep;
        this.axis_if.tlast = last;
        this.axis_if.tid = id;
        this.axis_if.tdest = dest;
        this.axis_if.tuser = user;
        this.axis_if.twakeup = wakeup;

        this.axis_if.tvalid = 1'b1;

        do begin
            @ (posedge clk);
        end while (this.axis_if.tready === 1'b0);

        this.axis_if.tvalid = 1'b0;

        this.axis_if.tdata = '0;
        this.axis_if.tstrb = '0;
        this.axis_if.tkeep = '0;
        this.axis_if.tlast = 1'b0;
        this.axis_if.tid = '0;
        this.axis_if.tdest = '0;
        this.axis_if.tuser = '0;
        this.axis_if.twakeup = 1'b0;
    endtask

    task automatic simple_transfer(
        ref var logic clk,
        input var logic [data_width-1:0] data
    );
        var logic [strobe_width-1:0] strobe = ~ '0;
        var logic [keep_width-1:0] keep = ~ '0;
        var logic last = '0;
        var logic [id_width-1:0] id = '0;
        var logic [dest_width-1:0] dest = '0;
        var logic [user_width-1:0] user = '0;
        var logic wakeup = '0;

        transfer(
            .clk(clk),
            .data(data),
            .strobe(strobe),
            .keep(keep),
            .last(last),
            .id(id),
            .dest(dest),
            .user(user),
            .wakeup(wakeup)
        );
    endtask
endclass
endpackage

`default_nettype wire