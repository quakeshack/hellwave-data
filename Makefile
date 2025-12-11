
GAME=hellwave

BASEDIR := ../id1
GAMEDIR := .

MAPS := $(filter-out %.autosave.map,$(wildcard $(GAMEDIR)/maps/*.map))
BSP_FILES := $(MAPS:.map=.bsp)
NAV_FILES := $(MAPS:.map=.nav)

TOOLS_DIR := ../../../tools/ericw-tools
QBSP := $(TOOLS_DIR)/qbsp
VIS := $(TOOLS_DIR)/vis
LIGHT := $(TOOLS_DIR)/light

LMSCALE=8
LGRIDSIZE=-lightgrid_dist 16 16 16
QUALITY=-extra4
FLAGS=-lowpriority

all: $(BSP_FILES) $(NAV_FILES)

%.bsp: %.map
	$(QBSP) -basedir $(BASEDIR) -gamedir $(GAMEDIR) $(FLAGS) -transwater -litwater -splitturb -nosoftware -bsp2 $<
	$(VIS) -basedir $(BASEDIR) -gamedir $(GAMEDIR) $(FLAGS) -noambientwater -noambientslime -noambientlava $<
	$(LIGHT) -basedir $(BASEDIR) -gamedir $(GAMEDIR) $(FLAGS) -bspxonly -bspx -novanilla -wrnormals -lightmap_scale $(LMSCALE) -lightgrid $(LGRIDSIZE) $(QUALITY) $<

%.nav: %.map
	@mapname=$$(basename "$<" .map); \
	../../dedicated.mjs -noserver -game $(GAME) +nav_build_process 1 +map $$mapname

clean:
	rm -f $(GAMEDIR)/maps/*.bsp
