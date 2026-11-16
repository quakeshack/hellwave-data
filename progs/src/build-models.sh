#!/usr/bin/env bash
# Rebuilds Hellwave's player and weapon models (IQM) from the LibreQuake sources into progs/.
#
#   LQ=/path/to/LibreQuake TOOLS=/path/to/qs-tools/blender progs/src/build-models.sh
#
# Needs Blender 5.x. The exporters are in the qs-tools repository (blender/README.md explains every option).
#
# progs/src/grips/*.json place a weapon in the hand: where it sits in the space of the player's `tag_weapon`
# (or `tag_axe`). They started as the output of qs-tools' fit_grip.py (the world model fitted onto the gun that is
# built into the LibreQuake player) and are meant to be adjusted by hand: translation, rotation in degrees, scale.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LQ="${LQ:-$here/../../../../../LibreQuake}"
TOOLS="${TOOLS:-$here/../../../../../tools/qs-tools/blender}"
progs="$here/.."
sources="$LQ/lq1/progs/src"

run() {
  blender -b "$1" --python-exit-code 1 --python "$TOOLS/$2" -- "${@:3}"
}

# The player: the built-in gun, axe and flash are cut out, their bones are the tags the weapons hang on. The rig's own
# `flash` bone is not a tag: every weapon model has its muzzle tag, and the engine looks at the player's own first.
run "$sources/player.mdl.blend" export_iqm.py \
  --output "$progs/player.iqm" --frames "$LQ/qcsrc/player.qc" --loop stand,axstnd,axrun,rockrun \
  --normals smooth --material-prefix progs/ \
  --strip-groups playergun,playeraxe,flash \
  --tag playergun=tag_weapon --tag playeraxe=tag_axe \
  --colormap "$LQ/lq1/gfx/palette.lmp"

# The weapons: a model name, the LibreQuake world model it is made from, and whether it has a muzzle.
weapon() {
  local name="$1" source="$2"
  shift 2
  run "$sources/$source.mdl.blend" export_attachment.py \
    --output "$progs/$name.iqm" --grip "$here/grips/$name.json" --normals smooth --material-prefix progs/ "$@"
}

weapon p_shot1 g_shot1 --tag-muzzle tag_flash   # shotgun
weapon p_shot  g_shot  --tag-muzzle tag_flash   # super shotgun
weapon p_nail  g_nail  --tag-muzzle tag_flash   # nailgun
weapon p_nail2 g_nail2 --tag-muzzle tag_flash   # super nailgun
weapon p_rock  g_rock  --tag-muzzle tag_flash   # grenade launcher
weapon p_rock2 g_rock2 --tag-muzzle tag_flash   # rocket launcher
weapon p_light g_light --tag-muzzle tag_flash   # thunderbolt
weapon p_axe   g_axe                            # axe
