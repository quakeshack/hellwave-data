
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
BMODELFLAGS=-bspx -bmodelcontents
ADDMAPS=-add $(GAMEDIR)/maps/_hw_lights.map

# -bspxonly/-novanilla skip the vanilla lighting lump in favor of BSPX RGB data,
# which is required for BSP29/BSP2 (whose native lump is mono-only) but breaks
# Quake II output: Q2's native LIGHTING lump is already RGB, and there is no
# BSPX lightmap-equivalent lump for it to fall back to, so -novanilla silently
# leaves the compiled BSP38 with zero lighting data. Only apply them for Q1-family formats.
ifeq ($(FORMAT),q2bsp)
LIGHT_BSPXFLAGS=
else
LIGHT_BSPXFLAGS=-bspxonly -novanilla
endif

all: $(BSP_FILES) $(NAV_FILES)

%.bsp: %.map
	$(QBSP) -basedir $(BASEDIR) -gamedir $(GAMEDIR) $(FLAGS) $(ADDMAPS) -transwater -litwater -splitturb -nosoftware $(BMODELFLAGS) -$(FORMAT) $<
	$(VIS) -basedir $(BASEDIR) -gamedir $(GAMEDIR) $(FLAGS) -noambientwater -noambientslime -noambientlava $<
	$(LIGHT) -basedir $(BASEDIR) -gamedir $(GAMEDIR) $(FLAGS) $(LIGHT_BSPXFLAGS) -bspx -bspxlux -wrnormals -lightmap_scale $(LMSCALE) $(LGRID) $(LGRIDSIZE) $(QUALITY) $<

%.nav: %.map
	@mapname=$$(basename "$<" .map); \
	$(DEDICATED) -noserver -basedir $(notdir $(BASEDIR)) -game $(GAME) +nav_build_process 1 +map $$mapname

clean:
	rm -f $(GAMEDIR)/maps/*.bsp
