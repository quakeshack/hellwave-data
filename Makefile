
BASEDIR := ../id1
GAMEDIR := .

MAPS := $(wildcard $(GAMEDIR)/maps/*.map)
BSP_FILES := $(MAPS:.map=.bsp)

TOOLS_DIR := ../../../tools/ericw-tools
QBSP := $(TOOLS_DIR)/qbsp
VIS := $(TOOLS_DIR)/vis
LIGHT := $(TOOLS_DIR)/light

all: $(BSP_FILES)

%.bsp: %.map
	$(QBSP) -basedir $(BASEDIR) -gamedir $(GAMEDIR) -transwater -litwater -splitturb $<
	$(VIS) -basedir $(BASEDIR) -gamedir $(GAMEDIR) $<
	$(LIGHT) -basedir $(BASEDIR) -gamedir $(GAMEDIR) -extra4 -bspx -novanilla -wrnormals $<

clean:
	rm -f $(GAMEDIR)/maps/*.bsp
