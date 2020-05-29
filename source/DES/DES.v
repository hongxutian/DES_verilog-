`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:23:19 04/12/2020 
// Design Name: 
// Module Name:    DES 
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
//data_out 数据输出64位
//data_in 数据输入64位
//key 密钥64位
//mode 模式，1加密，0解密
module DES(
    output [1:64] data_out,
    input [1:64] data_in,
    input [1:64] key,
    input mode 
    );

wire[1:56] movedkey1,movedkey2,movedkey3,movedkey4,movedkey5,movedkey6,movedkey7,movedkey8,movedkey9,movedkey10,movedkey11,movedkey12,movedkey13,movedkey14,movedkey15,movedkey16;//存放移位后的初始密钥
wire[1:48] roundkey1,roundkey2,roundkey3,roundkey4,roundkey5,roundkey6,roundkey7,roundkey8,roundkey9,roundkey10,roundkey11,roundkey12,roundkey13,roundkey14,roundkey15,roundkey16;//存放16个循环密钥

wire[1:64] ocac;
wire[1:64] iperi;//IP末置换的输入

wire [1:64] enco16;//存放第16轮加解密输出
wire [1:64] enci2,enci3,enci4,enci5,enci6,enci7,enci8,enci9,enci10,enci11,enci12,enci13,enci14,enci15,enci16;//存放每轮加密输入
wire [1:48] encrk1,encrk2,encrk3,encrk4,encrk5,encrk6,encrk7,encrk8,encrk9,encrk10,encrk11,encrk12,encrk13,encrk14,encrk15,encrk16;//存放每轮加密所用轮密钥
wire [1:64] ipro;//IP置换输出

//生成轮密钥
KeyIniReplace kip(.initial_key(key),.kc(movedkey1));

RoundKeyGenerator rkg1(.round_key(roundkey1),.moved_key(movedkey2),.mode(1'b0),.initial_key(movedkey1));
RoundKeyGenerator rkg2(.round_key(roundkey2),.moved_key(movedkey3),.mode(1'b0),.initial_key(movedkey2));
RoundKeyGenerator rkg3(.round_key(roundkey3),.moved_key(movedkey4),.mode(1'b1),.initial_key(movedkey3));
RoundKeyGenerator rkg4(.round_key(roundkey4),.moved_key(movedkey5),.mode(1'b1),.initial_key(movedkey4));
RoundKeyGenerator rkg5(.round_key(roundkey5),.moved_key(movedkey6),.mode(1'b1),.initial_key(movedkey5));
RoundKeyGenerator rkg6(.round_key(roundkey6),.moved_key(movedkey7),.mode(1'b1),.initial_key(movedkey6));
RoundKeyGenerator rkg7(.round_key(roundkey7),.moved_key(movedkey8),.mode(1'b1),.initial_key(movedkey7));
RoundKeyGenerator rkg8(.round_key(roundkey8),.moved_key(movedkey9),.mode(1'b1),.initial_key(movedkey8));
RoundKeyGenerator rkg9(.round_key(roundkey9),.moved_key(movedkey10),.mode(1'b0),.initial_key(movedkey9));
RoundKeyGenerator rkg10(.round_key(roundkey10),.moved_key(movedkey11),.mode(1'b1),.initial_key(movedkey10));
RoundKeyGenerator rkg11(.round_key(roundkey11),.moved_key(movedkey12),.mode(1'b1),.initial_key(movedkey11));
RoundKeyGenerator rkg12(.round_key(roundkey12),.moved_key(movedkey13),.mode(1'b1),.initial_key(movedkey12));
RoundKeyGenerator rkg13(.round_key(roundkey13),.moved_key(movedkey14),.mode(1'b1),.initial_key(movedkey13));
RoundKeyGenerator rkg14(.round_key(roundkey14),.moved_key(movedkey15),.mode(1'b1),.initial_key(movedkey14));
RoundKeyGenerator rkg15(.round_key(roundkey15),.moved_key(movedkey16),.mode(1'b1),.initial_key(movedkey15));
RoundKeyGenerator rkg16(.round_key(roundkey16),.mode(1'b0),.initial_key(movedkey16));

//设置轮密钥
assign encrk1 = mode ? roundkey1 : roundkey16;
assign encrk2 = mode ? roundkey2 : roundkey15;
assign encrk3 = mode ? roundkey3 : roundkey14;
assign encrk4 = mode ? roundkey4 : roundkey13;
assign encrk5 = mode ? roundkey5 : roundkey12;
assign encrk6 = mode ? roundkey6 : roundkey11;
assign encrk7 = mode ? roundkey7 : roundkey10;
assign encrk8 = mode ? roundkey8 : roundkey9;
assign encrk9 = mode ? roundkey9 : roundkey8;
assign encrk10 = mode ? roundkey10 : roundkey7;
assign encrk11 = mode ? roundkey11 : roundkey6;
assign encrk12 = mode ? roundkey12 : roundkey5;
assign encrk13 = mode ? roundkey13 : roundkey4;
assign encrk14 = mode ? roundkey14 : roundkey3;
assign encrk15 = mode ? roundkey15 : roundkey2;
assign encrk16 = mode ? roundkey16 : roundkey1;

//IP置换
IPReplace ipr(.data_in(data_in),.data_out(ipro));

//16轮加解密
EncryptCycle enc1(.data_in(ipro),.round_key(encrk1),.data_out(enci2));
EncryptCycle enc2(.data_in(enci2),.round_key(encrk2),.data_out(enci3));
EncryptCycle enc3(.data_in(enci3),.round_key(encrk3),.data_out(enci4));
EncryptCycle enc4(.data_in(enci4),.round_key(encrk4),.data_out(enci5));
EncryptCycle enc5(.data_in(enci5),.round_key(encrk5),.data_out(enci6));
EncryptCycle enc6(.data_in(enci6),.round_key(encrk6),.data_out(enci7));
EncryptCycle enc7(.data_in(enci7),.round_key(encrk7),.data_out(enci8));
EncryptCycle enc8(.data_in(enci8),.round_key(encrk8),.data_out(enci9));
EncryptCycle enc9(.data_in(enci9),.round_key(encrk9),.data_out(enci10));
EncryptCycle enc10(.data_in(enci10),.round_key(encrk10),.data_out(enci11));
EncryptCycle enc11(.data_in(enci11),.round_key(encrk11),.data_out(enci12));
EncryptCycle enc12(.data_in(enci12),.round_key(encrk12),.data_out(enci13));
EncryptCycle enc13(.data_in(enci13),.round_key(encrk13),.data_out(enci14));
EncryptCycle enc14(.data_in(enci14),.round_key(encrk14),.data_out(enci15));
EncryptCycle enc15(.data_in(enci15),.round_key(encrk15),.data_out(enci16));
EncryptCycle enc16(.data_in(enci16),.round_key(encrk16),.data_out(enco16));

assign iperi = {enco16[33:64],enco16[1:32]};

//IP末置换
IPEndReplace iper(.data_in(iperi),.data_out(ocac));
assign data_out = ocac;
endmodule
