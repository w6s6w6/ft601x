`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/08 19:59:14
// Design Name: 
// Module Name: ft60x_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ft60x_top_stream(
// system control
input                  Rstn_i,//fpga reset
output                 USBSS_EN,//power enable    
// FIFO interface     
input                  CLK_i,
inout [31:0]           DATA_io,
inout [3:0]            BE_io,
input                  RXF_N_i,   // ACK_N
input                  TXE_N_i,
output reg             OE_N_o,
output reg             WR_N_o,    // REQ_N
output                 SIWU_N_o,
output reg             RD_N_o,
output                 WAKEUP_o,
output [1:0]           GPIO_o

);

assign USBSS_EN = 1'b1;    
assign WAKEUP_o = 1'b1;
assign GPIO_o   = 2'b00;    
assign SIWU_N_o = 1'b0;

wire rstn;

(*mark_debug = "true"*) wire [31:0] rd_data;
(*mark_debug = "true"*) wire [31:0] wr_data;
(*mark_debug = "true"*) (* KEEP = "TRUE" *) wire [3 :0] BE_RD;
(*mark_debug = "true"*) wire [ 3:0] BE_WR;
(*mark_debug = "true"*) reg [1:0] USB_S;

//read or write flag
assign rd_data  =  (USB_S==2'd1) ? DATA_io : 32'd0;//read data dir
assign DATA_io  =  (USB_S==2'd2) ? wr_data : 32'bz;// write data dir
assign BE_RD    =  (USB_S==2'd1) ? BE_io   : 4'd0;
assign BE_io    =  (USB_S==2'd2) ? BE_WR   : 4'bz;// write data dir
assign BE_WR    =  4'b1111;


reg [7:0]wr_cnt;

assign wr_data = {wr_cnt,wr_cnt,wr_cnt,wr_cnt};

always @(posedge CLK_i)begin
    if(!rstn)begin
        wr_cnt <= 8'd0;
    end 
    else if(WR_N_o) begin
        wr_cnt <= wr_cnt + 1'b1;
    end
end

always @(posedge CLK_i)begin
    if(!rstn)begin
        USB_S <= 2'd0;
        OE_N_o <= 1'b1;
        RD_N_o <= 1'b1; 
        WR_N_o <= 1'b1; 
    end 
    else begin
        case(USB_S)
        0:begin
            OE_N_o <= 1'b1;
            RD_N_o <= 1'b1; 
            WR_N_o <= 1'b1; 
            if((!RXF_N_i)) begin
                USB_S  <= 2'd1;
                OE_N_o <= 1'b0;   
            end
            else if(!TXE_N_i)begin
                USB_S  <= 2'd2;
            end
        end
        1:begin
            RD_N_o <= 1'b0;   
            if(RXF_N_i) begin
                USB_S  <= 2'd0;
                RD_N_o <= 1'b1;
                OE_N_o <= 1'b1;      
            end
        end
        2:begin
            WR_N_o <= 1'b0; 
            if(TXE_N_i) begin
                USB_S  <= 2'd0;
                WR_N_o <= 1'b1; 
             end
        end
        3:begin
            USB_S <= 2'd0;
        end
        endcase                 
    end
end


Delay_rst #(
    .num(20'hffff0)
)
Delay_rst_inst
(
    .clk_i(CLK_i),
    .rstn_i(Rstn_i),
    .rst_o(rstn) 
 );

   
endmodule
