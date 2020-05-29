`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:32:26 05/07/2020
// Design Name:   DES_Top2
// Module Name:   D:/Xilinx/ISE_PROJECTS/demo1/source/vt.v
// Project Name:  demo1
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: DES_Top2
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module vt;

	// Inputs
	reg SCLK;
	reg CS;
	reg MOSI;

	// Outputs
	wire MISO;
	
	reg  en;
	wire	[7:0] dout;
	reg	[7:0] din;
	wire	infl;
	wire	outfl;
	
	reg sin;
	wire sout;
	
	reg [7:0]  a[0:383];
	reg [7:0]  b[0:383];
	
	
	reg [15:0] cnt;
	
	reg [15:0] temp;
	

	// Instantiate the Unit Under Test (UUT)
	DES_Top2 uut (  //DES加解密模块
		.SCLK(SCLK), 
		.CS(CS), 
		.MOSI(MOSI), 
		.MISO(MISO)
	);
	
	
	
	
	SAU  s(     //向DES模块发送数据接收数据的模块
	.clk(SCLK),
	.en(en),
	.din(din),
	.sin(sin),
	.dout(dout),
	.sout(sout),
	.infl(infl),
	.outfl(outfl)
	);
	
	always @(sout) begin
		MOSI = sout;
	end
	
	always @(MISO) begin
		sin = MISO;
	end
	
	

	initial begin
		// Initialize Inputs
		SCLK = 0;
		cnt = 0;
		
		//测试ECB
		a[0] = 8'h11;//标识ECB加密
//		a[0] = 8'h12;//标识ECB解密
		
		a[1] = 8'h02;//数据填充格式 02 pkcs7,01 zero
		
		a[2] = 8'h30;//密钥
		a[3] = 8'h31;
		a[4] = 8'h32;
		a[5] = 8'h33;
		a[6] = 8'h34;
		a[7] = 8'h35;
		a[8] = 8'h36;
		a[9] = 8'h37;
		
		a[10] = 8'h00;
		a[11] = 8'h00;
		a[12] = 8'h00;
		a[13] = 8'h0d;//加密数据长度
//		a[13] = 8'h10;//解密数据长度
		
		a[14] = 8'h30;//加密数据
		a[15] = 8'h31;
		a[16] = 8'h32;
		a[17] = 8'h33;
		a[18] = 8'h34;
		a[19] = 8'h35;
		a[20] = 8'h36;
		a[21] = 8'h37;
		
		a[22] = 8'h30;
		a[23] = 8'h31;
		a[24] = 8'h32;
		a[25] = 8'h33;
		a[26] = 8'h34;
		
		//c5 0a d0 28 c6 da 98 00 ac ad ae 56 b6 73 d5 da
//		a[14] = 8'hc5;//解密数据
//		a[15] = 8'h0a;
//		a[16] = 8'hd0;
//		a[17] = 8'h28;
//		a[18] = 8'hc6;
//		a[19] = 8'hda;
//		a[20] = 8'h98;
//		a[21] = 8'h00;
//		
//		a[22] = 8'hac;
//		a[23] = 8'had;
//		a[24] = 8'hae;
//		a[25] = 8'h56;
//		a[26] = 8'hb6;
//		a[27] = 8'h73;
//		a[28] = 8'hd5;
//		a[29] = 8'hda;

/*		
		//测试CBC
		a[0] = 8'h22;//标识CBC加密
		
		a[1] = 8'h01;//数据填充格式 02 pkcs7,01 zero
		
		a[2] = 8'h30;//密钥
		a[3] = 8'h31;
		a[4] = 8'h32;
		a[5] = 8'h33;
		a[6] = 8'h34;
		a[7] = 8'h35;
		a[8] = 8'h36;
		a[9] = 8'h37;
		
		a[10] = 8'h30;//填充向量
		a[11] = 8'h31;
		a[12] = 8'h32;
		a[13] = 8'h33;
		a[14] = 8'h34;
		a[15] = 8'h35;
		a[16] = 8'h36;
		a[17] = 8'h37;
		
		a[18] = 8'h00;//数据长度
		a[19] = 8'h00;
		a[20] = 8'h00;
		a[21] = 8'h10;
		//a[21] = 8'h0d;//加密数据长度
		
		
		a[22] = 8'h38;//解密数据
		a[23] = 8'h8d;
		a[24] = 8'h44;
		a[25] = 8'hf8;
		a[26] = 8'hb0;
		a[27] = 8'hf7;
		a[28] = 8'h09;
		a[29] = 8'hc0;
		
		a[30] = 8'hcf;
		a[31] = 8'h09;
		a[32] = 8'hc2;
		a[33] = 8'h03;
		a[34] = 8'heb;
		a[35] = 8'h89;
		a[36] = 8'h6a;
		a[37] = 8'h57;
		
		
//		a[22] = 8'h30;//加密数据
//		a[23] = 8'h31;
//		a[24] = 8'h32;
//		a[25] = 8'h33;
//		a[26] = 8'h34;
//		a[27] = 8'h35;
//		a[28] = 8'h36;
//		a[29] = 8'h37;
//		
//		a[30] = 8'h30;
//		a[31] = 8'h31;
//		a[32] = 8'h32;
//		a[33] = 8'h33;
//		a[34] = 8'h34;

*/
		// Wait 100 ns for global reset to finish
		
		CS = 0;
		en = 1;
		#100;
		CS = 1;
		en = 0;
		#100;
		CS = 0;
		en = 1;
		din = 8'hff;
		
//		temp = 0;
//		repeat(256) begin
//			a[temp + 14] = 8'h30;
//			temp = temp + 1;
//		end
		
		repeat(1000) begin
			SCLK = 0;
			#100;
			SCLK = 1;
			#100;
		end
        
		// Add stimulus here

	end
	
	always @(posedge SCLK) begin
		if(infl == 1) begin
			din = a[cnt];
			cnt = cnt + 1;
		end
	end
	
	always @(posedge SCLK) begin
		if(outfl == 1) begin
			$write("%h",dout);
		end
	end
      
endmodule

