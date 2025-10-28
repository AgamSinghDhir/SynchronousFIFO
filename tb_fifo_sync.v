`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2025 19:52:05
// Design Name: 
// Module Name: tb_fifo_sync
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


module tb_fifo_sync();
reg clk , reset_n , cs , rd_en , wr_en;
reg [31:0] data_in;
wire [31:0] data_out;
wire empty;
wire full;

integer i;

fifo_sync DUT(clk , reset_n , cs,  wr_en , rd_en , data_in , data_out , empty , full);
 
 initial clk = 0;
 always #5 clk = ~clk; // clock signal
 
 task write_data(input [31:0] d_in);
 begin
 @(posedge clk);
 cs = 1 ; wr_en = 1;
 data_in = d_in;
 $display($time , "write_data data_in = %0d",data_in);
 @(posedge clk);
 cs = 1; wr_en = 0;
 end
 endtask
 
 task read_data();
 begin
 @(posedge clk);
 cs = 1 ; rd_en = 1;
 @(posedge clk);
 $display($time , "read_data data_out = %0d" ,data_out);
 cs = 1 ; rd_en = 0;
 end
 endtask
 
 initial
 begin
 #1;
 reset_n = 0; rd_en = 0; wr_en = 0;
 
 @(posedge clk)
 reset_n = 1;
 for(i = 0 ; i<8 ; i=i+1) begin
 write_data(2**i);
 end
 
 for(i = 0 ; i<8 ; i=i+1) begin
 read_data();
 end
 #40 $finish;
 end
endmodule
