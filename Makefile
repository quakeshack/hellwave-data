
GAME=hellwave
BASE=id1

BASEDIR := ../$(BASE)
GAMEDIR := .

MAPS := $(filter-out $(GAMEDIR)/maps/autosave.map %.autosave.map,$(wildcard $(GAMEDIR)/maps/*.map))
BSP_FILES := $(MAPS:.map=.bsp)
NAV_FILES := $(MAPS:.map=.nav)

DEDICATED := node --preserve-symlinks --preserve-symlinks-main ../../dedicated.mjs

TOOLS_DIR := ../../../tools/ericw-tools
QBSP := $(TOOLS_DIR)/qbsp
VIS := $(TOOLS_DIR)/vis
LIGHT := $(TOOLS_DIR)/light

FORMAT=bsp2
LMSCALE=8
LGRIDSIZE=-lightgrid_dist 16 16 16
LGRID=-lightgrid
QUALITY=-extra4
FLAGS=-lowpriority

all: $(BSP_FILES) $(NAV_FILES)

%.bsp: %.map
	$(QBSP) -basedir $(BASEDIR) -gamedir $(GAMEDIR) $(FLAGS) -transwater -litwater -splitturb -nosoftware -bspx -bmodelcontents -$(FORMAT) $<
	$(VIS) -basedir $(BASEDIR) -gamedir $(GAMEDIR) $(FLAGS) -noambientwater -noambientslime -noambientlava $<
	$(LIGHT) -basedir $(BASEDIR) -gamedir $(GAMEDIR) $(FLAGS) -bspxonly -bspx -novanilla -wrnormals -lightmap_scale $(LMSCALE) $(LGRID) $(LGRIDSIZE) $(QUALITY) $<

%.nav: %.map
	@mapname=$$(basename "$<" .map); \
	$(DEDICATED) -noserver -basedir $(notdir $(BASEDIR)) -game $(GAME) +nav_build_process 1 +map $$mapname

clean:
	rm -f $(GAMEDIR)/maps/*.bsp
