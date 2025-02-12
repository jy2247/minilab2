`timescale 1ns / 1ps

module img_proc_tb();

    // Signals
    reg clk, rst;
    reg [10:0] iX_Cont, iY_Cont;
    reg [11:0] bayer_pixel;
    reg valid;
    
    wire [11:0] processed_pixel, processed_pixel2;
    wire processed_valid, processed_valid2;

    // Instantiate the DUT (Device Under Test)
    image_processing DUT (
        .clk(clk),
        .rst(rst),
        .iX_Cont(iX_Cont),
        .iY_Cont(iY_Cont),
        .bayer_pixel(bayer_pixel),
        .valid(valid),
        .processed_pixel(processed_pixel),
        .processed_valid(processed_valid),
        .processed_pixel2(processed_pixel2),
        .processed_valid2(processed_valid2)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // Test Sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        iX_Cont = 0;
        iY_Cont = 0;
        bayer_pixel = 12'h000;
        valid = 0;

        // Apply Reset
        #10 rst = 0;
        #10 rst = 1;

        // Apply test patterns
        valid = 1;
        repeat (10) begin
            #10;
            iX_Cont = $random % 2048;  // Random X coordinate
            iY_Cont = $random % 2048;  // Random Y coordinate
            bayer_pixel = $random % 4096; // Random 12-bit pixel value
        end

        // Wait for processed outputs
        #50;
        valid = 0;

        // Check results
        if (processed_valid && processed_valid2) begin
            $display("Test Passed: Processed outputs are valid");
        end else begin
            $display("Test Failed: Processed outputs not valid");
        end

        $finish;
    end

endmodule
