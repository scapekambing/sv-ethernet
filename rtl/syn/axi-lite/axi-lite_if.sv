/**
 * @file axi-lite_if.sv
 *
 * @author Mani Magnusson
 * @date   2023
 *
 * @brief AXI4-Lite Interface Definition, uses a 32 bit bus
 */

 /* 
 * TODO:
 *  - Add parameterization
*/

`default_nettype none

interface AXIL_IF # ();
    // Signals
    
    // Write address channel
    var logic        awvalid; // Single bit
    var logic        awready; // Single bit
    var logic [31:0] awaddr;  // 32 bit addresses
    var logic  [2:0] awprot;  // 3 bit access protection

    // Write data channel
    var logic        wvalid; // Single bit
    var logic        wready; // Single bit
    var logic [31:0] wdata; // 32 bit data bus
    var logic  [3:0] wstrb; // 32/8 bit strobe bus

    // Write response channel
    var logic        bvalid; // Single bit
    var logic        bready; // Single bit
    var logic  [1:0] bresp; // Response lines

    // Read address channel signals
    var logic        arvalid; // Single bit
    var logic        arready; // Single bit
    var logic [31:0] araddr;  // 31 bit addresses
    var logic [2:0]  arprot;  // 3 bit access protection

    // Read data channel
    var logic        rvalid; // Single bit
    var logic        rready; // Single bit
    var logic [31:0] rdata; // 32 bit data bus
    var logic  [1:0] rresp; // Response lines
    
    enum logic [1:0] {
        AXI_RESP_OKAY,
        AXI_RESP_EXOKAY,
        AXI_RESP_SLVERR,
        AXI_RESP_DECERR
    } axi_resp_t;
    
    enum logic [2:0] {
        AXI_PROT_UNPRIVILEGED_SECURE_DATA,
        AXI_PROT_PRIVILEGED_SECURE_DATA,
        AXI_PROT_UNPRIVILEGED_NONSECURE_DATA,
        AXI_PROT_PRIVILEGED_NONSECURE_DATA,
        AXI_PROT_UNPRIVILEGED_SECURE_INSTRUCTION,
        AXI_PROT_PRIVILEGED_SECURE_INSTRUCTION,
        AXI_PROT_UNPRIVILEGED_NONSECURE_INSTRUCTION,
        AXI_PROT_PRIVILEGED_NONSECURE_INSTRUCTION
    } axi_prot_t;

    // Modports

    modport Master (
        output awvalid,
        output awaddr,
        output awprot,
        input awready,

        output wvalid,
        output wdata,
        output wstrb,
        input wready,

        output bready,
        input bvalid,
        input bresp,

        output arvalid,
        output araddr,
        output arprot,
        input arready,

        output rready,
        input rvalid,
        input rdata,
        input rresp
    );

    modport Slave (
        output awready,
        input awvalid,
        input awaddr,
        input awprot,
        
        output wready,
        input wvalid,
        input wdata,
        input wstrb,

        output bvalid,
        output bresp,
        input bready,

        output arready,
        input arvalid,
        input araddr,
        input arprot,

        output rvalid,
        output rdata,
        output rresp,
        input rready
    );

    modport Monitor (
        input awvalid,
        input awready,
        input awaddr,
        input awprot,
        
        input wvalid,
        input wready,
        input wdata,
        input wstrb,

        input bvalid,
        input bready,
        input bresp,

        input arvalid,
        input arready,
        input araddr,
        input arprot,

        input rvalid,
        input rready,
        input rdata,
        input rresp
    );
endinterface

`default_nettype wire