`timescale 1ns / 1ps

module fft_tb();

    // --- 1. System Signals ---
    reg clk;
    reg resetn;
    
    // --- 2. AXI Slave Interface (Testbench -> FFT) ---
    reg [31:0] s_axis_tdata;
    reg s_axis_tvalid;
    reg s_axis_tlast;
    wire s_axis_tready;
    
    // --- 3. AXI Master Interface (FFT -> Testbench) ---
    // These wires let us watch the math come out!
    wire [31:0] m_axis_tdata;
    wire m_axis_tvalid;
    wire m_axis_tlast;
    reg  m_axis_tready;  // <-- THE CRITICAL FIX: The receiver is ready

    // --- 4. Instantiate the FFT AXI Wrapper ---
    fft_axi_wrapper uut (
        .clk(clk),
        .resetn(resetn),
        
        // Input ports
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        
        // Output ports
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    // --- 5. Clock Generation (100 MHz) ---
    always #5 clk = ~clk; 

    // --- 6. Main Test Sequence ---
    integer i;
    
    initial begin
        // Initialize system
        clk = 0;
        resetn = 0; 
        
        // Initialize inputs to FFT
        s_axis_tdata = 32'd0;
        s_axis_tvalid = 1'b0;
        s_axis_tlast = 1'b0;
        
        // IMPORTANT: Tell the FFT we are always ready to receive its output!
        m_axis_tready = 1'b1; 
        
        // Apply Reset
        #100;
        resetn = 1;
        #20; 
        
        // --- STREAMING IN THE DATA ---
        for (i = 0; i < 8; i = i + 1) begin
            s_axis_tvalid = 1'b1;         
            s_axis_tdata = i * 10;        // Send: 0, 10, 20, 30...
            
            // Pulse tlast only on the final element
            if (i == 7) begin
                s_axis_tlast = 1'b1;
            end else begin
                s_axis_tlast = 1'b0;
            end
            
            // Wait 1 clock cycle to advance data (simplified handshake)
            #10; 
        end
        
        // Pull signals low after array is completely sent
        s_axis_tvalid = 1'b0;
        s_axis_tlast = 1'b0;
        
        // Wait for the FFT pipeline to process and output the data
        #1000;
        
        // End simulation
        $finish;
    end

endmodule
