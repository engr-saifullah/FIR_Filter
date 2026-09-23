`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/20/2026 11:42:38 AM
// Design Name: 
// Module Name: FIR_FILTER
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


    module FIR_FILTER(
    input logic clk, rst,
    input logic data_valid,
    input logic signed [12:0] data_in,
    output logic signed [15:0] data_out,
    output logic out_valid
    );
    
    (* ram_style = "block" *) logic signed [12:0] circ_buffer [0:72];
    
    integer k ;
    initial begin
    for (k=0 ; k<73; k = k+1)
    circ_buffer[k] = 13'sd0;
    end
    
    logic signed [12:0] rd_old , rd_new; //bram output registers
    
    //control section
    
    typedef enum logic [1:0] {
    IDLE = 2'b00,
    RUN = 2'b01,
    DRAIN = 2'b10
    }state_t;
    
    state_t state;
    
    logic [6:0] wr_ptr;
    logic [6:0] ptr_new;
    logic [6:0] ptr_old;
    logic [5:0] tap;
    logic [5:0] tap_d;
    logic v1 , v2 , v3 , fin;
    
    wire [6:0] wr_ptr_inc = (wr_ptr == 7'd72) ? 7'd0 : wr_ptr + 7'd1;
    wire [6:0] new_dec = (ptr_new == 7'd0) ? 7'd72 : ptr_new - 7'd1;
    wire [6:0] old_inc = (ptr_old == 7'd72) ? 7'd0 : ptr_old + 7'd1;
    
    wire accept = (state == IDLE) & data_valid;
    wire [6:0] addr_a = (state == IDLE) ? wr_ptr : ptr_new;
    wire [6:0] addr_b = ptr_old;
    
    always_ff @(posedge clk) begin
    if(accept)
    circ_buffer[addr_a] <= data_in;
    rd_new <= circ_buffer[addr_a];
    end
    
    always_ff @(posedge clk)
    rd_old <= circ_buffer[addr_b];
    
    
    (* rom_style = "distributed" *) logic signed [15:0] coeff;
    always_ff @(posedge clk) begin
    case(tap_d)
    6'd0 : coeff <= 16'sd846;   
    6'd1 : coeff <= 16'sd673;
    6'd2 : coeff <= 16'sd931;    
    6'd3 : coeff <= 16'sd1243;
    6'd4 : coeff <= 16'sd1615;   
    6'd5 : coeff <= 16'sd2054;
    6'd6 : coeff <= 16'sd2562;   
    6'd7 : coeff <= 16'sd3145;
    6'd8 : coeff <= 16'sd3805;   
    6'd9 : coeff <= 16'sd4544;
    6'd10: coeff <= 16'sd5365;   
    6'd11: coeff <= 16'sd6267;
    6'd12: coeff <= 16'sd7249;   
    6'd13: coeff <= 16'sd8309;
    6'd14: coeff <= 16'sd9443;   
    6'd15: coeff <= 16'sd10646;
    6'd16: coeff <= 16'sd11912;  
    6'd17: coeff <= 16'sd13233;
    6'd18: coeff <= 16'sd14601;  
    6'd19: coeff <= 16'sd16004;
    6'd20: coeff <= 16'sd17431;  
    6'd21: coeff <= 16'sd18870;
    6'd22: coeff <= 16'sd20308;  
    6'd23: coeff <= 16'sd21731;
    6'd24: coeff <= 16'sd23125;  
    6'd25: coeff <= 16'sd24475;
    6'd26: coeff <= 16'sd25767;  
    6'd27: coeff <= 16'sd26987;
    6'd28: coeff <= 16'sd28120;  
    6'd29: coeff <= 16'sd29154;
    6'd30: coeff <= 16'sd30077;  
    6'd31: coeff <= 16'sd30878;
    6'd32: coeff <= 16'sd31547;  
    6'd33: coeff <= 16'sd32076;
    6'd34: coeff <= 16'sd32459;  
    6'd35: coeff <= 16'sd32691;
    6'd36: coeff <= 16'sd32767;                
    default: coeff <= 16'sd0;
    endcase
    end
    
     
    //main datapath
    logic signed [13:0] pre_add;
    logic signed [29:0] product;
    logic signed [33:0] accum;
    
    wire signed [13:0] pair_sum = rd_new + rd_old;
    
    always_ff @(posedge clk) begin
    tap_d <= tap;
    pre_add <= (tap_d == 6'd36) ? {rd_new[12] , rd_new } : pair_sum ;
    product <= pre_add * coeff;
    if (accept) accum <= 34'sd0;
    else if (v3) accum <= accum + product;
    
    end
    
    always_ff @(posedge clk) begin
    if(rst)begin
    state <= IDLE;
    wr_ptr <= 7'd0;
    tap <= 6'd0;
    v1 <= 1'b0;
    v2 <= 1'b0;
    v3 <= 1'b0;
    fin <= 1'b0;
    out_valid <= 1'b0;
    data_out <= 16'b0;
    end 
    else begin
    v1 <= (state == RUN);
    v2 <= v1;
    v3 <= v2;
    fin <= v3 & ~v2;
    out_valid <= fin ;
    
    case(state)
    IDLE: if (data_valid) begin
    ptr_new <= wr_ptr ;
    ptr_old <= wr_ptr_inc ;
    wr_ptr <= wr_ptr_inc;
    tap <= 6'd0;
    state <= RUN;
    end
    
    RUN : begin
    ptr_new <= new_dec;
    ptr_old <= old_inc;
    tap <= tap + 6'd1;
    if(tap == 6'd36)
        state <= DRAIN;
    end
    
    DRAIN: if (fin) state <= IDLE ;
    default : state <= IDLE;
    endcase
    
    if (fin) begin
    if (accum[33:27] ==7'b0000000 || accum[33:27] == 7'b1111111)
        data_out <= accum[27:12];
        else
        data_out<=accum[33] ? 16'sh8000 : 16'sh7FFF;
        end 
    end
end
 
endmodule
