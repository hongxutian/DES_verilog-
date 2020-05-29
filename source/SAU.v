`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:13:34 05/07/2020 
// Design Name: 
// Module Name:    SAU 
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
module SAU(
	input 								clk,
	input									en,
	input 			[7:0]				din,
	input									sin,
	output	reg	[7:0]				dout,
	output	reg						sout,
	output	reg						infl,
	output	reg						outfl
    );
	 
reg 	[3:0] 	cnt;
reg	[7:0]    doc;
reg	[7:0] 	dic;

//数据接收
always @(negedge clk,negedge en) begin
	if(en == 1'b0) begin
		doc <= 8'hff;
	end
	else begin
		doc[cnt] <= sin;
	end
end

always @(posedge clk,negedge en) begin
	if(en == 1'b0) begin
		dic <= 8'hff;
	end
	else if(cnt == 4'd7) begin
		dic <= din;
		//$display("dic=%h",din);
	end
end

//数据发送
always @(posedge clk,negedge en) begin
	if(en == 1'b0) begin
		sout <= 1'b1;
	end
	else begin
		sout <= dic[cnt];
		//$display("sout=%h",dic[cnt]);
	end
end

//调整接收位
always @(negedge clk,negedge en) begin
	if(en == 1'b0) begin
		cnt <= 4'd0;
	end
	else begin
		if(cnt >= 4'd7) begin
			cnt <= 4'd0;
		end
		else begin
			cnt <= cnt + 1;
		end
	end
end

//调整标志
always @(negedge clk,negedge en) begin
	if (en == 1'b0) begin
		infl <= 1'b0;
		outfl <= 1'b0;
		dout <= 8'h00;
	end
	else begin
		if(cnt == 4'd0) begin
			outfl <= 1'b1;
			dout <= doc;
		end
		else begin
			outfl <= 1'b0;
		end
		
		if(cnt == 4'd5) begin
			infl <= 1'b1;
		end
		else begin
			infl <= 1'b0;
		end
		
	end
end

endmodule
