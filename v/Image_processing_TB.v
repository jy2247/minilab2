// Written by us
`timescale 1ns / 1ps

module image_processing_tb;

    // Inputs
    reg clk;
    reg rst;
    reg [10:0] iX_Cont;
    reg [10:0] iY_Cont;
    reg [11:0] bayer_pixel;
    reg valid;

    // Outputs
    wire [11:0] processed_pixel;
    wire processed_valid;
    wire [11:0] processed_pixel2;
    wire processed_valid2;

    // Instantiate the Unit Under Test (UUT)
    image_processing uut (
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

    // Clock generation
    always #5 clk = ~clk;  // 10ns clock period

    // Testbench logic
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 0;
        iX_Cont = 0;
        iY_Cont = 0;
        bayer_pixel = 0;
        valid = 0;

        // Apply reset
        repeat(2) @(posedge clk);
        rst = 1;
        repeat(2) @(posedge clk);
        rst = 0;

        // Start generating input data
        valid = 1;

        // First row (R G R G R G)
        bayer_pixel = 12'hF00; // R
        repeat(2) @(posedge clk);
        bayer_pixel = 12'h0F0; // G
        repeat(2) @(posedge clk);
        bayer_pixel = 12'hF00; // R
        repeat(2) @(posedge clk);
        bayer_pixel = 12'h0F0; // G
        repeat(2) @(posedge clk);
        bayer_pixel = 12'hF00; // R
        repeat(2) @(posedge clk);
        bayer_pixel = 12'h0F0; // G
        repeat(2) @(posedge clk);

        // Second row (G B G B G B)
        bayer_pixel = 12'h0F0; // G
        repeat(2) @(posedge clk);
        bayer_pixel = 12'h00F; // B
        repeat(2) @(posedge clk);
        bayer_pixel = 12'h0F0; // G
        repeat(2) @(posedge clk);
        bayer_pixel = 12'h00F; // B
        repeat(2) @(posedge clk);
        bayer_pixel = 12'h0F0; // G
        repeat(2) @(posedge clk);
        bayer_pixel = 12'h00F; // B
        repeat(2) @(posedge clk);

        // Third row (R G R G R G)
        bayer_pixel = 12'hF00; // R
        repeat(2) @(posedge clk);
        bayer_pixel = 12'h0F0; // G
        repeat(2) @(posedge clk);
        bayer_pixel = 12'hF00; // R
        repeat(2) @(posedge clk);
        bayer_pixel = 12'h0F0; // G
        repeat(2) @(posedge clk);
        bayer_pixel = 12'hF00; // R
        repeat(2) @(posedge clk);
        bayer_pixel = 12'h0F0; // G
        repeat(2) @(posedge clk);

        // Stop generating input data
        valid = 0;

        // Wait for the convolution to complete
        repeat(10) @(posedge clk);

        // Expected results for Sobel convolution
        // Sobel X: [-1, 0, 1; -2, 0, 2; -1, 0, 1]
        // Sobel Y: [-1, -2, -1; 0, 0, 0; 1, 2, 1]
        // Grayscale values:
        // R = 0xF00 (3840), G = 0x0F0 (240), B = 0x00F (15)
        // Grayscale average for each pixel:
        // R = (3840 + 240 + 3840 + 240) / 4 = 2040
        // G = (240 + 15 + 240 + 15) / 4 = 127
        // B = (15 + 240 + 15 + 240) / 4 = 127

        // Convolution window (grayscale values):
        // [2040, 127, 2040]
        // [127, 127, 127]
        // [2040, 127, 2040]

        // Sobel X result:
        // (-1 * 2040) + (0 * 127) + (1 * 2040) +
        // (-2 * 127) + (0 * 127) + (2 * 127) +
        // (-1 * 2040) + (0 * 127) + (1 * 2040) = 0

        // Sobel Y result:
        // (-1 * 2040) + (-2 * 127) + (-1 * 2040) +
        // (0 * 127) + (0 * 127) + (0 * 127) +
        // (1 * 2040) + (2 * 127) + (1 * 2040) = 0

        // Expected outputs:
        // processed_pixel = 0 (Sobel X result)
        // processed_pixel2 = 0 (Sobel Y result)

        // Check the output of the convolution filters
        if (processed_pixel !== 12'h000 || processed_pixel2 !== 12'h000) begin
            $display("ERROR: Convolution results are incorrect!");
            $display("Expected: processed_pixel = 0, processed_pixel2 = 0");
            $display("Got: processed_pixel = %h, processed_pixel2 = %h", processed_pixel, processed_pixel2);
        end else begin
            $display("PASS: Convolution results are correct!");
            $display("processed_pixel = %h, processed_pixel2 = %h", processed_pixel, processed_pixel2);
        end

        // End simulation
        $finish;
    end

endmodule