module radix2_butterfly_pipelined #(
    parameter WIDTH = 16,
    parameter FRAC_BITS = 14
)(
    input clk,  // <-- Added clock
    
    input  signed [WIDTH-1:0] A_re, A_im,
    input  signed [WIDTH-1:0] B_re, B_im,
    input  signed [WIDTH-1:0] W_re, W_im,
    
    // Outputs are now registers
    output reg signed [WIDTH-1:0] X_re, X_im,
    output reg signed [WIDTH-1:0] Y_re, Y_im
);

    // --- PIPELINE STAGE 1: Multiplication ---
    reg signed [2*WIDTH-1:0] mult_rr, mult_ii, mult_ri, mult_ir;
    
    // Delay registers for A (Stage 1)
    reg signed [WIDTH-1:0] A_re_d1, A_im_d1;

    always @(posedge clk) begin
        // Multipliers map perfectly to Zynq DSP48 slices here
        mult_rr <= B_re * W_re;
        mult_ii <= B_im * W_im;
        mult_ri <= B_re * W_im;
        mult_ir <= B_im * W_re;
        
        // Push A into the delay line
        A_re_d1 <= A_re;
        A_im_d1 <= A_im;
    end

    // --- PIPELINE STAGE 2: Complex Addition (B * W) ---
    reg signed [2*WIDTH-1:0] BW_re_full, BW_im_full;
    
    // Delay registers for A (Stage 2)
    reg signed [WIDTH-1:0] A_re_d2, A_im_d2;

    always @(posedge clk) begin
        BW_re_full <= mult_rr - mult_ii;
        BW_im_full <= mult_ri + mult_ir;
        
        // Push A further down the delay line
        A_re_d2 <= A_re_d1;
        A_im_d2 <= A_im_d1;
    end

    // --- PIPELINE STAGE 3: Truncation & Final Butterfly ---
    // Truncate back to original fixed-point width
    wire signed [WIDTH-1:0] BW_re_trunc = BW_re_full[WIDTH+FRAC_BITS-1 : FRAC_BITS];
    wire signed [WIDTH-1:0] BW_im_trunc = BW_im_full[WIDTH+FRAC_BITS-1 : FRAC_BITS];

    always @(posedge clk) begin
        // A_d2 and BW_trunc now arrive at this adder on the exact same clock cycle
        X_re <= A_re_d2 + BW_re_trunc;
        X_im <= A_im_d2 + BW_im_trunc;
        
        Y_re <= A_re_d2 - BW_re_trunc;
        Y_im <= A_im_d2 - BW_im_trunc;
    end

endmodule
