SRC=./src/
TEST=./tests/
BIN=./bin/
SIMDMP=./sim_dump/
INC=./inc
VPI=./vpi
VPIm=-m vpi_top

VC=iverilog
VCFLAGS=-Wall -Wno-timescale -Wno-implicit-dimensions -I$(INC) -t vvp -D SIMULATION

VI=vvp
VIFLAGS=-s -M $(VPI) $(VPIm)

R_OBJ=$(addprefix $(BIN), $(shell ls $(BIN) | grep '.*\.vvp$$'))
R_DMP=$(addprefix $(SIMDMP), $(shell ls $(SIMDMP) | grep '.*\.lxt$$'))
SRCF=$(addprefix $(SRC), $(shell ls $(SRC) | grep '.*\.v$$'))

bn=$(addsuffix $(2),$(basename $(1)))

.SECONDARY:

.PHONY: clear

%.vvp: $(TEST)%.v $(SRCF)
	$(VC) $(VCFLAGS) -s $(call bn,$@,) -o $(BIN)$@ \
	$(TEST)$(call bn,$@,.v) $(SRCF)

%.sim: $(BIN)%.vvp
	$(VI) $(VIFLAGS) $< -lxt\
	test -e dump.lxt && mv dump.lxt $(SIMDMP)$(call bn,$@,.lxt)

$(BIN)%.vvp: $(TEST)%.v $(SRCF)
	$(VC) $(VCFLAGS) -s $(call bn,$(notdir $@),) -o $@ \
	$(TEST)$(call bn,$(notdir $@),.v) $(SRCF)

clear:
	$(if $(or $(R_OBJ), $(R_DMP)), rm $(R_OBJ) $(R_DMP))
