`timescale 1ns / 1ps

module fft_axi_wrapper (
    input wire clk,
    input wire resetn, 

    // AXI4-Stream SLAVE INTERFACE (Receiving from Processor)
    input  wire [31:0] s_axis_tdata,  
    input  wire        s_axis_tvalid, 
    output reg         s_axis_tready, 
    input  wire        s_axis_tlast,  

    // AXI4-Stream MASTER INTERFACE (Sending to Processor)
    output reg  [31:0] m_axis_tdata,  
    output reg         m_axis_tvalid, 
    input  wire        m_axis_tready, 
    output reg         m_axis_tlast   
);

    localparam IDLE         = 2'd0;
    localparam COLLECTING   = 2'd1;
    localparam COMPUTING    = 2'd2;
    localparam TRANSMITTING = 2'd3;

    reg [1:0] current_state;

    reg [127:0] x_re_buffer;
    reg [127:0] x_im_buffer;
    
    reg [2:0] input_counter;  
    reg [3:0] wait_counter;   
    reg [2:0] output_counter; 

    wire [127:0] X_re_out;
    wire [127:0] X_im_out;

    fft_8pt_top my_fft (
        .clk(clk),
        .x_re_in(x_re_buffer), 
        .x_im_in(x_im_buffer),
        .X_re_out(X_re_out),
        .X_im_out(X_im_out)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            current_state  <= IDLE;
            input_counter  <= 3'd0;
            wait_counter   <= 4'd0;
            output_counter <= 3'd0;
            
            s_axis_tready  <= 1'b0;
            m_axis_tvalid  <= 1'b0;
            m_axis_tlast   <= 1'b0;
            m_axis_tdata   <= 32'd0;
            
            x_re_buffer    <= 128'd0;
            x_im_buffer    <= 128'd0;
        end 
        else begin
            case (current_state)
                
                IDLE: begin
                    s_axis_tready <= 1'b1; 
                    m_axis_tlast  <= 1'b0; // FIXED: Ensures tlast is reset when idle
                    
                    if (s_axis_tvalid && s_axis_tready) begin
                        x_re_buffer[15:0]  <= s_axis_tdata[15:0];
                        x_im_buffer[15:0]  <= s_axis_tdata[31:16];
                        
                        input_counter <= 3'd1;
                        current_state <= COLLECTING;
                    end
                end

                COLLECTING: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        x_re_buffer[(input_counter * 16) +: 16] <= s_axis_tdata[15:0];
                        x_im_buffer[(input_counter * 16) +: 16] <= s_axis_tdata[31:16];
                        
                        if (input_counter == 3'd7) begin
                            s_axis_tready <= 1'b0; 
                            input_counter <= 3'd0; 
                            current_state <= COMPUTING;
                        end else begin
                            input_counter <= input_counter + 1;
                        end
                    end
                end

                COMPUTING: begin
                    if (wait_counter == 4'd9) begin
                        wait_counter  <= 4'd0;
                        current_state <= TRANSMITTING;
                    end else begin
                        wait_counter <= wait_counter + 1;
                    end
                end

                TRANSMITTING: begin
                    m_axis_tdata[15:0]  <= X_re_out[(output_counter * 16) +: 16];
                    m_axis_tdata[31:16] <= X_im_out[(output_counter * 16) +: 16];
                    
                    m_axis_tvalid <= 1'b1; 
                    
                    // FIXED: This is the ONLY place m_axis_tlast is assigned in this state
                    if (output_counter == 3'd7) begin
                        m_axis_tlast <= 1'b1;
                    end else begin
                        m_axis_tlast <= 1'b0;
                    end

                    if (m_axis_tvalid && m_axis_tready) begin
                        if (output_counter == 3'd7) begin
                            m_axis_tvalid  <= 1'b0;
                            // FIXED: Removed the duplicate m_axis_tlast <= 0 assignment from here
                            output_counter <= 3'd0;
                            current_state  <= IDLE; 
                        end else begin
                            output_counter <= output_counter + 1;
                        end
                    end
                end

                default: current_state <= IDLE;
            endcase
        end
    end

endmodule
