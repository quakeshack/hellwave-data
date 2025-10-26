
BASEDIR := ../id1
GAMEDIR := .

MAPS := $(wildcard $(GAMEDIR)/maps/*.map)
BSP_FILES := $(MAPS:.map=.bsp)

TOOLS_DIR := ../../../tools/ericw-tools
QBSP := $(TOOLS_DIR)/qbsp
VIS := $(TOOLS_DIR)/vis
LIGHT := $(TOOLS_DIR)/light

LMSCALE=8
LGRIDSIZE=-lightgrid_dist 16 16 16
QUALITY=-extra4

all: $(BSP_FILES)

%.bsp: %.map
	$(QBSP) -basedir $(BASEDIR) -gamedir $(GAMEDIR) -transwater -litwater -splitturb -nosoftware -bsp2 $<
	$(VIS) -basedir $(BASEDIR) -gamedir $(GAMEDIR) -noambientwater -noambientslime -noambientlava $<
	$(LIGHT) -basedir $(BASEDIR) -gamedir $(GAMEDIR) -bspxonly -bspx -novanilla -wrnormals -lightmap_scale $(LMSCALE) -lightgrid $(LGRIDSIZE) $(QUALITY) $<

clean:
	rm -f $(GAMEDIR)/maps/*.bsp
