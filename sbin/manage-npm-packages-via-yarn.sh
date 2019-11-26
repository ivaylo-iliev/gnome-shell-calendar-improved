#!/usr/bin/env bash

# ########################################################################### #
#
# Manage NPM packages installation via Yarn
#
# ########################################################################### #


# ........................................................................... #
# error out on unset variables
set -o nounset;
# error out on first error
set -o errexit;
# error out on any errors that happen during pipe executions
set -o pipefail;
# debugging
#set -o xtrace;


# ........................................................................... #
# get this scripts file name
SCRIPT_NAME="$(basename ${0})"
# get this scripts folder
SCRIPT_FOLDER="$(cd $(dirname ${0}) && pwd -P)";


# ........................................................................... #
# version
TMP_PROGRAM_VERSION="1.0"


# ........................................................................... #
# script argument flags
TMP_OPTION_INSTALL=0;
TMP_OPTION_CLEAN=0;
TMP_OPTION_PACKAGES_SPECIFICATION_FOLDER="";
TMP_OPTION_APPLICATION_FOLDER="";
declare -a TMP_OPTION_SHIM_FILES;
TMP_OPTION_YARN_COMMAND="";
# genetic argument flags
TMP_OPTION_VERBOSE=0;
TMP_OPTION_QUIET=0;
TMP_OPTION_DEBUG=0;


# ........................................................................... #
# various command verbosity flags
TMP_YARN_VERBOSITY="";
TMP_RM_VERBOSITY="";
TMP_CHMOD_VERBOSITY="";


# ........................................................................... #
function usage {
  echo "
NAME:

  ${SCRIPT_NAME} - Manage NPM package installation via Yarn

SYNOPSIS:

  ${SCRIPT_NAME} [options]

OPTIONS

  -i, --install
    install npm packages and shims, can be used with --clean/-c

  -c, --clean
    remove the application folder and shims

  -p, --packages-specification-folder
    required for '--install', folder containing 'package.json' and
    'yarn.lock' specifying packages to install

  -a, --application-folder
    required, folder that will contain installation (i.e. 'node_modules')

  -s, --shim-file
    required, path where executable of shim will be placed to package script,
    can be specified multiple times

  -y, --yarn-path
    optional, path to yarn. defaults to 'yarn'

  -v, --verbose
    optional, turn on verbose output.

  -q, --quiet
    optional, be as quiet as possible.

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
  validate_and_set_default;

  # run install or run operation
  if [ ${TMP_OPTION_INSTALL} == 1 ]; then
    install_npm_packages_and_shims;
  elif [ ${TMP_OPTION_CLEAN} == 1 ]; then
    clean_npm_packages_and_shims;
  else
    echo "BUG: do nothing, you should have never seen this message">&2;
    exit 2;
  fi

}

