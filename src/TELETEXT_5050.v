module TELETEXT_5050(
    input       CLK,
    input       SA_F1,
    input       SA_T6,
    input       VSYNC,
    input       HSYNC,
    input       DISEN,
    input       CHAR_ROUND,
    input [6:0] DATABUS,
    output[2:0] RGB);

    wire [5:0] SA_dots;
    reg  [6:0] SA_code;
    reg  [3:0] SA_row;
    reg  [5:0] SA_shifter;

	wire HSYNC_DROP;
    SA_ROM char_rom(.code(SA_code),.line(SA_row),.pattern(SA_dots));
	Edge_Trigger #(0) hsync_neg(.CLK(CLK),.IN(HSYNC),.En(SA_F1),.EDGE(HSYNC_DROP));

    always @ (posedge CLK) begin
        if(SA_F1) begin
            SA_code    <= DATABUS;
            SA_shifter <= SA_dots;
        end else if(SA_T6) begin
            SA_shifter <= SA_shifter << 1;
        end
    end

    always @ (posedge CLK) if(SA_F1) begin
            if(VSYNC)     
            	SA_row <= 0;
            else if(HSYNC_DROP)
            	SA_row <= (SA_row == 9)? 0 : SA_row + 1;
    end

    assign RGB = DISEN? {3{SA_shifter[5]}} : 3'b000;

endmodule
