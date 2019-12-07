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
SCRIPT_NAME="$(basename "${0}")";
# get this scripts folder
#SCRIPT_FOLDER="$(cd $(dirname "${0}") && pwd -P)";


# ........................................................................... #
# version
TMP_PROGRAM_VERSION="1.0";


# ........................................................................... #
# script argument flags
TMP_OPTION_SESSION_TYPE="";
TMP_OPTION_SANDBOX_FOLDER="";
TMP_OPTION_EXTENSION_FOLDER="";
TMP_OPTION_EXTENSION_UUID="";
TMP_OPTION_EXTENSION_DEBUG_STATEMENT="";
TMP_OPTION_RESOLUTION="";

# genetic argument flags
TMP_OPTION_VERBOSE=0;
TMP_OPTION_QUIET=0;
TMP_OPTION_DEBUG=0;


# ........................................................................... #
# various command verbosity flags
TMP_MKDIR_VERBOSITY="";
TMP_LN_VERBOSITY="";
TMP_RM_VERBOSITY="";
TMP_LN_VERBOSITY="";


# ........................................................................... #
function usage {

  echo "
NAME:

  ${SCRIPT_NAME} - Launch debug gnome session sandboxed to specific folder
                   and install enable given extenion/

SYNOPSIS:

  ${SCRIPT_NAME} [options]

OPTIONS

  -x, --session-type <x11|wayland>
    required, xdg sessions type, either x11 or wayland

  -s, --sandbox-folder <folder>
    required, folder in which to create sandbox

  -e, --extension-folder <folder>
    required, folder containing extension, which will be symlinked

  -u, --extension-uuid <uuid>
    required, extension uuid

  -d, --extension-debug-statement <code statement>
    optional, ecmascript statement to enable extension debugging

  -r, --resolution <uuid>
    optional, screen resolution, applies only to X11 via xrandr
    format: <height>x<width>

  -v, --verbose
    optional, turn on verbose output

  -q, --quiet
    optional, be as quiet as possible

  --version
    print version

  -h, --help
    This help screen
";


}


# ........................................................................... #
function main {

  # process script command and arguments
  process_script_arguments "$@";

  # validate and set defaults
  validate_script_arguments_and_set_defaults;

  # create sandbox;
  create_sandbox;

  # launch sandbox
  launch_sandbox

}


# ........................................................................... #
# get script params and store them
function process_script_arguments {

  local short_args;
  local long_args;
  local processed_args;

  short_args="x: s: e: u: d: r:";
  short_args+="v q";
  short_args+="h";
  long_args="session-type: sandbox-folder: extension-folder: extension-uuid: ";
  long_args+="extension-debug-statement: resolution: ";
  long_args+="verbose quiet ";
  long_args+="version help";

  # if no arguments given print usage
  if [ $# -eq 0 ]; then
    # print usage to stderr since no valid command was provided
    usage 1>&2;
    echo "No commands or arguments given">&2;
    exit 2;
  fi

  # process the arguments, if failed then print out all unknown arguments
  # and exit with code 2
  processed_args=$(get_getopt "${short_args}" "${long_args}" "$@") \
  || {
    echo "Unknown argument(s) given: ${processed_args}"; \
    exit 2;
  }

  # set the processed arguments into the $@
  eval set -- "${processed_args}";

  # go over the arguments
  while [ $# -gt 0 ]; do
    case "${1}" in

      # store session type
      --session-type | -x )
        TMP_OPTION_SESSION_TYPE="${2}";
        shift;
        ;;

      # store sandbox folder
      --sandbox-folder | -s)
        TMP_OPTION_SANDBOX_FOLDER="${2}";
        shift;
        ;;

      # store extension dolder
      --extension-folder | -e)
        TMP_OPTION_EXTENSION_FOLDER="${2}";
        shift;
        ;;

      # store extension uuid
      --extension-uuid | -u)
        TMP_OPTION_EXTENSION_UUID="${2}";
        shift;
        ;;

      # store extension uuid
      --extension-debug-statement | -d)
        TMP_OPTION_EXTENSION_DEBUG_STATEMENT="${2}";
        shift;
        ;;

      # store resolution
      --resolution | -r)
        TMP_OPTION_RESOLUTION="${2}";
        shift;
        ;;

      # store verbose flag
      --verbose | -v)
        TMP_OPTION_VERBOSE=1;
        ;;

      # store quiet flag
      --quiet | -q)
        TMP_OPTION_QUIET=1;
        ;;

      # store debug flag
      --debug)
        TMP_OPTION_DEBUG=1;
        ;;

      # store version flag
      --version)
        print_version;
        exit;
        ;;

      # show usage and quit with code 0
      --help | -h)
        usage;
        exit 0;
        ;;

      # argument end marker
      --)
        # pop the marker of the stack
        shift;
        # there should not be any trailing arguments
        if [ "${#}" -gt 0 ]; then
          # print usage to stderr exit with code 2
          usage 1>&2;
          echo "Unknown arguments(s) given: $*">&2;
          exit 2;
        else
          # if it 0 then break the loop, so the shift at the end
          # of the for loop did not cause an error
          break;
        fi
        ;;

      # unknown argument: anything that starts with -
      -*)
          # print usage to stderr exit with code 2
          usage 1>&2;
          echo "Unknown argument(s) given: ${1}">&2;
          exit 2;
          ;;

      *)
        # print usage to stderr since no valid command was provided
        usage 1>&2;
        echo "No arguments given.">&2;
        exit 2;
        ;;
    esac
    shift;
  done

}


