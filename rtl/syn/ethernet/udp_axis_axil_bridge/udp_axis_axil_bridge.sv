/**
 * @file udp_axis_axil_bridge.sv
 *
 * @author Mani Magnusson
 * @date   2024
 *
 * @brief UDP AXI-Stream to AXI-Lite bridge
*/

/* TODO:
 *  - Figure out the state machine for creating AXI-Lite transfers
 *  - Figure out how to actually create a state machine for AXI-Lite transfers
*/

`default_nettype none

module udp_axis_axil_bridge # (
    parameter int REQUEST_BUFFER_SIZE = 64,
    parameter int UDP_PORT = 1234
) (
    input var logic clk,
    input var logic reset,

    UDP_INPUT_HEADER_IF.Input udp_header_output_if,
    AXIS_IF.Receiver udp_payload_output_if,

    UDP_OUTPUT_HEADER_IF.Output udp_header_input_if,
    AXIS_IF.Transmitter udp_payload_input_if,

    AXIL_IF.Master axil_if
);
    /*
        Get a header valid
        Read header params and set header ready
        Read stream data into buffer
        Parse each request and issue AXI-L transfers
        Fill the same buffer from earlier with results from transfers
        If transfer successful, set bit 63 to 1, otherwise keep it at 0
        At end of AXI-L transfers send the buffer back to the UDP module
    */

    typedef enum logic [1:0] { 
        WRITE_DATA=0,
        READ_DATA=1,
        WRITE_OK=2,
        READ_OK=3
    } opcode_t;

    typedef struct packed {
        opcode_t opcode;
        var logic [29:0] address;
        var logic [31:0] data;
    } request_t;

    request_t [REQUEST_BUFFER_SIZE-1:0] requests;

    var logic port_match = udp_output_header_if.dest_port == UDP_PORT;

    always_ff @ (posedge clk) begin
        if (reset) begin
            // Reset signals
        end else begin
            // States? 
        end
    end

    /* TODO:
        Find a better name than just state_t for the high level SM states

    */

    typedef enum logic [2:0] {
        STATE_IDLE,
        STATE_HEADER_READ,
        STATE_STREAM_READ,
        STATE_ISSUE_TRANSFERS,
        STATE_HEADER_WRITE,
        STATE_STREAM_WRITE
    } state_t;

    state_t state, next_state;

    always_ff @ (posedge clk or posedge reset)
        if (reset)  state <= STATE_IDLE;
        else        state <= next_state;
    
    always_comb begin
        next_state = STATE_IDLE;
        case (state)
            STATE_IDLE              : if ()     next_state = 
                                      else      next_state = 
            STATE_HEADER_READ       : if ()     next_state = 
                                      else      next_state = 
            STATE_STREAM_READ       : if ()     next_state = 
                                      else      next_state = 
            STATE_ISSUE_TRANSFERS   : if ()     next_state = 
                                      else      next_state = 
            STATE_HEADER_WRITE      : if ()     next_state = 
                                      else      next_state = 
            STATE_STREAM_WRITE      : if ()     next_state = 
                                      else      next_state = 
        endcase
    end




    /* OLDER CODE */
    /* Process requests */

    var logic header_incoming, header_ok;

    assign header_incoming = udp_header_output_if.hdr_valid;
    assign header_ok = udp_header_output_if.hdr_ready && udp_header_output_if.length % 64 == 0; // Need to add check that packet length is n*64

    typedef enum logic [1:0] {
        REQUEST_STATE_IDLE,
        REQUEST_STATE_PROCESS_HEADER,
        REQUEST_STATE_PROCESS_REQUEST
    } request_state_t;

    request_state_t request_state, request_next_state;

    // Clock in next state
    always_ff @(posedge clk or posedge reset)
        if (reset)  request_state <= REQUEST_STATE_IDLE;
        else        request_state <= request_next_state;

    // Next state logic
    always_comb begin
        request_next_state = REQUEST_STATE_IDLE;
        case (request_state)
            REQUEST_STATE_IDLE              : if (header_incoming)  request_next_state = REQUEST_STATE_PROCESS_HEADER;
                                              else                  request_next_state = REQUEST_STATE_IDLE;
            REQUEST_STATE_PROCESS_HEADER    : if (header_ok)        request_next_state = REQUEST_STATE_PROCESS_REQUEST;
                                              else                  request_next_state = REQUEST_STATE_IDLE;
            REQUEST_STATE_PROCESS_REQUEST   : if ()
        endcase
    end

    // Next output logic
    always_comb begin
    end

    // Output registers
    always_ff @(posedge clk or posedge reset)
        if (reset) begin
        else begin
        end
    

endmodule

`default_nettype wire