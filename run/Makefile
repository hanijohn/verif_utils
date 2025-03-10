###################
DIR=

####################
UVM = 0
VERDI = 1
GUI = 0

ELAB_OPTS = -sverilog -debug_access+all

RUN_OPTS = 
GUI_OPTS = 

ifeq (${VERDI}, 1)
ELAB_OPTS += -kdb
endif

ifeq (${UVM}, 1)
ELAB_OPTS += -ntb_opts uvm
$(info Enabling UVM )
endif

ifeq (${GUI}, 1)
GUI_OPTS = -gui
endif
##################

# Verilog/SV filelist
TB_FILE_LIST = ../tb/tb.f

INCDIR_PATH = +incdir+../

#Top Module name
TOP="top"

##################

all : comp run

comp:
	vcs ${ELAB_OPTS} $(INCDIR_PATH) -f ${TB_FILE_LIST} -top ${TOP} -l vcs.log

run:
	./simv ${GUI_OPTS} ${RUN_OPTS} -l simv.log &

clean:
	\rm -rf csrc novas.conf simv simv.daidir ucli.key verdi* work/* *.log
