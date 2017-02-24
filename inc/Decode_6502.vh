`define ADR_ABSx 3'b111
`define ADR_ABSy 3'b110
`define ADR_ZPGi 3'b101
`define ADR_INDy 3'b100
`define ADR_ABS  3'b011
`define ADR_IMM  3'b010
`define ADR_ZPG  3'b001
`define ADR_INDx 3'b000

`define OP_SBC 3'b111
`define OP_CMP 3'b110
`define OP_LD  3'b101
`define OP_ST  3'b100
`define OP_ADC 3'b011
`define OP_EOR 3'b010
`define OP_AND 3'b001
`define OP_ORA 3'b000

`define iDB_PCL	0
`define iDB_PCH	1
`define iDB_SB	2
`define iDB_DIR	3
`define iDB_ACC	4
`define iDB_PSR	5
`define iDB_ABH 6

`define SB_iDB	0
`define SB_ACC	1
`define SB_iX	2
`define SB_iY	3
`define SB_SP	4
`define SB_AOR	5

`define ADBL_AOR	3'd0
`define ADBL_PCL	3'd1
`define ADBL_DIR	3'd2
`define ADBL_IRQ	3'd3
`define ADBL_NMI	3'd4
`define ADBL_RESET	3'd5
`define ADBL_STACK	3'd6
`define ADBL_BUFFER	3'd7

`define ADBH_PCH	3'd0
`define ADBH_AOR	3'd1
`define ADBH_DIR	3'd2
`define ADBH_ZPG	3'd3
`define ADBH_STACK	3'd4
`define ADBH_VECTOR	3'd5
`define ADBH_BUFFER	3'd7

`define ALU_ADD		0
`define ALU_SUB		1
`define ALU_AND		2
`define ALU_ORA		3
`define ALU_EOR		4
`define ALU_PASS	5
`define ALU_INC		6
`define ALU_DEC		7
`define ALU_LSR		8
`define ALU_ASL		9
`define ALU_ROR		10
`define ALU_ROL		11

`define ALUB_ADL	0
`define ALUB_iDB	1
