`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:25:54 04/12/2020 
// Design Name: 
// Module Name:    RoundKeyGenerator 
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
module RoundKeyGenerator(
	 output [1:48] round_key,
	 output [1:56] moved_key,
    input mode,
    input [1:56] initial_key
    );

wire [1:56] inikey;

assign inikey = (mode == 0) ? 
		{initial_key[2:28],initial_key[1],initial_key[30:56],initial_key[29]}
		: {initial_key[3:28],initial_key[1],initial_key[2],initial_key[31:56],initial_key[29],initial_key[30]}; 

// always @(initial_key,mode)
// begin
// 	if(mode == 0)
// 	begin
// 		inikey = {initial_key[2:28],initial_key[1],initial_key[30:56],initial_key[29]};
// 	end
// 	else
// 	begin
// 		inikey = {initial_key[3:28],initial_key[1],initial_key[2],initial_key[31:56],initial_key[29],initial_key[30]};
// 	end
// end

assign moved_key = inikey;

assign round_key[1] = inikey[14];
assign round_key[2] = inikey[17];
assign round_key[3] = inikey[11];
assign round_key[4] = inikey[24];
assign round_key[5] = inikey[1];
assign round_key[6] = inikey[5];
assign round_key[7] = inikey[3];
assign round_key[8] = inikey[28];
assign round_key[9] = inikey[15];
assign round_key[10] = inikey[6];
assign round_key[11] = inikey[21];
assign round_key[12] = inikey[10];
		
assign round_key[13] = inikey[23];
assign round_key[14] = inikey[19];
assign round_key[15] = inikey[12];
assign round_key[16] = inikey[4];
assign round_key[17] = inikey[26];
assign round_key[18] = inikey[8];
assign round_key[19] = inikey[16];
assign round_key[20] = inikey[7];
assign round_key[21] = inikey[27];
assign round_key[22] = inikey[20];
assign round_key[23] = inikey[13];
assign round_key[24] = inikey[2];
		
assign round_key[25] = inikey[41];
assign round_key[26] = inikey[52];
assign round_key[27] = inikey[31];
assign round_key[28] = inikey[37];
assign round_key[29] = inikey[47];
assign round_key[30] = inikey[55];
assign round_key[31] = inikey[30];
assign round_key[32] = inikey[40];
assign round_key[33] = inikey[51];
assign round_key[34] = inikey[45];
assign round_key[35] = inikey[33];
assign round_key[36] = inikey[48];
		
assign round_key[37] = inikey[44];
assign round_key[38] = inikey[49];
assign round_key[39] = inikey[39];
assign round_key[40] = inikey[56];
assign round_key[41] = inikey[34];
assign round_key[42] = inikey[53];
assign round_key[43] = inikey[46];
assign round_key[44] = inikey[42];
assign round_key[45] = inikey[50];
assign round_key[46] = inikey[36];
assign round_key[47] = inikey[29];
assign round_key[48] = inikey[32];

endmodule