# ........................................................................... #
# validate the set script arguments and set all default values that are
# not set at the top of the script when variable containing them are declared
function validate_script_arguments_and_set_defaults {

  local msg;

  # check if sessions type is specied and either x11 or wayland
  # if not abort with respective message
  if [ "${TMP_OPTION_SESSION_TYPE}" == "" ]; then
    abort "Please specify session type using -x/--session-type" 1;
  else
    if   [ "${TMP_OPTION_SESSION_TYPE}" != "x11" ] \
      && [ "${TMP_OPTION_SESSION_TYPE}" != "wayland" ]; then
      abort "Please specify session type of either 'x11' or 'wayland'" 1;
    fi
  fi

  # check if sandbox folder is specified, if not abort with message
  if [ "${TMP_OPTION_SANDBOX_FOLDER}" == "" ]; then
    abort "Please specify sandbod folder using -s/--sandbox-folder" 1;
  fi

  # check if extension folder is specified, if not abort with message
  if [ "${TMP_OPTION_EXTENSION_FOLDER}" == "" ]; then
    abort "Please specify extension folder using -s/--extension-folder" 1;
  fi

  # check if extension uuid is specified, if not abort with message
  if [ "${TMP_OPTION_EXTENSION_UUID}" == "" ]; then
    abort "Please specify extension uuid using -u/--extension-uuid" 1;
  fi

  # if debug then turn on verbosity
  if [ ${TMP_OPTION_DEBUG} -eq 1 ]; then
    TMP_OPTION_VERBOSE=1;
  fi

  # if verbose the set gpg, rm, mkdir verbosity
  if [ ${TMP_OPTION_VERBOSE} -eq 1 ]; then
    TMP_MKDIR_VERBOSITY="--verbose";
    TMP_LN_VERBOSITY="--verbose";
    TMP_RM_VERBOSITY="--verbose";
  else
    TMP_MKDIR_VERBOSITY=""
    TMP_LN_VERBOSITY="";
    TMP_RM_VERBOSITY="";
  fi

  # if quiet, set verbosity to 0 and enforce the quietest options for
  # those utilities that have it
  if [ ${TMP_OPTION_QUIET} -eq 1 ]; then
    TMP_OPTION_VERBOSE=0;
    TMP_MKDIR_VERBOSITY=""
    TMP_LN_VERBOSITY="";
    TMP_RM_VERBOSITY="";
  fi

}

