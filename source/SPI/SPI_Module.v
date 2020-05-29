`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:57:50 04/26/2020 
// Design Name: 
// Module Name:    SPI_Module 
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
module SPI_Module(
	input 	wire				SCLK,
	output	reg				MISO,
	input		wire				CS,
	input		wire				MOSI,
	
	output   reg 	[7:0]    recdata,
	output	reg				recflag,
	
	input		wire	[7:0]		sendata,
	output	reg				senflag
				
    );

reg 				[3:0]					cnt_bit;
reg				[7:0]					rec_buff;
reg				[7:0]					sen_buff;

reg    									recendf;//接收完一个字节数据的标志				

//接收数据
always @(negedge SCLK,posedge CS) begin
	if(CS == 1'b1) begin
		rec_buff <= 8'h00;
	end
	else begin
		rec_buff[cnt_bit] <= MOSI;
		//$display("MOSI= %h",MOSI);
	end
end

//调整位
always @(negedge SCLK,posedge CS) begin
	if(CS == 1'b1) begin
		cnt_bit <= 4'd0;
		recendf <= 1'b0;
	end
	else if (cnt_bit >= 4'd7) begin
		cnt_bit <= 4'd0;
		recendf <= 1'b1;
	end
	else begin
		cnt_bit <= cnt_bit + 4'd1;
		recendf <= 1'b0;
	end
end

//将接收到的数据送到其他模块
always @(posedge SCLK,posedge CS) begin
	if(CS == 1'b1) begin
		recflag <= 1'b0;
		recdata <= 8'b0;
	end
	else if(recendf == 1'b1) begin
		recflag <= 1'b1;
		recdata <= rec_buff;
		//$display("spi get = %h",rec_buff);
	end
	else begin
		recflag <= 1'b0;
		//recdata <= 8'b0;
	end
end

//发送数据
always @(posedge SCLK,posedge CS) begin
	if(CS == 1'b1) begin
		MISO <= 1'b1;
	end
	else begin
		MISO <= sen_buff[cnt_bit];
		//$display("sen_pin=%h",sen_buff[cnt_bit]);
	end
end

//发送完一个字节数据的标志
always @(posedge SCLK,posedge CS) begin
	if(CS == 1'b1) begin
		senflag <= 1'b0;
	end
	else if(cnt_bit == 4'd5) begin
		senflag <= 1'b1;
	end
	else begin
		senflag <= 1'b0;
	end
end

always @(posedge SCLK,posedge CS) begin
	if(CS == 1'b1) begin
		sen_buff <= 8'hff;
	end
	else if(cnt_bit == 4'd7) begin
		sen_buff <= sendata;
		//$display("sen_buff=%h",sendata);
	end
end

endmodule