# ........................................................................... #
# get script params and store them
function process_script_arguments {

  local short_args;
  local long_args;
  local processed_args;

  short_args="i c p: a: s: y: ";
  short_args+="v q";
  short_args+="h";
  long_args="install clean packages-specification-folder: ";
  long_args+="application-folder: shim-file: yarn-command: ";
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

      # set install option to 1
      --install | -i )
        TMP_OPTION_INSTALL=1;
        ;;

      # set clean option to 1
      --clean | -c )
        TMP_OPTION_CLEAN=1;
        ;;

      # store package specification folder path
      --packages-specification-folder | -p)
        TMP_OPTION_PACKAGES_SPECIFICATION_FOLDER="${2}";
        shift;
        ;;

      # store application folder path
      --application-folder | -a)
        TMP_OPTION_APPLICATION_FOLDER="${2}";
        shift;
        ;;

      # store shims
      --shim-file | -s)
        TMP_OPTION_SHIM_FILES+=("${2}");
        shift;
        ;;

      # store yarn command
      --yarn-command | -y)
        TMP_OPTION_YARN_COMMAND="${2}";
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
          echo "Unknown arguments(s) given: ${@}">&2;
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
function validate_and_set_default {

  local msg;

  # validate that we are doing either install or clean
  if [ ${TMP_OPTION_INSTALL} == 0 ] && [ ${TMP_OPTION_CLEAN} == 0 ]; then
      abort "Please specify either --install/-i or --clean/-c specified" 1;
  fi

  if [ ${TMP_OPTION_INSTALL} == 1 ]; then
    if [ "${TMP_OPTION_PACKAGES_SPECIFICATION_FOLDER}" == "" ]; then
      msg="Please specify folder containing package specification using ";
      msg+="-p/--packages-specification-folder";
      abort "${msg}" 1;
    fi
  fi

  # check if application folder is specified, if not abort with message
  if [ "${TMP_OPTION_APPLICATION_FOLDER}" == "" ]; then
    abort "Please specify output folder using -a/--application-folder" 1;
  fi

  # check if at least shim path is specified, if not abort with message
  if [ ${#TMP_OPTION_SHIM_FILES[@]} -eq 0 ]; then
      abort "Please specify at least one shim file using -s/--shim-file" 1;
  fi

  # check if yarn command is specified set to 'yarn'
  if [ "${TMP_OPTION_YARN_COMMAND}" == "" ]; then
    TMP_OPTION_YARN_COMMAND="yarn";
  fi

  # if debug then turn on verbosity
  if [ ${TMP_OPTION_DEBUG} -eq 1 ]; then
    TMP_OPTION_VERBOSE=1;
  fi

  # if verbose the set gpg, rm, mkdir verbosity
  if [ ${TMP_OPTION_VERBOSE} -eq 1 ]; then
    TMP_YARN_VERBOSITY="--verbose";
    TMP_RM_VERBOSITY="--verbose";
    TMP_CHMOD_VERBOSITY="--verbose";
  else
    TMP_YARN_VERBOSITY=""
    TMP_RM_VERBOSITY="";
    TMP_CHMOD_VERBOSITY="";
  fi

  # if quiet, set verbosity to 0 and enforce the quietest options for
  # those utilities that have it
  if [ ${TMP_OPTION_QUIET} -eq 1 ]; then
    TMP_OPTION_VERBOSE=0;
    TMP_YARN_VERBOSITY="--silent --no-progress"
    TMP_RM_VERBOSITY="";
    TMP_CHMOD_VERBOSITY="--silent";
  fi

}


# ........................................................................... #
# install npm packages using yarn
function install_npm_packages_and_shims {

  local output_shim_file;
  local not_clean;
  local msg;

  log_unquiet "install packages using yarn and create shims";

  not_clean=0;
  msg="";
  if [ ${TMP_OPTION_CLEAN} == 1 ]; then
    clean_npm_packages_and_shims;
  else
    # check if application folder already exists
    if [ -e "${TMP_OPTION_APPLICATION_FOLDER}" ]; then
      msg+="${TMP_OPTION_APPLICATION_FOLDER} already exists\n";
      not_clean=1;
    fi
    # check if any of the shims already exists
    for output_shim_file in "${TMP_OPTION_SHIM_FILES[@]}"; do
      if [ -e "${output_shim_file}" ]; then
        msg+="${output_shim_file} already exists\n";
        not_clean=1;
      fi
    done
    # if either of above exists then error out
    if [ ${not_clean} == 1 ]; then
      msg+="use --clean/-c option to remove existing packages and shims ";
      msg+="before install";
      abort -e "${msg}" 1;
    fi
  fi

  log_verbose "run 'yarn install'";
  "${TMP_OPTION_YARN_COMMAND}" install \
    ${TMP_YARN_VERBOSITY} \
    --modules-folder "${TMP_OPTION_APPLICATION_FOLDER}/node_modules" \
    --cwd "${TMP_OPTION_PACKAGES_SPECIFICATION_FOLDER}" \
  ;

  log_verbose "create shims";
  for output_shim_file in "${TMP_OPTION_SHIM_FILES[@]}"; do
    make_shim "${output_shim_file}";
  done

}


# ........................................................................... #
function make_shim {

  local output_shim_file="${1}";
  local target_shim_name="$(basename ${output_shim_file})";
  local application_folder_path;
  application_folder_path="${TMP_OPTION_APPLICATION_FOLDER}";

  cat << __EOF | sed 's/^  //g' > "${output_shim_file}"
  #!/usr/bin/env bash

  # can not use yarn run with --modules-folder so export NODE_PATH
  # https://github.com/yarnpkg/yarn/issues/1684#issuecomment-350964052
  export NODE_PATH="${application_folder_path}/node_modules";

  # run shim
  exec "${application_folder_path}/node_modules/.bin/${target_shim_name}" \\
    "\$@" \\
  ;
__EOF

  log_verbose "make shim executable";
  chmod \
    ${TMP_CHMOD_VERBOSITY} \
    +x  \
    "${output_shim_file}" \
  ;

}

# ........................................................................... #
function clean_npm_packages_and_shims {

  local output_shim_file;
  local msg;

  msg="remove packages installation folder: ";
  msg+="${TMP_OPTION_APPLICATION_FOLDER}";
  log_unquiet "${msg}";
  rm \
    ${TMP_RM_VERBOSITY} \
    -r \
    -f \
    "${TMP_OPTION_APPLICATION_FOLDER}" \
  ;

  log_verbose "remove shims";
  for output_shim_file in "${TMP_OPTION_SHIM_FILES[@]}"; do
    clean_shim "${output_shim_file}";
  done

}


# ........................................................................... #
function clean_shim {

  local output_shim_file="${1}";

  log_unquiet "remove shim ${output_shim_file}";
  rm \
    ${TMP_RM_VERBOSITY} \
    -f \
    "${output_shim_file}" \
  ;

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
        echo $(echo "${getopt_error_message}");
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
    exit ${exit_code};
}


# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
main "$@";
