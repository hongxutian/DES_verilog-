`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:11:12 04/13/2020 
// Design Name: 
// Module Name:    SBox4 
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
module SBox4(
    input [1:6] data_in,
    output reg [1:4] data_out
    );

always @(data_in)
begin
	case({data_in[1],data_in[6],data_in[2:5]})
		6'd0 : data_out  = 4'd7;
		6'd1 : data_out  = 4'd13;
		6'd2 : data_out  = 4'd14;
		6'd3 : data_out  = 4'd3;
		6'd4 : data_out  = 4'd0;
		6'd5 : data_out  = 4'd6;
		6'd6 : data_out  = 4'd9;
		6'd7 : data_out  = 4'd10;
		6'd8 : data_out  = 4'd1;
		6'd9 : data_out  = 4'd2;
		6'd10 : data_out = 4'd8;
		6'd11 : data_out = 4'd5;
		6'd12 : data_out = 4'd11;
		6'd13 : data_out = 4'd12;
		6'd14 : data_out = 4'd4;
		6'd15 : data_out = 4'd15;
		6'd16 : data_out = 4'd13;
		6'd17 : data_out = 4'd8;
		6'd18 : data_out = 4'd11;
		6'd19 : data_out = 4'd5;
		6'd20 : data_out = 4'd6;
		6'd21 : data_out = 4'd15;
		6'd22 : data_out = 4'd0;
		6'd23 : data_out = 4'd3;
		6'd24 : data_out = 4'd4;
		6'd25 : data_out = 4'd7;
		6'd26 : data_out = 4'd2;
		6'd27 : data_out = 4'd12;
		6'd28 : data_out = 4'd1;
		6'd29 : data_out = 4'd10;
		6'd30 : data_out = 4'd14;
		6'd31 : data_out = 4'd9;
		6'd32 : data_out = 4'd10;
		6'd33 : data_out = 4'd6;
		6'd34 : data_out = 4'd9;
		6'd35 : data_out = 4'd0;
		6'd36 : data_out = 4'd12;
		6'd37 : data_out = 4'd11;
		6'd38 : data_out = 4'd7;
		6'd39 : data_out = 4'd13;
		6'd40 : data_out = 4'd15;
		6'd41 : data_out = 4'd1;
		6'd42 : data_out = 4'd3;
		6'd43 : data_out = 4'd14;
		6'd44 : data_out = 4'd5;
		6'd45 : data_out = 4'd2;
		6'd46 : data_out = 4'd8;
		6'd47 : data_out = 4'd4;
		6'd48 : data_out = 4'd3;
		6'd49 : data_out = 4'd15;
		6'd50 : data_out = 4'd0;
		6'd51 : data_out = 4'd6;
		6'd52 : data_out = 4'd10;
		6'd53 : data_out = 4'd1;
		6'd54 : data_out = 4'd13;
		6'd55 : data_out = 4'd8;
		6'd56 : data_out = 4'd9;
		6'd57 : data_out = 4'd4;
		6'd58 : data_out = 4'd5;
		6'd59 : data_out = 4'd11;
		6'd60 : data_out = 4'd12;
		6'd61 : data_out = 4'd7;
		6'd62 : data_out = 4'd2;
		6'd63 : data_out = 4'd14;
	endcase
end

endmodule
