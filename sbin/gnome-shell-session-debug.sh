#!/usr/bin/env bash

# ########################################################################### #
#
#  Run extension Gnome Shell in nested Xephyr session or directly for Wayland
#
# ########################################################################### #

# ........................................................................... #
# turn on tracing of error, this will bubble up all the error codes
# basically this allows the ERR trap is inherited by shell functions
set -o errtrace;
# turn on quiting on first error
set -o errexit;
# error out on undefined variables
set -o nounset;
# propagate pipe errors
set -o pipefail;
# debugging
#set -o xtrace;


# ........................................................................... #
# get this scripts file name
SCRIPT_NAME=$(basename "${0}");
# get this scripts folder
SCRIPT_FOLDER="$(cd $(dirname ${0}); pwd -P)";


# ........................................................................... #
# version
TMP_PROGRAM_VERSION="1.0";


# ........................................................................... #
# get this scripts folder
SCRIPT_FOLDER="$(cd $(dirname ${0}); pwd -P)";


# ........................................................................... #
SIZE="1200x1000"


# ........................................................................... #
# store current display port
OLD_DISPLAY=$DISPLAY


# ........................................................................... #
# store positional parameters
TYPE=${1:-$XDG_SESSION_TYPE};
ROOT=$2;
UUID=$3;

SUFFIX="";

# ........................................................................... #
# find next X11 display free socket number
d=0
while [ -e /tmp/.X11-unix/X${d} ]; do
    d=$((d + 1))
done
NEW_DISPLAY=:$d


# ........................................................................... #
XDG_RUNTIME_DIR=$(mktemp -d);
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/${UUID}${SUFFIX}";
mkdir -p "${CACHE}";
export XDG_CONFIG_HOME="${CACHE}/config";
export XDG_DATA_HOME="${CACHE}/local";
mkdir -p "${XDG_DATA_HOME}/gnome-shell/extensions"
ln -fsn "${ROOT}" "${XDG_DATA_HOME}/gnome-shell/extensions/${UUID}";
export XDG_CACHE_HOME="${CACHE}/cache";
export GSETTINGS_SCHEMA_DIR="${XDG_DATA_HOME}/gnome-shell/extensions/${UUID}/schemas";

# ........................................................................... #
# export the DISPLAY variable so we can create a new dbus session
DISPLAY=$NEW_DISPLAY
# create new dbus socket and export it's address
eval $(dbus-launch --exit-with-session --sh-syntax)
echo $DBUS_SESSION_BUS_ADDRESS
DISPLAY=$OLD_DISPLAY


# ........................................................................... #
# prepare for gnome-shell launch
args=()
case "$TYPE" in
    wayland)
        args=(--nested --wayland)
        ;;
    x11)
        # launch Xephyr without access control and screen size of 1280x960
        Xephyr -ac -screen "${SIZE}" $NEW_DISPLAY &
        DISPLAY=$NEW_DISPLAY
        args=--x11
        ;;
esac


# ........................................................................... #
# dconf reset -f /  # Reset settings
dconf write /org/gnome/shell/enabled-extensions "['${UUID}']"


# ........................................................................... #
# preconfigure the environment for development
# set static workspaces[org/gnome/mutter]
#dconf write /org/gnome/shell/overrides/dynamic-workspaces false

# ........................................................................... #
# make sample calendar
#
mkdir \
  --parents \
  "${CACHE}/local/evolution/calendar/system" \
;
# generate sample calendar
"${SCRIPT_FOLDER}/../bin"/make_ical_calendar \
  "${CACHE}/local/evolution/calendar/system/calendar.ics" \
;
# delete existing ignored events
rm \
  -f \
  "${XDG_DATA_HOME}/gnome-shell/ignored_events";

# ........................................................................... #
# do not need FPS messages
#export CLUTTER_SHOW_FPS=1
export SHELL_DEBUG=all
export MUTTER_DEBUG=1
export MUTTER_DEBUG_NUM_DUMMY_MONITORS=1
export MUTTER_DEBUG_DUMMY_MONITOR_SCALES=1
export MUTTER_DEBUG_TILED_DUMMY_MONITORS=1


# ........................................................................... #
# hack to work around gnome resizing Xephyr screen
# gnome-shell claims monitors.xml has an invalid mode, could not use it
# even thought it was generated inside the Xephyr window
# ----
# enable job control so we can background gnome-shell to launch additional
# commands
set -m

# ........................................................................... #
# launch and background it
gnome-shell ${args[*]} 2>&1 | sed 's/\x1b\[[0-9;]*m//g' &
# wait for 5 seconds for gnome to start up
sleep 5;

# ........................................................................... #
# enable debug mode for the extension
dbus-send \
  --session \
  --type=method_call \
  --dest=org.gnome.Shell \
  /org/gnome/Shell \
  org.gnome.Shell.Eval string:'
  window.calendar_improved.debug = true;
  ' \
;

# ........................................................................... #
# resize the Xephyr screen post gnome start up
#xrandr --size "${SIZE}" &

# ........................................................................... #
# launch gnome-tweak
dconf-editor &

# ........................................................................... #
# launch gnome-tweak
gnome-tweaks &

# ........................................................................... #
# go back to waiting on the gnome-shell process
wait %1
