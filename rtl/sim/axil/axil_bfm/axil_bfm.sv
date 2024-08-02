/**
 * @file axil_bfm.sv
 *
 * @author Mani Magnusson
 * @date   2023
 *
 * @brief AXI4-Lite bus functional model
 */

/* TODO:
 *  - Check if awaddr, wdata, araddr and rdata widths have to be multiples of 8
 *    I assume they are, in which case add a check to make sure they are and throw an assertion error if not
 *  - Option to have READY deassert before VALID is asserted (allowed in spec)
*/

`timescale 1ns / 1ps
`default_nettype none

package axil_bfm;
class AXIL_Slave_BFM # (
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
);
    localparam int STRB_WIDTH = DATA_WIDTH / 8;

    typedef virtual AXIL_IF # (
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) v_axil_if_t;

    v_axil_if_t axil_if;

    int rand_wait_max = 10; // clock cycles
    bit use_random_wait = 0;

    function new(v_axil_if_t axil_if_in, input bit use_random_wait_in);
        axil_if = axil_if_in;
        use_random_wait = use_random_wait_in;
    endfunction

    // Set all slave outputs to zero
    task automatic reset_task();
        this.axil_if.awready = '0;
        this.axil_if.wready = '0;
        this.axil_if.bresp = '0;
        this.axil_if.bvalid = '0;
        this.axil_if.arready = '0;
        this.axil_if.rdata = '0;
        this.axil_if.rresp = '0;
        this.axil_if.rvalid = '0;
    endtask

    task automatic awtransfer(
        ref var logic clk,
        output var logic [ADDR_WIDTH-1:0] address,
        output var logic [2:0] awprot
    );
        if(use_random_wait) begin
            int random_wait = $urandom_range(0,rand_wait_max);
            $display("[AXIL BFM Slave] awtransfer waiting %0d ns", random_wait);
            repeat(random_wait) begin
                @(posedge clk);
            end
        end

        this.axil_if.awready = 1'b1;

        do begin
            @(posedge clk);
        end while (this.axil_if.awvalid === 1'b0);
        
        address = this.axil_if.awaddr;
        awprot = this.axil_if.awprot;

        this.axil_if.awready = 1'b0;
    endtask

    task automatic wtransfer(
        ref var logic clk,
        output var logic [DATA_WIDTH-1:0] data,
        output var logic [STRB_WIDTH-1:0] strobe
    );
        if(use_random_wait) begin
            int random_wait = $urandom_range(0,rand_wait_max);
            $display("[AXIL BFM Slave] wtransfer waiting %0d ns", random_wait);
            repeat(random_wait) begin
                @(posedge clk);
            end
        end

        this.axil_if.wready = 1'b1;

        do begin
            @(posedge clk);
        end while (this.axil_if.wvalid  === 1'b0);
        
        data = this.axil_if.wdata;
        strobe = this.axil_if.wstrb;
        this.axil_if.wready = 1'b0;
    endtask

    task automatic btransfer(
        ref var logic clk,
        input var logic [1:0] bresp = this.axil_if.AXI_RESP_OKAY
    );  
        if(use_random_wait) begin
            int random_wait = $urandom_range(0,rand_wait_max);
            $display("[AXIL BFM Slave] btransfer waiting %0d ns", random_wait);
            repeat(random_wait) begin
                @(posedge clk);
            end
        end
        
        this.axil_if.bresp = bresp;
        this.axil_if.bvalid = 1'b1;

        do begin
            @(posedge clk);
        end while (this.axil_if.bready  === 1'b0);
        
        this.axil_if.bvalid = 1'b0;
    endtask

    task automatic artransfer(
        ref var logic clk,
        output var logic [ADDR_WIDTH-1:0] address,
        output var logic [2:0] arprot
    );
        if(use_random_wait) begin
            int random_wait = $urandom_range(0,rand_wait_max);
            $display("[AXIL BFM Slave] artransfer waiting %0d ns", random_wait);
            repeat(random_wait) begin
                @(posedge clk);
            end
        end

        this.axil_if.arready = 1'b1;

        do begin
            @(posedge clk);
        end while (this.axil_if.arvalid === 1'b0);
        
        address = this.axil_if.araddr;
        arprot = this.axil_if.arprot;
        this.axil_if.arready = 1'b0;
    endtask

    task automatic rtransfer(
        ref var logic clk,
        input var logic [DATA_WIDTH-1:0] data,
        input var logic [1:0] rresp = this.axil_if.AXI_RESP_OKAY
    );
        if(use_random_wait) begin
            int random_wait = $urandom_range(0,rand_wait_max);
            $display("[AXIL BFM Slave] rtransfer waiting %0d ns", random_wait);
            repeat(random_wait) begin
                @(posedge clk);
            end
        end
        this.axil_if.rdata = data;
        this.axil_if.rresp = rresp;

        this.axil_if.rvalid = 1'b1;

        do begin
            @(posedge clk);
        end while (this.axil_if.rready === 1'b0);
        
        this.axil_if.rvalid = 1'b0;
    endtask

    // Write transaction (slave receives an address and data)
    task automatic write(
        ref var logic clk,
        output var logic [ADDR_WIDTH-1:0] address,
        output var logic [DATA_WIDTH-1:0] data,
        output var logic [STRB_WIDTH-1:0] strobe,
        output var logic [2:0] awprot,
        input var logic [1:0] bresp = this.axil_if.AXI_RESP_OKAY
    );

        // Fork join because W channel could arrive before AW channel, or they could come simultaneously
        fork
            // Do an AW transfer
            begin
                awtransfer(clk, address, awprot);
            end

            // Do a W transfer
            begin
                wtransfer(clk, data, strobe);
            end
        join

        // Respond on the B channel
        btransfer(clk, bresp);
    endtask
endclass

class AXIL_Master_BFM # (
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
);
    localparam int STRB_WIDTH = DATA_WIDTH / 8;

    typedef virtual AXIL_IF # (
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) v_axil_if_t;

    v_axil_if_t axil_if;

    int rand_wait_max = 10; //ns
    bit use_random_wait = 0;

    function new(v_axil_if_t axil_if_in, input bit use_random_wait_in);
        axil_if = axil_if_in;
        use_random_wait = use_random_wait_in;
    endfunction

    task automatic reset_task();
        this.axil_if.awvalid = '0;
        this.axil_if.awaddr = '0;
        this.axil_if.awprot = '0;

        this.axil_if.wvalid = '0;
        this.axil_if.wdata = '0;
        this.axil_if.wstrb = '0;
        
        this.axil_if.bready = '0;
        
        this.axil_if.arvalid = '0;
        this.axil_if.araddr = '0;
        this.axil_if.arprot = '0;

        this.axil_if.rready = '0;
    endtask

    task automatic awtransfer(
        ref var logic clk,
        input var logic [ADDR_WIDTH-1:0] address = '0,
        input var logic [2:0] awprot = this.axil_if.AXI_PROT_UNPRIVILEGED_NONSECURE_DATA
    );
        if(use_random_wait) begin
            int random_wait = $urandom_range(0,rand_wait_max);
            $display("[AXIL BFM Master] awtransfer waiting %0d ns", random_wait);
            repeat(random_wait) begin
                @(posedge clk);
            end
        end
        this.axil_if.awaddr = address;
        this.axil_if.awprot = awprot;

        this.axil_if.awvalid = 1'b1;

        do begin
            @(posedge clk);
        end while (this.axil_if.awready === 1'b0);
        
        this.axil_if.awvalid = 1'b0;

        this.axil_if.awaddr = '0;
        this.axil_if.awprot = '0;
    endtask

    task automatic wtransfer(
        ref var logic clk,
        input var logic [DATA_WIDTH-1:0] data = '0,
        input var logic [STRB_WIDTH-1:0] strobe = '1
    );
        if(use_random_wait) begin
            int random_wait = $urandom_range(0,rand_wait_max);
            $display("[AXIL BFM Master] wtransfer waiting %0d ns", random_wait);
            repeat(random_wait) begin
                @(posedge clk);
            end
        end
        this.axil_if.wdata = data;
        this.axil_if.wstrb = strobe;

        this.axil_if.wvalid = 1'b1;

        do begin
            @(posedge clk);
        end while (this.axil_if.wready  === 1'b0);
        
        this.axil_if.wvalid = 1'b0;

        this.axil_if.wdata = '0;
        this.axil_if.wstrb = '0;
    endtask

    task automatic btransfer(
        ref var logic clk,
        output var logic [1:0] bresp
    );
        if(use_random_wait) begin
            int random_wait = $urandom_range(0,rand_wait_max);
            $display("[AXIL BFM Master] btransfer waiting %0d ns", random_wait);
            repeat(random_wait) begin
                @(posedge clk);
            end
        end

        this.axil_if.bready = 1'b1;

        do begin
            @(posedge clk);
        end while (this.axil_if.bvalid  === 1'b0);
        
        bresp = this.axil_if.bresp;

        this.axil_if.bready = 1'b0;
    endtask

    task automatic artransfer(
        ref var logic clk,
        input var logic [ADDR_WIDTH-1:0] address = '0,
        input var logic [2:0] arprot = this.axil_if.AXI_PROT_UNPRIVILEGED_NONSECURE_DATA
    );
        if(use_random_wait) begin
            int random_wait = $urandom_range(0,rand_wait_max);
            $display("[AXIL BFM Master] artransfer waiting %0d ns", random_wait);
            repeat(random_wait) begin
                @(posedge clk);
            end
        end

        this.axil_if.araddr = address;
        this.axil_if.arprot = arprot;

        this.axil_if.arvalid = 1'b1;

        do begin
            @(posedge clk);
        end while (this.axil_if.arready === 1'b0);
        
        this.axil_if.arvalid = 1'b0;

        this.axil_if.araddr = '0;
        this.axil_if.arprot = '0;
    endtask

    task automatic rtransfer(
        ref var logic clk,
        output var logic [DATA_WIDTH-1:0] data,
        output var logic [1:0] rresp
    );
        if(use_random_wait) begin
            int random_wait = $urandom_range(0,rand_wait_max);
            $display("[AXIL BFM Master] rtransfer waiting %0d ns", random_wait);
            repeat(random_wait) begin
                @(posedge clk);
            end
        end
        this.axil_if.rready = 1'b1;

        do begin
            @(posedge clk);
        end while (this.axil_if.rvalid === 1'b0);

        data = this.axil_if.rdata;
        rresp = this.axil_if.rresp;
        
        this.axil_if.rready = 1'b0;
    endtask

    task automatic write(
        ref var logic clk,
        input var logic [ADDR_WIDTH-1:0] address = '0,
        input var logic [2:0] prot = this.axil_if.AXI_PROT_UNPRIVILEGED_NONSECURE_DATA,
        input var logic [DATA_WIDTH-1:0] data = '0,
        input var logic [STRB_WIDTH-1:0] strobe = '1,
        input bit simultaneous = 0,
        output var logic [1:0] response
    );
        if (simultaneous) begin
            fork
                begin
                    awtransfer(clk, address, prot);
                end

                begin
                    wtransfer(clk, data, strobe);
                end
            join
        end else begin
            awtransfer(clk, address, prot);
            wtransfer(clk, data, strobe);
        end
        
        // B transfer always comes last after AW and W transfers
        btransfer(clk, response);
    endtask

    task automatic simple_write(
        ref var logic clk,
        input var logic [ADDR_WIDTH-1:0] address = '0,
        input var logic [DATA_WIDTH-1:0] data = '0
    );
        logic [1:0] response;
        write(clk, address, this.axil_if.AXI_PROT_UNPRIVILEGED_NONSECURE_DATA, data, '1, 1, response);
    endtask

    task automatic read(
        ref var logic clk,
        input var logic [ADDR_WIDTH-1:0] address = '0,
        input var logic [2:0] prot = this.axil_if.AXI_PROT_UNPRIVILEGED_NONSECURE_DATA,
        output var logic [DATA_WIDTH-1:0] data,
        output var logic [1:0] response
    );
        artransfer(clk, address, prot);
        rtransfer(clk, data, response);
    endtask

    task automatic simple_read(
        ref var logic clk,
        input var logic [ADDR_WIDTH-1:0] address = '0,
        output var logic [DATA_WIDTH-1:0] data
    );
        logic [1:0] response;
        read(clk, address, this.axil_if.AXI_PROT_UNPRIVILEGED_NONSECURE_DATA, data, response);
    endtask
endclass
endpackage

`default_nettype wire