# ........................................................................... #
function create_sandbox {

  # ~~~~~ #
  # compose and make cache folder the at will contain the sandboxed extension
  export HOME="${TMP_OPTION_SANDBOX_FOLDER}";
  mkdir \
    ${TMP_MKDIR_VERBOSITY} \
    --parents \
    "${HOME}" \
  ;

  # ~~~~~ #
  # export and re-make xdg run time folder
  export XDG_RUNTIME_DIR="${TMP_OPTION_SANDBOX_FOLDER}/run";
  # delete run time folder first if it exist (need new one per run)
  rm \
    ${TMP_RM_VERBOSITY} \
    --recursive \
    --force \
    "${XDG_RUNTIME_DIR}" \
  ;
  mkdir \
    ${TMP_MKDIR_VERBOSITY} \
    --parents \
    "${XDG_RUNTIME_DIR}" \
  ;

  # ~~~~~ #
  # export and make xdg config folder
  export XDG_CONFIG_HOME="${TMP_OPTION_SANDBOX_FOLDER}/config";
  mkdir \
    ${TMP_MKDIR_VERBOSITY} \
    --parents \
    "${XDG_RUNTIME_DIR}" \
  ;

  # ~~~~~ #
  # export and make xdg data home folder
  export XDG_DATA_HOME="${TMP_OPTION_SANDBOX_FOLDER}/local";
  mkdir \
    ${TMP_MKDIR_VERBOSITY} \
    --parents \
    "${XDG_DATA_HOME}" \
  ;

  # ~~~~~ #
  # export and make xdg cache folder
  export XDG_CACHE_HOME="${TMP_OPTION_SANDBOX_FOLDER}/cache";
  mkdir \
    ${TMP_MKDIR_VERBOSITY} \
    --parents \
    "${XDG_CACHE_HOME}" \
  ;

  # ~~~~~ #
  # make gnome-shell extensions folder
  mkdir \
    ${TMP_MKDIR_VERBOSITY} \
    --parents \
    "${XDG_DATA_HOME}/gnome-shell/extensions" \
  ;

  # ~~~~~ #
  # symlink extensions to gnome-shell extensions folder
  ln \
    ${TMP_LN_VERBOSITY} \
    --force \
    --symbolic \
    --no-dereference \
    "${TMP_OPTION_EXTENSION_FOLDER}" \
    "${XDG_DATA_HOME}/gnome-shell/extensions/${TMP_OPTION_EXTENSION_UUID}" \
  ;

  # ~~~~~ #
  # export GSETTINGS_SCHEMA_DIR so it can be found
  export GSETTINGS_SCHEMA_DIR="${XDG_DATA_HOME}/gnome-shell/extensions/${TMP_OPTION_EXTENSION_UUID}/schemas";

}



