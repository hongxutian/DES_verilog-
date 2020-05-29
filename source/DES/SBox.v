`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:18:59 04/14/2020 
// Design Name: 
// Module Name:    SBox 
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
module SBox(
    input [1:48] data_in,
    output [1:32] data_out
    );

SBox1 s1(data_in[1:6],data_out[1:4]);
SBox2 s2(data_in[7:12],data_out[5:8]);
SBox3 s3(data_in[13:18],data_out[9:12]);
SBox4 s4(data_in[19:24],data_out[13:16]);
SBox5 s5(data_in[25:30],data_out[17:20]);
SBox6 s6(data_in[31:36],data_out[21:24]);
SBox7 s7(data_in[37:42],data_out[25:28]);
SBox8 s8(data_in[43:48],data_out[29:32]);

endmodule
