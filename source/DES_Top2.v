`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:00:56 05/07/2020 
// Design Name: 
// Module Name:    DES_Top2 
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

//des模块的数据传输格式
//1、发送给模块的数据格式
//标识+数据填充格式+密钥+CBC iv偏移量+数据长度+数据
//标识：0x11 ECB加密，0x12 ECB解密，0x21 CBC加密，0x22CBC解密
//数据填充格式：0x01 zeropadding，0x02 pkcs7padding
//密钥：8个字节
//CBC iv偏移量：8个字节，CBC模式需要传输，ECB模式不要传输
//数据长度：4个字节，高位字节在前
//数据：模块会接收数据长度规定的数据字节数
//
//注1：数据发送完毕后可以发送0xff，0xff为空闲字符，模块不会处理，发送0xff等待模块处理完毕，
//模块在没有有效数据发出前会发送0xff,有有效数据发出时，先发送0x01数据起始，然后发送有效数
//据，有效数据发送完毕之后，继续发送0xff
//
//注2：模块采用SPI协议传输，空闲时时钟信号为低电平，第一个时钟边沿发送数据（即上升沿发送数据），
//第二个时钟边沿接收数据（即下降沿接收数据）

module DES_Top2(
	input		wire						SCLK,
	input		wire						CS,
	input		wire						MOSI,
	output		wire						MISO
    );

parameter 		s0 = 8'd0,//空闲状态
				s1 = 8'd1,//接收参数
				s2 = 8'd2;//接收数据、处理、返回

parameter       dumpy = 8'hff;
parameter		intercept = 64'h000000000000001f;//限制存储范围

reg 		[7:0]				state;//模块的状态

//SPI模块的连接
wire							recflag;
wire		[7:0]				recdata;
wire							senflag;
reg			[7:0]				sendata;

//存放加解密需要用到的数据
reg 							recpf;//参数接收完成标志位
reg			[7:0] 				key [0:7];//密钥
reg			[7:0]				vec [0:7];//向量
reg			[7:0]				work;//工作模式，加解密，ECB CBC
reg			[7:0]          		datpad;//数据填充方式01 zero 02 pkcs7
reg			[31:0]				reclen;//待处理数据的长度
reg			[7:0]				buff [0:31];//接收缓冲区
reg			[7:0]				buff2 [0:31];//发送缓冲区

//数据接收的标志
reg								cnt_pad;//是否接收了填充格式
reg			[3:0]				cnt_key;//计算接收了多少个字节的密钥
reg			[3:0]				cnt_vec;//计算接收了多少个字节的向量
reg			[3:0]				cnt_len;//计算接收了多少个字节的待处理数据长度
reg			[31:0]				cnt_data;//计算接收了多少个字节的数据

//DES模块的连接
wire 		[1:64]				desout;//des模块的输出
reg			[1:64]				desin;//des模块的输入
reg			[1:64]				deskey;//密钥
reg								desmode;//设置des模式，1加密，0解密


reg			[31:0]				cnt_handata;//计算处理了多少个数据
reg 		[31:0]				cnt_save;//计算存储了多少个处理之后的数据
reg         [31:0]				cnt_send;//计算发送了多少处理之后的数据
reg 		 					wflag;//处理了8个字节数据的标志
reg			[1:64]				cbccyc;//CBC解密的中间变量
reg 							senf;//数据发送完成标志

reg 							recendf;//数据接收完成标志

reg							senstf;//数据有效返回起始标志是否已发

//SPI模块
SPI_Module		spi1(.SCLK(SCLK),.CS(CS),.MOSI(MOSI),.MISO(MISO),.recdata(recdata),
						  .recflag(recflag),.sendata(sendata),.senflag(senflag));

//DES模块
DES des1(.data_out(desout),.data_in(desin),.key(deskey),.mode(desmode));

//状态切换
always @(posedge SCLK or posedge CS) begin
	if (CS == 1'b1) begin
		state <= s0;
	end
	else if (state == s0) begin
		if (recflag == 1'b1) begin
			if(recdata == 8'h11 || recdata == 8'h12 || recdata == 8'h21 || recdata == 8'h22) begin
				work <= recdata;
				state <= s1;
				//$display("s1");
			end
		end
	end
	else if(state == s1) begin
		if(recpf == 1'b1) begin
			state <= s2;
			//$display("s2");
			//$display("reclen=%h",reclen);
			//$display("key=%h",key);
		end
	end
	else if(state == s2) begin
		if(senf == 1'b1) begin
			state <= s0;
		end
	end
end

//接收参数
always @(posedge SCLK or posedge CS) begin
	if (CS == 1'b1) begin
		cnt_pad <= 1'b0;
		cnt_key <= 4'd0;
		cnt_vec <= 4'd0;
		cnt_len <= 4'd0;
		recpf <= 1'b0;
	end
	else if(state == s1) begin
		if (recflag == 1'b1) begin
			//$display("para = %h",recdata);
			if(work == 8'h11 || work == 8'h12 || work == 8'h21 || work == 8'h22) begin
				if(cnt_pad == 1'b0) begin
					datpad <= recdata;
					cnt_pad <= 1'b1;
				end
				else if(work == 8'h11 || work == 8'h12) begin //接收ECB加解密的数据
					if(cnt_key < 4'd8) begin  //接收密钥
						key[cnt_key] <= recdata;
						cnt_key <= cnt_key + 4'd1;
					end
					else if(cnt_len < 4'd4) begin  //接收数据长度
						case(cnt_len)
							4'd0:begin
								reclen[31:24] <= recdata;
							end
							4'd1:begin
								reclen[23:16] <= recdata;
							end
							4'd2:begin
								reclen[15:8] <= recdata;
							end
							4'd3:begin
								reclen[7:0] <= recdata;
								recpf <= 1'b1;
							end
						endcase
						cnt_len <= cnt_len + 4'd1;
					end
				end
				else if(work == 8'h21 || work == 8'h22) begin //接收CBC加解密的数据
					if(cnt_key < 4'd8) begin //接收密钥
						key[cnt_key] <= recdata;
						cnt_key <= cnt_key + 4'd1;
					end
					else if(cnt_vec < 4'd8) begin  //接收向量
						vec[cnt_vec] <= recdata;
						cnt_vec <= cnt_vec + 4'd1;
					end
					else if(cnt_len < 4'd4) begin  //接收数据长度
						case(cnt_len)
							4'd0:begin
								reclen[31:24] <= recdata;
							end
							4'd1:begin
								reclen[23:16] <= recdata;
							end
							4'd2:begin
								reclen[15:8] <= recdata;
							end
							4'd3:begin
								reclen[7:0] <= recdata;
								recpf <= 1'b1;
							end
						endcase
						cnt_len <= cnt_len + 4'd1;
					end
				end
			end
		end
		
	end
	else begin
		cnt_pad <= 1'b0;
		cnt_key <= 4'd0;
		cnt_vec <= 4'd0;
		cnt_len <= 4'd0;
		recpf <= 1'b0;
	end
end

//接收数据
always @(posedge SCLK or posedge CS) begin
	if (CS == 1'b1) begin
		cnt_data <= 32'd0;
		recendf <= 1'b0;
	end
	else if (state == s2) begin
		if (recflag == 1'b1) begin
			//----------
			if (work == 8'h11 || work == 8'h12 || work == 8'h21 || work == 8'h22) begin
				if(cnt_data < reclen) begin //接收数据
					//$display("data = %h",recdata);
					buff[cnt_data & intercept] <= recdata;
					cnt_data <= cnt_data + 32'd1;
				end
				if(recendf == 1'b0 && (cnt_data + 32'd1) == reclen) begin
					recendf <= 1'b1;
					if(work == 8'h11 || work == 8'h21) begin //对加密模式进行数据填充
						//$display("data padding");
						case(reclen[2:0])
							3'd0:begin
								if(datpad == 8'h01) begin     //zeropadding 填充8个0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
									buff[(reclen + 2) & intercept] <= 8'h00; 
									buff[(reclen + 3) & intercept] <= 8'h00; 
									buff[(reclen + 4) & intercept] <= 8'h00; 
									buff[(reclen + 5) & intercept] <= 8'h00; 
									buff[(reclen + 6) & intercept] <= 8'h00; 
									buff[(reclen + 7) & intercept] <= 8'h00; 
								end
								else  begin                   //pkcs7padding 填充8个8  
									buff[(reclen + 0) & intercept] <= 8'h08; 
									buff[(reclen + 1) & intercept] <= 8'h08; 
									buff[(reclen + 2) & intercept] <= 8'h08; 
									buff[(reclen + 3) & intercept] <= 8'h08; 
									buff[(reclen + 4) & intercept] <= 8'h08; 
									buff[(reclen + 5) & intercept] <= 8'h08; 
									buff[(reclen + 6) & intercept] <= 8'h08; 
									buff[(reclen + 7) & intercept] <= 8'h08;
								end
								cnt_data <= reclen + 32'd8;
							end
							3'd1:begin//7
								if(datpad == 8'h01) begin      //zeropadding 填充7个0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
									buff[(reclen + 2) & intercept] <= 8'h00; 
									buff[(reclen + 3) & intercept] <= 8'h00; 
									buff[(reclen + 4) & intercept] <= 8'h00; 
									buff[(reclen + 5) & intercept] <= 8'h00; 
									buff[(reclen + 6) & intercept] <= 8'h00; 
								end
								else begin                    //pkcs7padding 填充7个7
									buff[(reclen + 0) & intercept] <= 8'h07; 
									buff[(reclen + 1) & intercept] <= 8'h07; 
									buff[(reclen + 2) & intercept] <= 8'h07; 
									buff[(reclen + 3) & intercept] <= 8'h07; 
									buff[(reclen + 4) & intercept] <= 8'h07; 
									buff[(reclen + 5) & intercept] <= 8'h07; 
									buff[(reclen + 6) & intercept] <= 8'h07; 
								end
								cnt_data <= reclen + 32'd7;
							end
							3'd2:begin
								if(datpad == 8'h01) begin     //zeropadding 填充6个0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
									buff[(reclen + 2) & intercept] <= 8'h00; 
									buff[(reclen + 3) & intercept] <= 8'h00; 
									buff[(reclen + 4) & intercept] <= 8'h00; 
									buff[(reclen + 5) & intercept] <= 8'h00; 
								end
								else begin                    //pkcs7padding 填充6个6
									buff[(reclen + 0) & intercept] <= 8'h06; 
									buff[(reclen + 1) & intercept] <= 8'h06; 
									buff[(reclen + 2) & intercept] <= 8'h06; 
									buff[(reclen + 3) & intercept] <= 8'h06; 
									buff[(reclen + 4) & intercept] <= 8'h06; 
									buff[(reclen + 5) & intercept] <= 8'h06; 
								end
								cnt_data <= reclen + 32'd6;
							end
							3'd3:begin
								if(datpad == 8'h01) begin      //zeropadding 填充5个0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
									buff[(reclen + 2) & intercept] <= 8'h00; 
									buff[(reclen + 3) & intercept] <= 8'h00; 
									buff[(reclen + 4) & intercept] <= 8'h00; 
								end
								else begin                     //pkcs7padding 填充5个5
									buff[(reclen + 0) & intercept] <= 8'h05; 
									buff[(reclen + 1) & intercept] <= 8'h05; 
									buff[(reclen + 2) & intercept] <= 8'h05; 
									buff[(reclen + 3) & intercept] <= 8'h05; 
									buff[(reclen + 4) & intercept] <= 8'h05; 
								end
								cnt_data <= reclen + 32'd5;
							end
							3'd4:begin
								if(datpad == 8'h01) begin     //zeropadding 填充4个0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
									buff[(reclen + 2) & intercept] <= 8'h00; 
									buff[(reclen + 3) & intercept] <= 8'h00; 
								end
								else begin                    //pkcs7padding 填充4个4
									buff[(reclen + 0) & intercept] <= 8'h04; 
									buff[(reclen + 1) & intercept] <= 8'h04; 
									buff[(reclen + 2) & intercept] <= 8'h04; 
									buff[(reclen + 3) & intercept] <= 8'h04; 
								end
								cnt_data <= reclen + 32'd4;
							end
							3'd5:begin
								if(datpad == 8'h01) begin     //zeropadding 填充3个0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
									buff[(reclen + 2) & intercept] <= 8'h00; 
								end
								else begin                    //pkcs7padding 填充3个3
									buff[(reclen + 0) & intercept] <= 8'h03; 
									buff[(reclen + 1) & intercept] <= 8'h03; 
									buff[(reclen + 2) & intercept] <= 8'h03;  
								end
								cnt_data <= reclen + 32'd3;
							end
							3'd6:begin
								if(datpad == 8'h01) begin     //zeropadding 填充2个0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
								end
								else begin                    //pkcs7padding 填充2个2
									buff[(reclen + 0) & intercept] <= 8'h02; 
									buff[(reclen + 1) & intercept] <= 8'h02;  
								end
								cnt_data <= reclen + 32'd2;
							end
							3'd7:begin
								if(datpad == 8'h01) begin     //zeropadding 填充1个0
									buff[(reclen + 0) & intercept] <= 8'h00; 
								end
								else begin                    //pkcs7padding 填充1个1
									buff[(reclen + 0) & intercept] <= 8'h01;  
								end
								cnt_data <= reclen + 32'd1;
							end
						endcase
					end
				end
			end
			//----------
		end

		
	end
	else begin
		cnt_data <= 32'd0;
		recendf <= 1'b0;
	end
end

//对接收的数据进行处理
always @(posedge SCLK or posedge CS) begin
	if (CS == 1'b1) begin
		cnt_handata <= 32'd0;
		wflag <= 1'b0;
	end
	else if (state == s2) begin
		if(work == 8'h11 || work == 8'h12 || work == 8'h21 || work == 8'h22) begin
			if(cnt_handata + 32'd8 <= cnt_data) begin
			//$display("data handle");
				wflag <= 1'b1;
				if(work == 8'h11) begin //ECB加密
					desmode <= 1'b1;
					deskey <= {key[0],key[1],key[2],key[3],key[4],key[5],key[6],key[7]};
					desin <= {buff[(cnt_handata + 0) & intercept],buff[(cnt_handata + 1) & intercept],buff[(cnt_handata + 2) & intercept],buff[(cnt_handata + 3) & intercept],
							  buff[(cnt_handata + 4) & intercept],buff[(cnt_handata + 5) & intercept],buff[(cnt_handata + 6) & intercept],buff[(cnt_handata + 7) & intercept]};
					cnt_handata <= cnt_handata + 32'd8;
				end
				else if (work == 8'h12) begin //ECB解密
					//$display("ECB DE handle");
					desmode <= 1'b0;
					deskey <= {key[0],key[1],key[2],key[3],key[4],key[5],key[6],key[7]};
					desin <= {buff[(cnt_handata + 0) & intercept],buff[(cnt_handata + 1) & intercept],buff[(cnt_handata + 2) & intercept],buff[(cnt_handata + 3) & intercept],
							  buff[(cnt_handata + 4) & intercept],buff[(cnt_handata + 5) & intercept],buff[(cnt_handata + 6) & intercept],buff[(cnt_handata + 7) & intercept]};
					cnt_handata <= cnt_handata + 32'd8;
					//$display("ECB DE data=%h",{buff[cnt_handata + 0],buff[cnt_handata + 1],buff[cnt_handata + 2],buff[cnt_handata + 3],
							  //buff[cnt_handata + 4],buff[cnt_handata + 5],buff[cnt_handata + 6],buff[cnt_handata + 7]});
				end
				else if (work == 8'h21) begin //CBC加密
					if(cnt_handata == 32'd0) begin
						desmode <= 1'b1;
						deskey <= {key[0],key[1],key[2],key[3],key[4],key[5],key[6],key[7]};
						desin <= {buff[(cnt_handata + 0) & intercept],buff[(cnt_handata + 1) & intercept],buff[(cnt_handata + 2) & intercept],buff[(cnt_handata + 3) & intercept],
								  buff[(cnt_handata + 4) & intercept],buff[(cnt_handata + 5) & intercept],buff[(cnt_handata + 6) & intercept],buff[(cnt_handata + 7) & intercept]}
									^ 
									{vec[0],vec[1],vec[2],vec[3],vec[4],vec[5],vec[6],vec[7]};
						cnt_handata <= cnt_handata + 32'd8;
					end
					else begin
						desmode <= 1'b1;
						deskey <= {key[0],key[1],key[2],key[3],key[4],key[5],key[6],key[7]};
						desin <= {buff[(cnt_handata + 0) & intercept],buff[(cnt_handata + 1) & intercept],buff[(cnt_handata + 2) & intercept],buff[(cnt_handata + 3) & intercept],
								  buff[(cnt_handata + 4) & intercept],buff[(cnt_handata + 5) & intercept],buff[(cnt_handata + 6) & intercept],buff[(cnt_handata + 7) &intercept]}
								  ^ 
								 {buff2[(cnt_handata - 8) & intercept],buff2[(cnt_handata - 7) & intercept],buff2[(cnt_handata - 6) & intercept],buff2[(cnt_handata - 5) & intercept],
								  buff2[(cnt_handata - 4) & intercept],buff2[(cnt_handata - 3) & intercept],buff2[(cnt_handata - 2) & intercept],buff2[(cnt_handata - 1) & intercept]};
						cnt_handata <= cnt_handata + 32'd8;
					end
				end
				else if (work == 8'h22) begin //CBC解密
				 	desmode <= 1'b0;
					deskey <= {key[0],key[1],key[2],key[3],key[4],key[5],key[6],key[7]};
					desin <= {buff[(cnt_handata + 0) & intercept],buff[(cnt_handata + 1) & intercept],buff[(cnt_handata + 2) & intercept],buff[(cnt_handata + 3) & intercept],
							  buff[(cnt_handata + 4) & intercept],buff[(cnt_handata + 5) & intercept],buff[(cnt_handata + 6) & intercept],buff[(cnt_handata + 7) & intercept]};
					if(cnt_handata == 32'd0) begin
						cbccyc <= {vec[0],vec[1],vec[2],vec[3],vec[4],vec[5],vec[6],vec[7]};
					end
					else begin
						cbccyc <= {buff[(cnt_handata - 8) & intercept],buff[(cnt_handata - 7) & intercept],buff[(cnt_handata - 6) & intercept],buff[(cnt_handata - 5) & intercept],
								   buff[(cnt_handata - 4) & intercept],buff[(cnt_handata - 3) & intercept],buff[(cnt_handata - 2) & intercept],buff[(cnt_handata - 1) & intercept]};
					end
					cnt_handata <= cnt_handata + 32'd8;
				end
			end
			else begin
				wflag <= 1'b0;
			end
		end
		else begin
			wflag <= 1'b0;
		end
	end
	else begin
		wflag <= 1'b0;
		cnt_handata <= 32'd0;
	end
end

//存储处理后的数据
always @(posedge SCLK or posedge CS) begin
	if (CS == 1'b1) begin
		cnt_save <= 32'd0;
	end
	else if (state == s2) begin
		if(wflag == 1'b1) begin
			if(work == 8'h11 || work == 8'h12 || work == 8'h21) begin
				{buff2[(cnt_handata - 8) & intercept],buff2[(cnt_handata - 7) & intercept],buff2[(cnt_handata - 6) & intercept],buff2[(cnt_handata - 5) & intercept],
				 buff2[(cnt_handata - 4) & intercept],buff2[(cnt_handata - 3) & intercept],buff2[(cnt_handata - 2) & intercept],buff2[(cnt_handata - 1) & intercept]}
				 <= desout;
				cnt_save <= cnt_save + 32'd8;
				//$display("save=%h",desout);
			end
			else if (work == 8'h22) begin
				{buff2[(cnt_handata - 8) & intercept],buff2[(cnt_handata - 7) & intercept],buff2[(cnt_handata - 6) & intercept],buff2[(cnt_handata - 5) & intercept],
				 buff2[(cnt_handata - 4) & intercept],buff2[(cnt_handata - 3) & intercept],buff2[(cnt_handata - 2) & intercept],buff2[(cnt_handata - 1) & intercept]}
				 <= desout ^ cbccyc;
				cnt_save <= cnt_save + 32'd8;
				//$display("cbccyc=%h",cbccyc);
				//$display("cbc save=%h",(desout ^ cbccyc));
			end
			
			if(cnt_data >= reclen && cnt_handata == cnt_data) begin
				if(work == 8'h22) begin
					if(datpad == 8'h01) begin
						if(((desout ^ cbccyc) & 64'hffffffffffffffff) == 64'd0) begin
							cnt_save <= cnt_handata - 8;
						end
						else if(((desout ^ cbccyc) & 64'h00ffffffffffffff) == 64'd0) begin
							cnt_save <= cnt_handata - 7;
						end
						else if(((desout ^ cbccyc) & 64'h0000ffffffffffff) == 64'd0) begin
							cnt_save <= cnt_handata - 6;
						end
						else if(((desout ^ cbccyc) & 64'h000000ffffffffff) == 64'd0) begin
							cnt_save <= cnt_handata - 5;
						end
						else if(((desout ^ cbccyc) & 64'h00000000ffffffff) == 64'd0) begin
							cnt_save <= cnt_handata - 4;
						end
						else if(((desout ^ cbccyc) & 64'h0000000000ffffff) == 64'd0) begin
							cnt_save <= cnt_handata - 3;
						end
						else if(((desout ^ cbccyc) & 64'h000000000000ffff) == 64'd0) begin
							cnt_save <= cnt_handata - 2;
						end
						else if(((desout ^ cbccyc) & 64'h00000000000000ff) == 64'd0) begin
							cnt_save <= cnt_handata - 1;
						end
					end
					else begin
						cnt_save <= cnt_handata - ((desout ^ cbccyc) & 64'h00000000000000ff);
					end
				end
				else if(work == 8'h12) begin
					if(datpad == 8'h01) begin
						if((desout & 64'hffffffffffffffff) == 64'd0) begin
							cnt_save <= cnt_handata - 8;
						end
						else if((desout & 64'h00ffffffffffffff) == 64'd0) begin
							cnt_save <= cnt_handata - 7;
						end
						else if((desout & 64'h0000ffffffffffff) == 64'd0) begin
							cnt_save <= cnt_handata - 6;
						end
						else if((desout & 64'h000000ffffffffff) == 64'd0) begin
							cnt_save <= cnt_handata - 5;
						end
						else if((desout & 64'h00000000ffffffff) == 64'd0) begin
							cnt_save <= cnt_handata - 4;
						end
						else if((desout & 64'h0000000000ffffff) == 64'd0) begin
							cnt_save <= cnt_handata - 3;
						end
						else if((desout & 64'h000000000000ffff) == 64'd0) begin
							cnt_save <= cnt_handata - 2;
						end
						else if((desout & 64'h00000000000000ff) == 64'd0) begin
							cnt_save <= cnt_handata - 1;
						end
					end
					else begin
						cnt_save <= cnt_handata - (desout & 64'h00000000000000ff);
					end
				end
			end
			
		end
		
//		if(work == 8'h12 || work == 8'h22) begin
//			if(cnt_data >= reclen && cnt_handata == cnt_data) begin //对解密数据去掉填充
//				if(work == 8'h12 || work == 8'h22) begin
//					//$display("move padding");
//					if(datpad == 8'h01) begin //去掉zeropadding
//						if({buff2[cnt_handata - 8],buff2[cnt_handata - 7],buff2[cnt_handata - 6],buff2[cnt_handata - 5],
//					 		buff2[cnt_handata - 4],buff2[cnt_handata - 3],buff2[cnt_handata - 2],buff2[cnt_handata - 1]} == 64'h00) begin
//							cnt_save <= cnt_handata - 8;
//						end
//						else if({buff2[cnt_handata - 7],buff2[cnt_handata - 6],buff2[cnt_handata - 5],
//								 buff2[cnt_handata - 4],buff2[cnt_handata - 3],buff2[cnt_handata - 2],buff2[cnt_handata - 1]} == 56'h00) begin
//							cnt_save <= cnt_handata - 7;
//						end
//						else if({buff2[cnt_handata - 6],buff2[cnt_handata - 5],
//								 buff2[cnt_handata - 4],buff2[cnt_handata - 3],buff2[cnt_handata - 2],buff2[cnt_handata - 1]} == 48'h00) begin
//							cnt_save <= cnt_handata - 6;
//						end
//						else if({buff2[cnt_handata - 5],
//								 buff2[cnt_handata - 4],buff2[cnt_handata - 3],buff2[cnt_handata - 2],buff2[cnt_handata - 1]} == 40'h00) begin
//							cnt_save <= cnt_handata - 5;
//						end
//						else if({buff2[cnt_handata - 4],buff2[cnt_handata - 3],buff2[cnt_handata - 2],buff2[cnt_handata - 1]} == 32'h00) begin
//							cnt_save <= cnt_handata - 4;
//						end
//						else if({buff2[cnt_handata - 3],buff2[cnt_handata - 2],buff2[cnt_handata - 1]} == 24'h00) begin
//							cnt_save <= cnt_handata - 3;
//						end
//						else if({buff2[cnt_handata - 2],buff2[cnt_handata - 1]} == 16'h00) begin
//							cnt_save <= cnt_handata - 2;
//						end
//						else if({buff2[cnt_handata - 1]} == 8'h00) begin
//							cnt_save <= cnt_handata - 1;
//						end
//					end
//					else begin //去掉pkcs7padding
//						cnt_save <= cnt_handata - buff2[cnt_handata - 1];
//						//$display("cnt_handata=%h",cnt_handata);
//						//$display("buff2=%h",buff2[cnt_handata - 1]);
//					end
//				end
//			end
//		end
	end
	else begin
		cnt_save <= 32'd0;
	end
end

//数据发送
always @(posedge SCLK or posedge CS) begin
	if (CS == 1'b1) begin
		cnt_send <= 32'd0;
		senf <= 1'b0;
		senstf <= 1'b0;
	end
	else if(state == s2) begin
		if(senflag == 1'b1) begin
			if(cnt_send == 32'd0 && cnt_save == 32'd0) begin
				sendata <= dumpy;
			end
			else if(cnt_send == 32'd0 && cnt_save > 32'd0) begin
				if(senstf == 1'b0) begin
					sendata <= 8'h01;
					senstf <= 1'b1;
					//$display("send=01");
				end
				else begin
					sendata <= buff2[cnt_send];
					cnt_send <= cnt_send + 32'd1;
					//$display("send=%h",buff2[cnt_send]);
				end
			end
			else if (cnt_send < cnt_save) begin
				sendata <= buff2[cnt_send & intercept];
				cnt_send <= cnt_send + 32'd1;
				//$display("send=%h",buff2[cnt_send]);
				if((cnt_send + 32'd1) == cnt_save) begin
					senf <= 1'b1;
				end
			end
			else begin
				sendata <= dumpy;
			end
		end
	end
	else begin
		if(senflag == 1'b1) begin
			sendata <= dumpy;
			senf <= 1'b0;
			cnt_send <= 32'd0;
		end
	end
end

endmodule
