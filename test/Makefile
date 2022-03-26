SIM ?= GHDL
TOPLEVEL_LANG ?=vhdl
SIM_ARGS ?= --wave=results.ghw
COMPILE_ARGS = -frelaxed
EXTRA_ARGS = --std=08

include ../sources.mk
include ../SpaceWireCODEC/sources.mk

VHDL_SOURCES += $(addprefix ../SpaceWireCODEC/, $(SPACEWIRECODEC_SOURCES)) \
								$(addprefix ../, $(SPACEWIREROUTER_SOURCES)) \
								LinkTest.vhdl

TOPLEVEL = tester

MODULE = router_test

include $(shell cocotb-config --makefiles)/Makefile.sim
