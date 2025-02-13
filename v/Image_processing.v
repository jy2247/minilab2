// Written by us


module image_processing (
    input wire clk,
    input wire rst,
    input wire [10:0] iX_Cont,
    input wire [10:0] iY_Cont,
    input wire [11:0] bayer_pixel,  // 12-bit Bayer pattern pixel
    input wire valid,               // Valid signal for incoming pixel
    output wire [11:0] processed_pixel, // 12-bit grayscale output after convolution filter 1
    output wire processed_valid,      // Valid signal for processed output
    output wire [11:0] processed_pixel2, // 12-bit grayscale output after convolution filter 2
    output wire processed_valid2     // Valid signal for processed output
);

    // Internal signals for Bayer to grayscale conversion
    wire [11:0] mDATA_0;
    wire [11:0] mDATA_1;
    reg  [11:0] mDATAd_0;
    reg  [11:0] mDATAd_1;
    reg  [11:0] mCCD_GRAY;

    // Internal signals for grayscale line buffers
    wire [11:0] gDATA_0;
    wire [11:0] gDATA_1;
    reg  [11:0] gDATAd_0;
    reg  [11:0] gDATAd_1;

    // Internal signals for 3x3 convolution
    reg  [11:0] conv_window [0:2][0:2];  // 3x3 window for convolution
    reg  signed [15:0] conv_result, conv_result2;      // Convolution result (may be negative)
    reg  [11:0] conv_output, conv_output2;             // Final output after convolution

    // Instantiate Bayer Line Buffer
    Line_Buffer1 u0 (
        .clken(valid),
        .clock(clk),
        .shiftin(bayer_pixel),
        .taps0x(mDATA_1),
        .taps1x(mDATA_0)
    );

    // Bayer to grayscale conversion
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            mCCD_GRAY <= 0;
            mDATAd_0  <= 0;
            mDATAd_1  <= 0;
        end else begin
            mDATAd_0 <= mDATA_0;
            mDATAd_1 <= mDATA_1;

            // Calculate grayscale value by averaging the Bayer pattern values
            mCCD_GRAY <= (mDATA_0 + mDATA_1 + mDATAd_0 + mDATAd_1) >> 2;  // Average of 4 pixels
        end
    end

    // Instantiate grayscale Line Buffer
    Line_Buffer1 u1 (
        .clken(valid),
        .clock(clk),
        .shiftin(mCCD_GRAY),
        .taps0x(gDATA_1),
        .taps1x(gDATA_0)
    );

    // Buffer grayscale pixels for 3x3 convolution
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            gDATAd_0 <= 0;
            gDATAd_1 <= 0;
            conv_window[0][0] <= 0; conv_window[0][1] <= 0; conv_window[0][2] <= 0;
            conv_window[1][0] <= 0; conv_window[1][1] <= 0; conv_window[1][2] <= 0;
            conv_window[2][0] <= 0; conv_window[2][1] <= 0; conv_window[2][2] <= 0;
        end else begin
            gDATAd_0 <= gDATA_0;
            gDATAd_1 <= gDATA_1;

            // Shift pixels into the 3x3 window
            conv_window[0][0] <= conv_window[0][1];
            conv_window[0][1] <= conv_window[0][2];
            conv_window[0][2] <= gDATA_0;

            conv_window[1][0] <= conv_window[1][1];
            conv_window[1][1] <= conv_window[1][2];
            conv_window[1][2] <= gDATAd_0;

            conv_window[2][0] <= conv_window[2][1];
            conv_window[2][1] <= conv_window[2][2];
            conv_window[2][2] <= gDATAd_1;
        end
    end

    // Perform 3x3 convolution
    always @(posedge clk) begin
        // filter: Sobel 
        conv_result <= 
            (conv_window[0][0] * (-1)) + (conv_window[0][1] * 0) + (conv_window[0][2] * 1) +
            (conv_window[1][0] * (-2)) + (conv_window[1][1] * 0) + (conv_window[1][2] * 2) +
            (conv_window[2][0] * (-1)) + (conv_window[2][1] * 0) + (conv_window[2][2] * 1);


        conv_result2 <= 
            (conv_window[0][0] * (-1)) + (conv_window[0][1] * (-2)) + (conv_window[0][2] *(-1)) +
            (conv_window[1][0] * (0)) + (conv_window[1][1] * 0) + (conv_window[1][2] * 0) +
            (conv_window[2][0] * (1)) + (conv_window[2][1] * 2) + (conv_window[2][2] * 1);

        // Take absolute value and clamp to 12-bit range
        conv_output <= (conv_result < 0) ? -conv_result : conv_result;
        conv_output2 <= (conv_result2 < 0) ? -conv_result2 : conv_result2;
        if (conv_output > 4095) conv_output <= 4095;  // Clamp to 12-bit range
        if (conv_output2 > 4095) conv_output2 <= 4095;
    end

    // Output processed pixel and valid signal
    assign processed_pixel = conv_output;
    assign processed_valid = valid;  // Propagate valid signal
    assign processed_pixel2 = conv_output2;
    assign processed_valid2 = valid;  // Propagate valid signal

endmodule