# ........................................................................... #
function launch_sandbox {
  local i;

  # ~~~~~ #
  # store current display port
  OLD_DISPLAY="${DISPLAY}"
  # find next X11 display free socket number
  i=0;
  while [ -e /tmp/.X11-unix/X${i} ]; do
      i=$((i + 1))
  done
  NEW_DISPLAY=":${i}";

  # ~~~~~ #
  # export the DISPLAY variable so we can create a new dbus session
  DISPLAY="${NEW_DISPLAY}";
  # create new dbus socket and export it's address
  eval "$(dbus-launch --exit-with-session --sh-syntax)";
  # put DISPLAY variable back to no normal display
  DISPLAY="${OLD_DISPLAY}";

  # ~~~~~ #
  # prepare for gnome-shell launch
  args=()
  case "${TMP_OPTION_SESSION_TYPE}" in
    wayland)
      args=(--nested --wayland);
      ;;

    x11)
      # launch Xephyr without access control and set screen size
      # gnome shell resizes the screeen to size does not work
      #   -screen "${TMP_OPTION_RESOLUTION}" \
      Xephyr \
        -ac \
        "${NEW_DISPLAY}" \
        &
      DISPLAY="${NEW_DISPLAY}";
      args=(--x11)
      ;;
  esac

  # ~~~~~ #
  # https://gitlab.gnome.org/GNOME/gnome-shell/blob/master/src/main.c
  # https://developer.gnome.org/glib/unstable/glib-Miscellaneous-Utility-Functions.html#g-parse-debug-string
  export SHELL_DEBUG=all;

  # ~~~~~ #
  # clutter debug
  #export CLUTTER_SHOW_FPS=1

  # ~~~~~ #
  # mutter debug
  export MUTTER_DEBUG=1;
  #export MUTTER_DEBUG_NUM_DUMMY_MONITORS=1;
  #export MUTTER_DEBUG_DUMMY_MONITOR_SCALES=1;
  #export MUTTER_DEBUG_TILED_DUMMY_MONITORS=1;

  # ~~~~~ #
  # reset all the settings
  # dconf reset -f /  # Reset settings
  # enable the extension
  dconf write \
    /org/gnome/shell/enabled-extensions \
    "['${TMP_OPTION_EXTENSION_UUID}']" \
  ;

  # ~~~~~ #
  # hack to work around gnome resizing Xephyr screen
  # gnome-shell claims monitors.xml has an invalid mode, could not use it
  # even thought it was generated inside the Xephyr window
  # ----
  # enable job control so we can background gnome-shell to launch additional
  # commands
  set -m;

  # ~~~~~ #
  # launch and background it
  gnome-shell "${args[*]}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' &
  # wait for 5 seconds for gnome to start up
  sleep 5;

  # ~~~~~ #
  # enable debug mode for the extension
  if [ "${TMP_OPTION_EXTENSION_DEBUG_STATEMENT}" != "" ]; then
    dbus-send \
      --session \
      --type=method_call \
      --dest=org.gnome.Shell \
      /org/gnome/Shell \
      org.gnome.Shell.Eval string:"
      ${TMP_OPTION_EXTENSION_DEBUG_STATEMENT}
      " \
    ;
  fi

  # ~~~~~ #
  # resize the Xephyr screen post gnome start up
  if [ "${TMP_OPTION_RESOLUTION}" != "" ]; then
    xrandr --size "${TMP_OPTION_RESOLUTION}" &
  fi

  # ~~~~~ #
  # launch dconf-editor
  dconf-editor &

  # ~~~~~ #
  # launch gnome-tweaks
  gnome-tweaks &

  # ~~~~~ #
  # go back to waiting on the gnome-shell process
  wait %1

}


# ........................................................................... #
# print out version
function print_version {
    echo "version: ${TMP_PROGRAM_VERSION}";
}


# ........................................................................... #
# return getopts line
# $1 {string} - getopt short opts
# $2 {integer} - getopt long opts
# $@ {string} - getopt options
function get_getopt {

    local short_opts=${1};
    local long_opts=${2};
    local getopt_error_message;
    shift 2;

    local opts="";

    # we do not use local here, since that operation would yield 0
    # return code, overwriting the getopt one
    opts=$(getopt -o "${short_opts}" -l "${long_opts}" -- "$@" 2>&1);
    # shellcheck disable=SC2181
    if [ $? != 0 ]; then
        # strip out header text for unrecognized and invalid options
        # and replace it with our own arguments text
        # strip out the single quotes surronding each quote
        getopt_error_message=$(\
            echo "$opts" \
            | head -n -1 \
            | sed "s/getopt: unrecognized option '//" \
            | sed "s/getopt: invalid option -- '/-/" \
            | sed "s/'$//" \
            | sed "s/\n//"
        );
        # replace newlines with spaces
        # shellcheck disable=SC2005,SC2116
        echo "$(echo "${getopt_error_message}")";
        return 1;

    fi

    echo "${opts}"
}


# ........................................................................... #
# print out message if verbosity is enabled
function log_verbose {
    local msg="${1}";
    if [ ${TMP_OPTION_VERBOSE} -eq 1 ]; then
        echo "${msg}";
    fi
}


# ........................................................................... #
# print out message if unless quiet is enabled
function log_unquiet {
    local msg="${1}";
    if [ ${TMP_OPTION_QUIET} -eq 0 ]; then
        echo "${msg}";
    fi
}


# ........................................................................... #
# echo out a given message and exit script with a give code
# $1 {string} - message to echo.
# $2 {integer} - exit code
function abort {

    local msg;
    local exit_code;
    local echo_opts="";

    if [ "x${1}" == "x-e" ]; then
        echo_opts="-e";
        shift;
    fi

    msg="${1}";
    local exit_code=${2};


    echo ${echo_opts} "${msg}
Aborting
" >&2;
    exit "${exit_code}";
}


# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
main "$@";
