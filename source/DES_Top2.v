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

//desģ������ݴ����ʽ
//1�����͸�ģ������ݸ�ʽ
//��ʶ+��������ʽ+��Կ+CBC ivƫ����+���ݳ���+����
//��ʶ��0x11 ECB���ܣ�0x12 ECB���ܣ�0x21 CBC���ܣ�0x22CBC����
//��������ʽ��0x01 zeropadding��0x02 pkcs7padding
//��Կ��8���ֽ�
//CBC ivƫ������8���ֽڣ�CBCģʽ��Ҫ���䣬ECBģʽ��Ҫ����
//���ݳ��ȣ�4���ֽڣ���λ�ֽ���ǰ
//���ݣ�ģ���������ݳ��ȹ涨�������ֽ���
//
//ע1�����ݷ�����Ϻ���Է���0xff��0xffΪ�����ַ���ģ�鲻�ᴦ������0xff�ȴ�ģ�鴦����ϣ�
//ģ����û����Ч���ݷ���ǰ�ᷢ��0xff,����Ч���ݷ���ʱ���ȷ���0x01������ʼ��Ȼ������Ч��
//�ݣ���Ч���ݷ������֮�󣬼�������0xff
//
//ע2��ģ�����SPIЭ�鴫�䣬����ʱʱ���ź�Ϊ�͵�ƽ����һ��ʱ�ӱ��ط������ݣ��������ط������ݣ���
//�ڶ���ʱ�ӱ��ؽ������ݣ����½��ؽ������ݣ�

module DES_Top2(
	input		wire						SCLK,
	input		wire						CS,
	input		wire						MOSI,
	output		wire						MISO
    );

parameter 		s0 = 8'd0,//����״̬
				s1 = 8'd1,//���ղ���
				s2 = 8'd2;//�������ݡ���������

parameter       dumpy = 8'hff;
parameter		intercept = 64'h000000000000001f;//���ƴ洢��Χ

reg 		[7:0]				state;//ģ���״̬

//SPIģ�������
wire							recflag;
wire		[7:0]				recdata;
wire							senflag;
reg			[7:0]				sendata;

//��żӽ�����Ҫ�õ�������
reg 							recpf;//����������ɱ�־λ
reg			[7:0] 				key [0:7];//��Կ
reg			[7:0]				vec [0:7];//����
reg			[7:0]				work;//����ģʽ���ӽ��ܣ�ECB CBC
reg			[7:0]          		datpad;//������䷽ʽ01 zero 02 pkcs7
reg			[31:0]				reclen;//���������ݵĳ���
reg			[7:0]				buff [0:31];//���ջ�����
reg			[7:0]				buff2 [0:31];//���ͻ�����

//���ݽ��յı�־
reg								cnt_pad;//�Ƿ����������ʽ
reg			[3:0]				cnt_key;//��������˶��ٸ��ֽڵ���Կ
reg			[3:0]				cnt_vec;//��������˶��ٸ��ֽڵ�����
reg			[3:0]				cnt_len;//��������˶��ٸ��ֽڵĴ��������ݳ���
reg			[31:0]				cnt_data;//��������˶��ٸ��ֽڵ�����

//DESģ�������
wire 		[1:64]				desout;//desģ������
reg			[1:64]				desin;//desģ�������
reg			[1:64]				deskey;//��Կ
reg								desmode;//����desģʽ��1���ܣ�0����


reg			[31:0]				cnt_handata;//���㴦���˶��ٸ�����
reg 		[31:0]				cnt_save;//����洢�˶��ٸ�����֮�������
reg         [31:0]				cnt_send;//���㷢���˶��ٴ���֮�������
reg 		 					wflag;//������8���ֽ����ݵı�־
reg			[1:64]				cbccyc;//CBC���ܵ��м����
reg 							senf;//���ݷ�����ɱ�־

reg 							recendf;//���ݽ�����ɱ�־

reg							senstf;//������Ч������ʼ��־�Ƿ��ѷ�

//SPIģ��
SPI_Module		spi1(.SCLK(SCLK),.CS(CS),.MOSI(MOSI),.MISO(MISO),.recdata(recdata),
						  .recflag(recflag),.sendata(sendata),.senflag(senflag));

