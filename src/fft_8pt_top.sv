`timescale 1ns/1ps

module fft_8pt_top(
    input clk,
    input wire signed [127:0] x_re_in, x_im_in,
    output wire signed [127:0] X_re_out, X_im_out
);

//twiddle factors for 8-point FFT
localparam signed [15:0] W0_re = 16'd16384 , W0_im = 16'd0;
localparam signed [15:0] W1_re= 16'd11585 , W1_im= -16'd11585;
localparam signed [15:0] W2_re=16'd0 , W2_im= -16'd16384;
localparam signed [15:0] W3_re = -16'd11585 , W3_im= -16'd11585;

//intenal signals 
//unpacked inputs
wire signed [15:0] x_re [0:7];
wire signed [15:0] x_im [0:7];

//stage 1 to stage 2 wires
wire signed [15:0] s1_re [0:7];
wire signed [15:0] s1_im [0:7];

//stage 2 to stage 3 wires
wire signed [15:0] s2_re [0:7];
wire signed [15:0] s2_im [0:7];

//final stage 
wire signed [15:0] X_re [0:7];
wire signed [15:0] X_im [0:7];

//unpacking inputs
genvar i;
generate 
    for (i=0;i<8;i=i+1) begin : unpack
    assign x_re[i] = x_re_in[(i*16)+:16];
    assign x_im[i] = x_im_in[(i*16)+:16];

    assign X_re_out[(i*16)+:16] = X_re[i];
    assign X_im_out[(i*16)+:16] = X_im[i];
    end 
endgenerate


//stage 1 butterflies 

radix2_butterfly_pipelined bfly1_0 (
    .clk(clk),
    .A_re(x_re[0]), .A_im(x_im[0]), .B_re(x_re[4]), .B_im(x_im[4]),
    .W_re(W0_re), .W_im(W0_im),
    .X_re(s1_re[0]), .X_im(s1_im[0]), .Y_re(s1_re[1]), .Y_im(s1_im[1])
);

radix2_butterfly_pipelined bfly1_1 (
    .clk(clk),
    .A_re(x_re[2]), .A_im(x_im[2]), .B_re(x_re[6]), .B_im(x_im[6]),
    .W_re(W0_re), .W_im(W0_im),
    .X_re(s1_re[2]), .X_im(s1_im[2]), .Y_re(s1_re[3]), .Y_im(s1_im[3])
);

radix2_butterfly_pipelined bfly1_2 (
    .clk(clk),
    .A_re(x_re[1]), .A_im(x_im[1]), .B_re(x_re[5]), .B_im(x_im[5]),
    .W_re(W0_re), .W_im(W0_im),
    .X_re(s1_re[4]), .X_im(s1_im[4]), .Y_re(s1_re[5]), .Y_im(s1_im[5])
);

radix2_butterfly_pipelined bfly1_3 (
    .clk(clk),
    .A_re(x_re[3]), .A_im(x_im[3]), .B_re(x_re[7]), .B_im(x_im[7]),
    .W_re(W0_re), .W_im(W0_im),
    .X_re(s1_re[6]), .X_im(s1_im[6]), .Y_re(s1_re[7]), .Y_im(s1_im[7])
);


//stage 2 butterflies

radix2_butterfly_pipelined bfly2_0 (
    .clk(clk),
    .A_re(s1_re[0]), .A_im(s1_im[0]), .B_re(s1_re[2]), .B_im(s1_im[2]),
    .W_re(W0_re), .W_im(W0_im),
    .X_re(s2_re[0]), .X_im(s2_im[0]), .Y_re(s2_re[2]), .Y_im(s2_im[2])
);

radix2_butterfly_pipelined bfly2_1 (
    .clk(clk),
    .A_re(s1_re[1]), .A_im(s1_im[1]), .B_re(s1_re[3]), .B_im(s1_im[3]),
    .W_re(W2_re), .W_im(W2_im),
    .X_re(s2_re[1]), .X_im(s2_im[1]), .Y_re(s2_re[3]), .Y_im(s2_im[3])
);

radix2_butterfly_pipelined bfly2_2 (
    .clk(clk),
    .A_re(s1_re[4]), .A_im(s1_im[4]), .B_re(s1_re[6]), .B_im(s1_im[6]),
    .W_re(W0_re), .W_im(W0_im),
    .X_re(s2_re[4]), .X_im(s2_im[4]), .Y_re(s2_re[6]), .Y_im(s2_im[6])
);

radix2_butterfly_pipelined bfly2_3 (
    .clk(clk),
    .A_re(s1_re[5]), .A_im(s1_im[5]), .B_re(s1_re[7]), .B_im(s1_im[7]),
    .W_re(W2_re), .W_im(W2_im),
    .X_re(s2_re[5]), .X_im(s2_im[5]), .Y_re(s2_re[7]), .Y_im(s2_im[7])
);

//stage 3 butterflies

radix2_butterfly_pipelined bfly3_0 (
    .clk(clk),
    .A_re(s2_re[0]), .A_im(s2_im[0]), .B_re(s2_re[4]), .B_im(s2_im[4]),
    .W_re(W0_re), .W_im(W0_im),
    .X_re(X_re[0]), .X_im(X_im[0]), .Y_re(X_re[4]), .Y_im(X_im[4])
);

radix2_butterfly_pipelined bfly3_1 (
    .clk(clk),
    .A_re(s2_re[1]), .A_im(s2_im[1]), .B_re(s2_re[5]), .B_im(s2_im[5]),
    .W_re(W1_re), .W_im(W1_im),
    .X_re(X_re[1]), .X_im(X_im[1]), .Y_re(X_re[5]), .Y_im(X_im[5])
);

radix2_butterfly_pipelined bfly3_2 (
    .clk(clk),
    .A_re(s2_re[2]), .A_im(s2_im[2]), .B_re(s2_re[6]), .B_im(s2_im[6]),
    .W_re(W2_re), .W_im(W2_im),
    .X_re(X_re[2]), .X_im(X_im[2]), .Y_re(X_re[6]), .Y_im(X_im[6])
);

radix2_butterfly_pipelined bfly3_3 (
    .clk(clk),
    .A_re(s2_re[3]), .A_im(s2_im[3]), .B_re(s2_re[7]), .B_im(s2_im[7]),
    .W_re(W3_re), .W_im(W3_im),
    .X_re(X_re[3]), .X_im(X_im[3]), .Y_re(X_re[7]), .Y_im(X_im[7])
);

endmodule
