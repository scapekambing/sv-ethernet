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
    // Parameters
) (
    input var logic clk,
    input var logic reset,

    UDP_OUTPUT_HEADER_IF.Input udp_header_input_if,
    AXIS_IF.Receiver udp_payload_input_if,

    UDP_INPUT_HEADER_IF.Output udp_header_output_if,
    AXIS_IF.Transmitter udp_payload_output_if,

    AXIL_IF.Master axil_if
);
    /* Process requests */

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

    // Next logic
    always_comb begin
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