`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:25:53 04/22/2020 
// Design Name: 
// Module Name:    KeyIniReplace 
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
module KeyIniReplace(
    input [1:64] initial_key,
    output [1:56] kc
    );

assign kc[1]=initial_key[57];
assign kc[2]=initial_key[49];
assign kc[3]=initial_key[41];
assign kc[4]=initial_key[33];
assign kc[5]=initial_key[25];
assign kc[6]=initial_key[17];
assign kc[7]=initial_key[9];
assign kc[8]=initial_key[1];
			
assign kc[9]=initial_key[58];
assign kc[10]=initial_key[50];
assign kc[11]=initial_key[42];
assign kc[12]=initial_key[34];
assign kc[13]=initial_key[26];
assign kc[14]=initial_key[18];
assign kc[15]=initial_key[10];
assign kc[16]=initial_key[2];
			
assign kc[17]=initial_key[59];
assign kc[18]=initial_key[51];
assign kc[19]=initial_key[43];
assign kc[20]=initial_key[35];
assign kc[21]=initial_key[27];
assign kc[22]=initial_key[19];
assign kc[23]=initial_key[11];
assign kc[24]=initial_key[3];
			
assign kc[25]=initial_key[60];
assign kc[26]=initial_key[52];
assign kc[27]=initial_key[44];
assign kc[28]=initial_key[36];		
assign kc[29]=initial_key[63];
assign kc[30]=initial_key[55];
assign kc[31]=initial_key[47];
assign kc[32]=initial_key[39];
			
assign kc[33]=initial_key[31];
assign kc[34]=initial_key[23];
assign kc[35]=initial_key[15];
assign kc[36]=initial_key[7];			
assign kc[37]=initial_key[62];
assign kc[38]=initial_key[54];
assign kc[39]=initial_key[46];
assign kc[40]=initial_key[38];
			
assign kc[41]=initial_key[30];
assign kc[42]=initial_key[22];			
assign kc[43]=initial_key[14];
assign kc[44]=initial_key[6];
assign kc[45]=initial_key[61];
assign kc[46]=initial_key[53];
assign kc[47]=initial_key[45];
assign kc[48]=initial_key[37];
			
assign kc[49]=initial_key[29];
assign kc[50]=initial_key[21];
assign kc[51]=initial_key[13];
assign kc[52]=initial_key[5];
assign kc[53]=initial_key[28];
assign kc[54]=initial_key[20];
assign kc[55]=initial_key[12];
assign kc[56]=initial_key[4];

endmodule
