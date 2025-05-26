//------------------------------------------------------------------------------
// Title        : ft60x_top.v 
// Project      : FT601   
//------------------------------------------------------------------------------
// Author       : W.S.W 
//------------------------------------------------------------------------------
// Description  : 
// 2025-05-25   :  
//  
//             
//------------------------------------------------------------------------------
// Known issues & omissions:
// 
// 
//------------------------------------------------------------------------------


module ft60x_top (
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

(*mark_debug = "true"*) wire [31:0] FIFO_Din;
(*mark_debug = "true"*) wire [31:0] FIFO_Dout;
(*mark_debug = "true"*) (* KEEP = "TRUE" *) wire [3 :0] BE_RD;
(*mark_debug = "true"*) wire [ 3:0] BE_WR;
(*mark_debug = "true"*) wire FIFO_F,FIFO_V;
(*mark_debug = "true"*) reg [1:0] usb_state ;      // fsm 
(*mark_debug = "true"*) wire FIFO_WR, FIFO_RD;


assign FIFO_Din =  ( usb_state ==2'd1) ? DATA_io   : 32'd0;//read data dir
assign DATA_io  =  ( usb_state ==2'd2) ? FIFO_Dout : 32'bz;// write data dir
assign BE_RD    =  ( usb_state ==2'd1) ? BE_io   : 4'd0;
assign BE_io    =  ( usb_state ==2'd2) ? BE_WR   : 4'bz;// write data dir
assign BE_WR    =  4'b1111;


assign FIFO_WR    = (!RD_N_o)&&(!RXF_N_i);
assign FIFO_RD    = (!WR_N_o)&&(!TXE_N_i);


fifo_generator_0 your_instance_name (
  .clk(CLK_i),      // input wire clk
  .din(FIFO_Din),      // input wire [31 : 0] din
  .wr_en(FIFO_WR),  // input wire wr_en
  .rd_en(FIFO_RD),  // input wire rd_en
  .dout(FIFO_Dout),    // output wire [31 : 0] dout
  .full(),    // output wire full
  .empty()  // output wire empty
);




always @(posedge CLK_i)begin
    if(!rstn)begin
        usb_state <= 2'd0;
        OE_N_o <= 1'b1;
        RD_N_o <= 1'b1; 
        WR_N_o <= 1'b1; 
    end 
    else begin
        case(usb_state)
        0:begin
            OE_N_o <= 1'b1;
            RD_N_o <= 1'b1; 
            WR_N_o <= 1'b1; 
            if((!RXF_N_i)) begin
                usb_state  <= 2'd1;
                OE_N_o <= 1'b0;   
            end
            else if(!TXE_N_i)begin
                usb_state  <= 2'd2;
            end
        end
        1:begin
            RD_N_o <= 1'b0;   
            if(RXF_N_i) begin
                usb_state  <= 2'd0;
                RD_N_o <= 1'b1;
                OE_N_o <= 1'b1;      
            end
        end
        2:begin
            WR_N_o <= 1'b0; 
            if(TXE_N_i) begin
                usb_state  <= 2'd0;
                WR_N_o <= 1'b1; 
             end
        end
        3:begin
            usb_state <= 2'd0;
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