`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2025 19:26:19
// Design Name: 
// Module Name: fifo_sync
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


module fifo_sync(clk , reset_n , cs,  wr_en , rd_en , data_in , data_out , empty , full);
input clk , reset_n , cs , wr_en , rd_en;
input [31:0] data_in;
output reg [31:0] data_out;
output full , empty;

reg [31:0] fifo[0:7]; // memory where data will be stored
reg [3:0] write_pointer , read_pointer;

always@(posedge clk or negedge reset_n) begin //write
if(!reset_n) write_pointer <= 0;
else if(cs && wr_en && !full)
begin
fifo[write_pointer] <= data_in;
write_pointer <= write_pointer + 1'b1;
end
end

always@(posedge clk or negedge reset_n) begin //read
if(!reset_n) read_pointer <= 0;
else if(cs && rd_en && !empty)
begin
data_out <= fifo[read_pointer];
read_pointer <= read_pointer + 1'b1;  
end
end

assign empty = (read_pointer == write_pointer);
assign full = (read_pointer == {~write_pointer[3] , write_pointer[2:0]});
endmodule
