`timescale 1ns/1ps

module tb_fft_8pt();

//signals 
reg clk;
reg signed [127:0] x_re_in, x_im_in;
wire signed [127:0] X_re_out, X_im_out;

fft_8pt_top uut (
    .clk(clk),
    .x_re_in (x_re_in),
    .x_im_in(x_im_in),
    .X_re_out(X_re_out),
    .X_im_out(X_im_out)
);

//clock
initial begin
    clk=0;
    forever #5 clk=~clk;
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_fft_8pt);
end

initial begin

    x_re_in = 128'd0;
    x_im_in = 128'd0;

    #100;

    x_re_in[15:0] = 16'd16384;

    //each stage latency is 3 clock cycles,
    // so for 3 stages, we need to wait for 9 clock cycles before the output is valid
    #100;
    
    #50;
    $finish;
end

endmodule
