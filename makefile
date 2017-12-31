################################################################################
#   Verilog makefile
################################################################################
VC      = iverilog
VCFLAGS = -Wall -Wno-timescale -Wno-implicit-dimensions -I$(HEAD) -t vvp \
          -y$(SRC) -D SIMULATION

VI      = vvp
VI_OUT  = lx2
VIFLAGS = -s $(addprefix -m,$(VPI_TGT))

VPI     = iverilog-vpi
VPIFLAGS= --name=$(basename $@)

CC          = gcc
VPI_CFLAGS := $(shell iverilog-vpi --cflags)
CFLAGS      = $(VPI_CFLAGS) -I$(VPIHEAD) -c -Wno-strict-prototypes -o $@

################################################################################

SRC     := ./src
VVP     := ./vvp
TESTS   := ./tests
SIMDMP  := ./sim_dump
HEAD    := ./head
VPISRC  := ./vpi_src
VPIOBJ  := ./vpi_obj
VPIBIN  := ./vpi_bin
VPIHEAD	:= ./vpi_head

get_file    =$(basename $(notdir $(1)))
make_target =$(addprefix $(1)/,$(call get_file,$(wildcard $(2)/*.$(3))))
get_module  =$(call get_file,$(1))

VPI_TGT := $(addsuffix .vpi,$(call make_target,$(VPIBIN),$(VPISRC),c))
VPI_OBJ := $(addsuffix .o,  $(call make_target,$(VPIOBJ),$(VPISRC),c))
VVP_TGT := $(addsuffix .vvp,$(call make_target,$(VVP),$(TESTS),v))
SIM_TGT := $(addsuffix .$(VI_OUT),$(call make_target,$(SIMDMP),$(TESTS),v))
HEADERS := $(wildcard $(HEAD)/*.vh)
SOURCES := $(wildcard $(SRC)/*.v)
VPI_HEAD:= $(wildcard $(VPIHEAD)/*.h)

################################################################################

.PHONY: clean

.SECONDARY:

all: $(SIM_TGT)

$(VVP):
	mkdir $(VVP)/

$(VPIBIN):
	mkdir $(VPIBIN)/

$(VPIOBJ):
	mkdir $(VPIOBJ)/

$(SIMDMP):
	mkdir $(SIMDMP)/

%.sim: $(SIMDMP)/%.$(VI_OUT);

$(SIMDMP)/%.$(VI_OUT): $(VVP)/%.vvp $(VPI_TGT) | $(SIMDMP)
	$(VI) $(VIFLAGS) $< -$(VI_OUT)
	$(if $(wildcard dump.$(VI_OUT)), mv dump.$(VI_OUT) $@)

$(VVP)/%.vvp: $(TESTS)/%.v $(SOURCES) $(HEADERS) | $(VVP)
	$(VC) $(VCFLAGS) -s $(call get_module,$<) -o $@ $<

$(VPIBIN)/%.vpi: $(VPIOBJ)/%.o | $(VPIBIN)
	$(VPI) $(VPIFLAGS) $<

$(VPIOBJ)/%.o: $(VPISRC)/%.c $(VPI_HEAD) | $(VPIOBJ)
	$(CC) $(CFLAGS) $<

clean:
	@rm -fv $(VPI_TGT) $(VPI_OBJ) $(VVP_TGT) $(SIM_TGT)
