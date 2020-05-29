`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:19:10 04/15/2020 
// Design Name: 
// Module Name:    EncryptCycle 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module EncryptCycle(
    input [1:64] data_in,
    input [1:48] round_key,
    output [1:64] data_out
    );
reg [1:32] left,right;
reg [1:48] rk;
wire [1:32] lt;
wire [1:48] rigex;
wire [1:48] rigex2;
wire [1:32] s;
wire [1:32] p;


always @(data_in,round_key)
begin
	left  = data_in[1:32];
   right = data_in[33:64];
	rk = round_key;
end


EExpand eex(.data_in(right),.data_out(rigex));

assign rigex2 = rigex ^ rk;
SBox sb(.data_in(rigex2),.data_out(s));
PBox pb(.data_in(s),.data_out(p));

assign lt = left ^ p;

assign data_out = {right,lt};

endmodule
