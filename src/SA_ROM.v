module SA_ROM(
input  [6:0] code,
input  [3:0] line,
output reg [5:0] pattern);
	
always @ (*) begin
    pattern[5] = 1'b0;
	case(code[6:2])
	5'b010_00:case (line)
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b01010; 3:pattern[4:0]=5'b00110; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b01010; 3:pattern[4:0]=5'b01001; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b01010; 3:pattern[4:0]=5'b01000; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b11100; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b01000; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b01000; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b11111; endcase
		default: pattern[4:0] = 5'h00; endcase
	5'b010_01:case (line)
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b01110; 1:pattern[4:0]=5'b11000; 2:pattern[4:0]=5'b01000; 3:pattern[4:0]=5'b00100; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b10101; 1:pattern[4:0]=5'b11001; 2:pattern[4:0]=5'b10100; 3:pattern[4:0]=5'b00100; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b10100; 1:pattern[4:0]=5'b00010; 2:pattern[4:0]=5'b10100; 3:pattern[4:0]=5'b00100; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b01110; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b01000; 3:pattern[4:0]=5'b00000; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b00101; 1:pattern[4:0]=5'b01000; 2:pattern[4:0]=5'b10101; 3:pattern[4:0]=5'b00000; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b10101; 1:pattern[4:0]=5'b10011; 2:pattern[4:0]=5'b10010; 3:pattern[4:0]=5'b00000; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b01110; 1:pattern[4:0]=5'b00011; 2:pattern[4:0]=5'b01101; 3:pattern[4:0]=5'b00000; endcase
		default: pattern[4:0] = 5'h00; endcase
	5'b010_10:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b00010; 1:pattern[4:0]=5'b01000; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b00000; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b10101; 3:pattern[4:0]=5'b00100; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b01000; 1:pattern[4:0]=5'b00010; 2:pattern[4:0]=5'b01110; 3:pattern[4:0]=5'b00100; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b01000; 1:pattern[4:0]=5'b00010; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b11111; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b01000; 1:pattern[4:0]=5'b00010; 2:pattern[4:0]=5'b01110; 3:pattern[4:0]=5'b00100; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b10101; 3:pattern[4:0]=5'b00100; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b00010; 1:pattern[4:0]=5'b01000; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b00000; endcase
		default: pattern[4:0] = 5'h00; endcase
	5'b010_11:case (line)
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00001; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00010; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b01110; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00100; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b01000; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b10000; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b00000; endcase
		4'h7: case(code[1:0]) 0:pattern[4:0]=5'b01000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
		default: pattern[4:0] = 5'h00; endcase
	
	5'b011_00:case (line)
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b01110; 3:pattern[4:0]=5'b11111; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b01100; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b00001; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00001; 3:pattern[4:0]=5'b00010; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00110; 3:pattern[4:0]=5'b00110; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b01000; 3:pattern[4:0]=5'b00001; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b10000; 3:pattern[4:0]=5'b10001; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b01110; 2:pattern[4:0]=5'b11111; 3:pattern[4:0]=5'b01110; endcase
		default: pattern[4:0] = 5'h00; endcase
	5'b011_01:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b00010; 1:pattern[4:0]=5'b11111; 2:pattern[4:0]=5'b00110; 3:pattern[4:0]=5'b11111; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b00110; 1:pattern[4:0]=5'b10000; 2:pattern[4:0]=5'b01000; 3:pattern[4:0]=5'b00001; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b11110; 2:pattern[4:0]=5'b10000; 3:pattern[4:0]=5'b00010; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b10010; 1:pattern[4:0]=5'b00001; 2:pattern[4:0]=5'b11110; 3:pattern[4:0]=5'b00100; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b11111; 1:pattern[4:0]=5'b00001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b01000; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b00010; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b01000; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b00010; 1:pattern[4:0]=5'b01110; 2:pattern[4:0]=5'b01110; 3:pattern[4:0]=5'b01000; endcase
		default: pattern[4:0] = 5'h00; endcase
	5'b011_10:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b01110; 1:pattern[4:0]=5'b01110; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b00100; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b01110; 1:pattern[4:0]=5'b01111; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00001; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00010; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00100; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b01110; 1:pattern[4:0]=5'b01100; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b00100; endcase
		4'h7: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b01000; endcase
		default: pattern[4:0] = 5'h00; endcase
	5'b011_11:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b00010; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b01000; 3:pattern[4:0]=5'b01110; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b10001; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b01000; 1:pattern[4:0]=5'b11111; 2:pattern[4:0]=5'b00010; 3:pattern[4:0]=5'b00010; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00001; 3:pattern[4:0]=5'b00100; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b01000; 1:pattern[4:0]=5'b11111; 2:pattern[4:0]=5'b00010; 3:pattern[4:0]=5'b00100; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b00000; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b00010; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b01000; 3:pattern[4:0]=5'b00100; endcase
		default: pattern[4:0] = 5'h00; endcase
	
	5'b100_00:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b01110; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b11110; 3:pattern[4:0]=5'b01110; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b01010; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10001; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b10111; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10000; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b10101; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b11110; 3:pattern[4:0]=5'b10000; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b10111; 1:pattern[4:0]=5'b11111; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10000; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10001; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b01110; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b11110; 3:pattern[4:0]=5'b01110; endcase
		default: pattern[4:0] = 5'h00; endcase
	5'b100_01:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b11110; 1:pattern[4:0]=5'b11111; 2:pattern[4:0]=5'b11111; 3:pattern[4:0]=5'b01110; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10000; 2:pattern[4:0]=5'b10000; 3:pattern[4:0]=5'b10001; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10000; 2:pattern[4:0]=5'b10000; 3:pattern[4:0]=5'b10000; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b11110; 2:pattern[4:0]=5'b11110; 3:pattern[4:0]=5'b10000; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10000; 2:pattern[4:0]=5'b10000; 3:pattern[4:0]=5'b10011; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10000; 2:pattern[4:0]=5'b10000; 3:pattern[4:0]=5'b10001; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b11110; 1:pattern[4:0]=5'b11111; 2:pattern[4:0]=5'b10000; 3:pattern[4:0]=5'b01111; endcase
		default: pattern[4:0] = 5'h00; endcase
	5'b100_10:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b01110; 2:pattern[4:0]=5'b00001; 3:pattern[4:0]=5'b10001; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00001; 3:pattern[4:0]=5'b10010; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00001; 3:pattern[4:0]=5'b10100; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b11111; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00001; 3:pattern[4:0]=5'b11000; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00001; 3:pattern[4:0]=5'b10100; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10010; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b01110; 2:pattern[4:0]=5'b01110; 3:pattern[4:0]=5'b10001; endcase
		default: pattern[4:0] = 5'h00; endcase
	5'b100_11:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b01110; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b11011; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10001; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b10101; 2:pattern[4:0]=5'b11001; 3:pattern[4:0]=5'b10001; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b10101; 2:pattern[4:0]=5'b10101; 3:pattern[4:0]=5'b10001; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10011; 3:pattern[4:0]=5'b10001; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10001; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b11111; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b01110; endcase
		default: pattern[4:0] = 5'h00; endcase
	
	5'b101_00:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b11110; 1:pattern[4:0]=5'b01110; 2:pattern[4:0]=5'b11110; 3:pattern[4:0]=5'b01110; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10001; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10000; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b11110; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b11110; 3:pattern[4:0]=5'b01110; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b10101; 2:pattern[4:0]=5'b10100; 3:pattern[4:0]=5'b00001; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b10010; 2:pattern[4:0]=5'b10010; 3:pattern[4:0]=5'b10001; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b01101; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b01110; endcase
		default: pattern[4:0] = 5'h00; endcase
	5'b101_01:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b11111; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10001; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10001; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10001; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b01010; 3:pattern[4:0]=5'b10101; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b01010; 3:pattern[4:0]=5'b10101; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b10101; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b01110; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b01010; endcase
		default: pattern[4:0] = 5'h00; endcase
	5'b101_10:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b11111; 3:pattern[4:0]=5'b00000; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b00001; 3:pattern[4:0]=5'b00100; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b01010; 2:pattern[4:0]=5'b00010; 3:pattern[4:0]=5'b01000; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b11111; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b01000; 3:pattern[4:0]=5'b01000; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b10000; 3:pattern[4:0]=5'b00100; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b11111; 3:pattern[4:0]=5'b00000; endcase
		default: pattern[4:0] = 5'h00; endcase
	5'b101_11:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b01010; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b01010; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b00010; 2:pattern[4:0]=5'b01110; 3:pattern[4:0]=5'b11111; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b11111; 2:pattern[4:0]=5'b10101; 3:pattern[4:0]=5'b01010; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b10110; 1:pattern[4:0]=5'b00010; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b11111; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b00001; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b01010; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b00010; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b01010; endcase
		4'h7: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
		4'h8: case(code[1:0]) 0:pattern[4:0]=5'b00111; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
        default: pattern[4:0] = 5'h00; endcase
	
	5'b110_00:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b10000; 3:pattern[4:0]=5'b00000; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b10000; 3:pattern[4:0]=5'b00000; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b01110; 2:pattern[4:0]=5'b11110; 3:pattern[4:0]=5'b01111; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b11111; 1:pattern[4:0]=5'b00001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10000; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b01111; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10000; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10000; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b01111; 2:pattern[4:0]=5'b11110; 3:pattern[4:0]=5'b01111; endcase
        default: pattern[4:0] = 5'h00; endcase
	5'b110_01:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b00001; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00010; 3:pattern[4:0]=5'b00000; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b00001; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b00000; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b01111; 1:pattern[4:0]=5'b01110; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b01111; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b01110; 3:pattern[4:0]=5'b10001; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b11111; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b10001; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10000; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b10001; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b01111; 1:pattern[4:0]=5'b01110; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b01111; endcase
		4'h7: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00001; endcase
		4'h8: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b01110; endcase
        default: pattern[4:0] = 5'h00; endcase
	5'b110_10:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b01000; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b01000; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b11110; 1:pattern[4:0]=5'b01100; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b01001; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b01010; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b01100; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b01010; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b01110; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b01001; endcase
		4'h7: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b00000; endcase
		4'h8: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b01000; 3:pattern[4:0]=5'b00000; endcase
        default: pattern[4:0] = 5'h00; endcase
	5'b110_11:case (line) 
		4'h0: case(code[1:0]) 0:pattern[4:0]=5'b01100; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b11010; 2:pattern[4:0]=5'b11110; 3:pattern[4:0]=5'b01110; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b10101; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10001; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b10101; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10001; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b10101; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10001; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b01110; 1:pattern[4:0]=5'b10101; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b01110; endcase
        default: pattern[4:0] = 5'h00; endcase
	
	5'b111_00:case (line) 
        4'h0: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b11110; 1:pattern[4:0]=5'b01111; 2:pattern[4:0]=5'b01011; 3:pattern[4:0]=5'b01111; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b01100; 3:pattern[4:0]=5'b10000; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b01000; 3:pattern[4:0]=5'b01110; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b01000; 3:pattern[4:0]=5'b00001; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b11110; 1:pattern[4:0]=5'b01111; 2:pattern[4:0]=5'b01000; 3:pattern[4:0]=5'b11110; endcase
        4'h7: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b00001; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
        4'h8: case(code[1:0]) 0:pattern[4:0]=5'b10000; 1:pattern[4:0]=5'b00001; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
        default: pattern[4:0] = 5'h00; endcase
	5'b111_01:case (line)
        4'h0: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b01110; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10001; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b10001; 3:pattern[4:0]=5'b10001; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b01010; 3:pattern[4:0]=5'b10101; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b01010; 3:pattern[4:0]=5'b10101; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b00010; 1:pattern[4:0]=5'b01111; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b01010; endcase
        default: pattern[4:0] = 5'h00; endcase
	5'b111_10:case (line) 
        4'h0: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b01000; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b01000; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b11111; 3:pattern[4:0]=5'b01000; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b00010; 3:pattern[4:0]=5'b01000; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b00100; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b01001; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b10001; 2:pattern[4:0]=5'b01000; 3:pattern[4:0]=5'b00011; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b10001; 1:pattern[4:0]=5'b01111; 2:pattern[4:0]=5'b11111; 3:pattern[4:0]=5'b00101; endcase
        4'h7: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00001; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00111; endcase
        4'h8: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b01110; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00001; endcase
        default: pattern[4:0] = 5'h00; endcase
	5'b111_11:case (line) 
        4'h0: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b11000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b11111; endcase
		4'h1: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b11111; endcase
		4'h2: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b11000; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b11111; endcase
		4'h3: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b00100; 2:pattern[4:0]=5'b11111; 3:pattern[4:0]=5'b11111; endcase
		4'h4: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b11001; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b11111; endcase
		4'h5: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b10011; 2:pattern[4:0]=5'b00100; 3:pattern[4:0]=5'b11111; endcase
		4'h6: case(code[1:0]) 0:pattern[4:0]=5'b01010; 1:pattern[4:0]=5'b00101; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b11111; endcase
        4'h7: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00111; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
        4'h8: case(code[1:0]) 0:pattern[4:0]=5'b00000; 1:pattern[4:0]=5'b00001; 2:pattern[4:0]=5'b00000; 3:pattern[4:0]=5'b00000; endcase
        default: pattern[4:0] = 5'h00; endcase
    default: pattern[4:0] = 5'h00; endcase end
endmodule