//DESģ��
DES des1(.data_out(desout),.data_in(desin),.key(deskey),.mode(desmode));

//״̬�л�
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

//���ղ���
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
				else if(work == 8'h11 || work == 8'h12) begin //����ECB�ӽ��ܵ�����
					if(cnt_key < 4'd8) begin  //������Կ
						key[cnt_key] <= recdata;
						cnt_key <= cnt_key + 4'd1;
					end
					else if(cnt_len < 4'd4) begin  //�������ݳ���
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
				else if(work == 8'h21 || work == 8'h22) begin //����CBC�ӽ��ܵ�����
					if(cnt_key < 4'd8) begin //������Կ
						key[cnt_key] <= recdata;
						cnt_key <= cnt_key + 4'd1;
					end
					else if(cnt_vec < 4'd8) begin  //��������
						vec[cnt_vec] <= recdata;
						cnt_vec <= cnt_vec + 4'd1;
					end
					else if(cnt_len < 4'd4) begin  //�������ݳ���
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

//��������
always @(posedge SCLK or posedge CS) begin
	if (CS == 1'b1) begin
		cnt_data <= 32'd0;
		recendf <= 1'b0;
	end
	else if (state == s2) begin
		if (recflag == 1'b1) begin
			//----------
			if (work == 8'h11 || work == 8'h12 || work == 8'h21 || work == 8'h22) begin
				if(cnt_data < reclen) begin //��������
					//$display("data = %h",recdata);
					buff[cnt_data & intercept] <= recdata;
					cnt_data <= cnt_data + 32'd1;
				end
				if(recendf == 1'b0 && (cnt_data + 32'd1) == reclen) begin
					recendf <= 1'b1;
					if(work == 8'h11 || work == 8'h21) begin //�Լ���ģʽ�����������
						//$display("data padding");
						case(reclen[2:0])
							3'd0:begin
								if(datpad == 8'h01) begin     //zeropadding ���8��0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
									buff[(reclen + 2) & intercept] <= 8'h00; 
									buff[(reclen + 3) & intercept] <= 8'h00; 
									buff[(reclen + 4) & intercept] <= 8'h00; 
									buff[(reclen + 5) & intercept] <= 8'h00; 
									buff[(reclen + 6) & intercept] <= 8'h00; 
									buff[(reclen + 7) & intercept] <= 8'h00; 
								end
								else  begin                   //pkcs7padding ���8��8  
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
								if(datpad == 8'h01) begin      //zeropadding ���7��0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
									buff[(reclen + 2) & intercept] <= 8'h00; 
									buff[(reclen + 3) & intercept] <= 8'h00; 
									buff[(reclen + 4) & intercept] <= 8'h00; 
									buff[(reclen + 5) & intercept] <= 8'h00; 
									buff[(reclen + 6) & intercept] <= 8'h00; 
								end
								else begin                    //pkcs7padding ���7��7
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
								if(datpad == 8'h01) begin     //zeropadding ���6��0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
									buff[(reclen + 2) & intercept] <= 8'h00; 
									buff[(reclen + 3) & intercept] <= 8'h00; 
									buff[(reclen + 4) & intercept] <= 8'h00; 
									buff[(reclen + 5) & intercept] <= 8'h00; 
								end
								else begin                    //pkcs7padding ���6��6
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
								if(datpad == 8'h01) begin      //zeropadding ���5��0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
									buff[(reclen + 2) & intercept] <= 8'h00; 
									buff[(reclen + 3) & intercept] <= 8'h00; 
									buff[(reclen + 4) & intercept] <= 8'h00; 
								end
								else begin                     //pkcs7padding ���5��5
									buff[(reclen + 0) & intercept] <= 8'h05; 
									buff[(reclen + 1) & intercept] <= 8'h05; 
									buff[(reclen + 2) & intercept] <= 8'h05; 
									buff[(reclen + 3) & intercept] <= 8'h05; 
									buff[(reclen + 4) & intercept] <= 8'h05; 
								end
								cnt_data <= reclen + 32'd5;
							end
							3'd4:begin
								if(datpad == 8'h01) begin     //zeropadding ���4��0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
									buff[(reclen + 2) & intercept] <= 8'h00; 
									buff[(reclen + 3) & intercept] <= 8'h00; 
								end
								else begin                    //pkcs7padding ���4��4
									buff[(reclen + 0) & intercept] <= 8'h04; 
									buff[(reclen + 1) & intercept] <= 8'h04; 
									buff[(reclen + 2) & intercept] <= 8'h04; 
									buff[(reclen + 3) & intercept] <= 8'h04; 
								end
								cnt_data <= reclen + 32'd4;
							end
							3'd5:begin
								if(datpad == 8'h01) begin     //zeropadding ���3��0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
									buff[(reclen + 2) & intercept] <= 8'h00; 
								end
								else begin                    //pkcs7padding ���3��3
									buff[(reclen + 0) & intercept] <= 8'h03; 
									buff[(reclen + 1) & intercept] <= 8'h03; 
									buff[(reclen + 2) & intercept] <= 8'h03;  
								end
								cnt_data <= reclen + 32'd3;
							end
							3'd6:begin
								if(datpad == 8'h01) begin     //zeropadding ���2��0
									buff[(reclen + 0) & intercept] <= 8'h00; 
									buff[(reclen + 1) & intercept] <= 8'h00; 
								end
								else begin                    //pkcs7padding ���2��2
									buff[(reclen + 0) & intercept] <= 8'h02; 
									buff[(reclen + 1) & intercept] <= 8'h02;  
								end
								cnt_data <= reclen + 32'd2;
							end
							3'd7:begin
								if(datpad == 8'h01) begin     //zeropadding ���1��0
									buff[(reclen + 0) & intercept] <= 8'h00; 
								end
								else begin                    //pkcs7padding ���1��1
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

//�Խ��յ����ݽ��д���
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
				if(work == 8'h11) begin //ECB����
					desmode <= 1'b1;
					deskey <= {key[0],key[1],key[2],key[3],key[4],key[5],key[6],key[7]};
					desin <= {buff[(cnt_handata + 0) & intercept],buff[(cnt_handata + 1) & intercept],buff[(cnt_handata + 2) & intercept],buff[(cnt_handata + 3) & intercept],
							  buff[(cnt_handata + 4) & intercept],buff[(cnt_handata + 5) & intercept],buff[(cnt_handata + 6) & intercept],buff[(cnt_handata + 7) & intercept]};
					cnt_handata <= cnt_handata + 32'd8;
				end
				else if (work == 8'h12) begin //ECB����
					//$display("ECB DE handle");
					desmode <= 1'b0;
					deskey <= {key[0],key[1],key[2],key[3],key[4],key[5],key[6],key[7]};
					desin <= {buff[(cnt_handata + 0) & intercept],buff[(cnt_handata + 1) & intercept],buff[(cnt_handata + 2) & intercept],buff[(cnt_handata + 3) & intercept],
							  buff[(cnt_handata + 4) & intercept],buff[(cnt_handata + 5) & intercept],buff[(cnt_handata + 6) & intercept],buff[(cnt_handata + 7) & intercept]};
					cnt_handata <= cnt_handata + 32'd8;
					//$display("ECB DE data=%h",{buff[cnt_handata + 0],buff[cnt_handata + 1],buff[cnt_handata + 2],buff[cnt_handata + 3],
							  //buff[cnt_handata + 4],buff[cnt_handata + 5],buff[cnt_handata + 6],buff[cnt_handata + 7]});
				end
				else if (work == 8'h21) begin //CBC����
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
				else if (work == 8'h22) begin //CBC����
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

//�洢����������
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
//			if(cnt_data >= reclen && cnt_handata == cnt_data) begin //�Խ�������ȥ�����
//				if(work == 8'h12 || work == 8'h22) begin
//					//$display("move padding");
//					if(datpad == 8'h01) begin //ȥ��zeropadding
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
//					else begin //ȥ��pkcs7padding
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

//���ݷ���
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
