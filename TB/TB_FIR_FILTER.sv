`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/21/2026 02:00:09 PM
// Design Name: 
// Module Name: TB_FIR_FILTER
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_fir_filter;
    logic clk;
    initial clk = 0;
    always #5 clk = ~clk; 
    logic rst;
    logic signed [12:0] data_in;
    logic data_valid;
    logic signed [15:0] data_out;
    logic out_valid;

    FIR_FILTER uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_out(data_out),
        .out_valid(out_valid)
    );

    logic signed [12:0] input_mem [0:99];
    logic signed [15:0] expected_mem [0:99];
    initial begin
        $readmemh("input_stimulus.txt", input_mem);
        $readmemh("expected_outputs.txt", expected_mem);
    end
    initial begin
        rst = 1;
        data_in = 0;
        data_valid = 0;
        #100;
        rst = 0;
    end
    integer timer = 0;
    integer sample_idx = 0;

    always @(posedge clk) begin
        if (rst) begin
            timer <= 0;
            sample_idx <= 0;
            data_valid <= 0;
        end else if (sample_idx < 100) begin
          
            if (timer == 99) begin
                data_in <= input_mem[sample_idx];
                data_valid <= 1;           
                sample_idx <= sample_idx + 1;
                timer <= 0;                
            end else begin
                data_valid <= 0;         
                timer <= timer + 1;
            end
        end else begin
            data_valid <= 0;
        end
    end

    integer check_idx = 0;
    integer errors = 0;

    always @(posedge clk) begin
        if (out_valid) begin
            if (data_out !== expected_mem[check_idx]) begin
                $display("FAIL at sample %0d: Expected %h, Got %h", check_idx, expected_mem[check_idx], data_out);
                errors <= errors + 1;
            end else begin
                $display("PASS at sample %0d: Output = %h", check_idx, data_out);
            end
            
            check_idx <= check_idx + 1;
            
            if (check_idx == 99) begin
                if (errors == 0)
                    $display("SUCCESS: All 100 samples match the C Golden Reference Model.");
                else
                    $display("SIMULATION COMPLETE: %0d mismatches found.", errors);
                $finish;
            end
        end
    end

endmodule