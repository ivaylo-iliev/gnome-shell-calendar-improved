#!/usr/bin/env bash

# ########################################################################### #
#
#  Install poetry into it's own virtualenv and create a wrapper that is
#  has uses a custom configuration location in custom XDG_CONFIG_HOME until
#  https://github.com/sdispater/poetry/issues/618 is resolved.
#
#  Currently this only works on linux because XDG_CONFIG_HOME is only
#  supported there.
#  See: https://github.com/sdispater/poetry/blob/master/poetry/utils/appdirs.py#L93-L101
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
SCRIPT_NAME=$(basename "${0}");
SCRIPT_FOLDER="$(cd $(dirname ${0}) && pwd -P)";


# ........................................................................... #
TMP_PROGRAM_VERSION="1.0";


# ........................................................................... #
TMP_OPTION_INSTALL=0;
TMP_OPTION_CLEAN=0;
TMP_OPTION_POETRY_VERSION="";
TMP_OPTION_APPLICATION_FOLDER="";
TMP_OPTION_SHIM_FILE="";
TMP_OPTION_VIRTUALENV_COMMAND="virtualenv --quiet --no-download";
TMP_OPTION_PIP_ARGUMENTS="";
# genetic argument flags
TMP_OPTION_VERBOSE=0;
TMP_OPTION_QUIET=0;
TMP_OPTION_DEBUG=0;


# ........................................................................... #
# various command verbosity flags
TMP_VIRTUALENV_VERBOSITY="";
TMP_PIP_VERBOSITY="--quiet";
TMP_RM_VERBOSITY="";
TMP_CHMOD_VERBOSITY="";

# ........................................................................... #
# prefix of poetry, used in folder and file
# unlikely to change, currently just a re-usable variable
TMP_POETRY_PREFIX="poetry-"

# ........................................................................... #
# print script usage
function usage {
    echo "\
Usage: ${SCRIPT_NAME} [OPTIONS]

Options:

  -i, --install
    install poetry package and shim, can be used with --clean/-c

  -c, --clean
    remove the application folder and shim

  -e, --poetry-version <poetry version>
    required, version of poetry to manage

  -a, --application-folder <folder path>
    required, folder that will contain the installation

  -s, --shim-file <file path>
    required, path where executable of yarn shim will be placed.
    typically, inside project bin folder

  -l, --virtualenv-command <command, quoted>
    optional, virtualenv command to be used to create virtual environment for
    poetry install (when properly quoted can contain script arguments)
    defaults to '${TMP_OPTION_VIRTUALENV_COMMAND}'

  -p, --pip-arguments <arguments, quoted>
    optional, arguments pip install operation for poetry, can be used to
    specify pip configuration.

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
function begin {

  # process script arguments
  process_script_arguments "$@";

  # validate script arguments
  validate_script_arguments_and_set_defaults;

  if [ ${TMP_OPTION_INSTALL} == 1 ]; then
    install_poetry;
  elif [ ${TMP_OPTION_CLEAN} == 1 ]; then
    clean_poetry;
  else
    abort "BUG: do nothing, you should have never seen this message" 2;
  fi

}


# ........................................................................... #
# get script commands and argument and process them
function process_script_arguments {

  local short_args;
  local long_args="";
  local processed_args;

  short_args="i c a: e: s: l: p: ";
  short_args+="v q";
  short_args+="h";
  long_args+="install clean application-folder: poetry-version: ";
  long_args+="shim-file:  virtualenv-command: pip-arguments: ";
  long_args+="verbose quiet ";
  long_args+="version help";

  # if no arguments given print usage
  if [ $# -eq 0 ]; then
    # print usage to stderr since no valid command was provided
    usage 1>&2;
    echo "No arguments given">&2;
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

      # store poetry version value
      --poetry-version | -e )
        TMP_OPTION_POETRY_VERSION="${2}";
        shift;
        ;;

      # store application folder value
      --application-folder | -a )
        TMP_OPTION_APPLICATION_FOLDER="${2}";
        shift;
        ;;

      # store shim file value
      --shim-file | -s )
        TMP_OPTION_SHIM_FILE="${2}";
        shift;
        ;;

      # store virtualenv command value
      --virtualenv-command | -l )
        TMP_OPTION_VIRTUALENV_COMMAND="${2}";
        shift;
        ;;

      # store pip arguments value
      --pip-arguments | -p )
        TMP_OPTION_PIP_ARGUMENTS="${2}";
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
          echo "Unknown positional arguments(s) given: ${@}">&2;
          exit 2;
        else
          # if it 0 then break the loop, so the shift at the end
          # of the for loop did not cause an error
          break;
        fi
        ;;

      # unknown argument: anything that starts with -
      -*)
        # print usage to stderr since no valid command was provided
        usage 1>&2;
        echo "Unknown argument(s) given: ${@}">&2;
        exit 2;
        ;;

      *)
        # print usage to stderr since no valid command was provided
        usage 1>&2;
        echo "No argument given">&2;
        exit 2;
        ;;
    esac
    shift;
  done

}


# ........................................................................... #
function validate_script_arguments_and_set_defaults {

  local msg;

  # validate that we are doing either install or clean
  if [ ${TMP_OPTION_INSTALL} == 0 ] && [ ${TMP_OPTION_CLEAN} == 0 ]; then
    abort "please specify either --install/-i or --clean/-c" 1;
  fi

  # check if application folder is specified, if not abort with message
  if [ "${TMP_OPTION_APPLICATION_FOLDER}" == "" ]; then
    abort "please specify output folder using -a/--application-folder" 1;
  fi

  # check if shim file is specified, if not abort with message
  if [ "${TMP_OPTION_SHIM_FILE}" == "" ]; then
    abort "please specify shim file path using -s/--shim-file" 1;
  fi

  # validate options that are needed for install
  if [ ${TMP_OPTION_INSTALL} == 1 ]; then

    # validate that we have poetry version
    if [ "${TMP_OPTION_POETRY_VERSION}" == "" ]; then
      abort "please specify poetry version using --poetry-version/-e" 1;
    fi

  fi

  # if verbose the set gpg, rm, mkdir verbosity
  if [ ${TMP_OPTION_VERBOSE} -eq 1 ]; then
    TMP_VIRTUALENV_VERBOSITY="--verbose";
    TMP_PIP_VERBOSITY="--verbose";
    TMP_RM_VERBOSITY="--verbose";
    TMP_CHMOD_VERBOSITY="--verbose";
  else
    TMP_VIRTUALENV_VERBOSITY=""
    TMP_PIP_VERBOSITY="";
    TMP_RM_VERBOSITY="";
    TMP_CHMOD_VERBOSITY="";
  fi

  # if quiet, set verbosity to 0 and enforce the quietest options for
  # those utilities that have it
  if [ ${TMP_OPTION_QUIET} -eq 1 ]; then
    TMP_OPTION_VERBOSE=0;
    TMP_VIRTUALENV_VERBOSITY="--quiet"
    TMP_PIP_VERBOSITY="--quiet";
    TMP_RM_VERBOSITY="";
    TMP_CHMOD_VERBOSITY="--silent";
  fi


}


# ........................................................................... #
function clean_poetry {

  # remove existing application folder and shim
  rm \
    -r \
    -f \
    "${TMP_OPTION_APPLICATION_FOLDER}" \
    "${TMP_OPTION_SHIM_FILE}" \
  ;

  log_unquiet "removed ${TMP_OPTION_APPLICATION_FOLDER} folder";
  log_unquiet "removed ${TMP_OPTION_SHIM_FILE} shim";


}


# ........................................................................... #
function install_poetry {

  local application_folder_path;
  application_folder_path="${TMP_OPTION_APPLICATION_FOLDER}";
  application_folder_path+="/${TMP_POETRY_PREFIX}${TMP_OPTION_POETRY_VERSION}";

  local application_parent_folder="$(dirname ${TMP_OPTION_APPLICATION_FOLDER})"
  local xdg_folder="${application_folder_path}/config";
  local poetry_config_folder="${xdg_folder}/pypoetry";
  local not_clean=0;
  local msg;

  # verity output folder exists
  if [ ! -d "${application_parent_folder}" ]; then
    msg="application folder parent folder must already exist, since we can ";
    msg+="only remove the last folder in the applicaiton folder path"
    echo "${msg}">&2;
    exit 1;
  fi

  # if clean option specified then clean poetry
  if [ ${TMP_OPTION_CLEAN} == 1 ]; then
    clean_poetry;
  else
    # check if poetry folder already exists
    if [ -e "${application_folder_path}" ]; then
      echo "${application_folder_path} already exists">&2;
      not_clean=1;
    fi
    # check if shim file already exists
    if [ -e "${TMP_OPTION_SHIM_FILE}" ]; then
      echo "${TMP_OPTION_SHIM_FILE} already exists">&2;
      not_clean=1;
    fi
    # if either of above exists then error out
    if [ ${not_clean} == 1 ]; then
      msg="you can use --clean/-c option to remove existing poetry package ";
      msg+="and shim before install";
      abort "${msg}" 1;
    fi
  fi

  # create virtualenv folder
  ${TMP_OPTION_VIRTUALENV_COMMAND} \
    ${TMP_VIRTUALENV_VERBOSITY} \
    --prompt="(${TMP_POETRY_PREFIX}${TMP_OPTION_POETRY_VERSION})" \
    "${application_folder_path}" \
  ;

  # install poetry
  ${application_folder_path}/bin/pip \
    ${TMP_PIP_VERBOSITY} \
    install \
      ${TMP_OPTION_PIP_ARGUMENTS} \
      poetry==${TMP_OPTION_POETRY_VERSION} \
  ;

  # make config folder
  make_configs "${poetry_config_folder}";

  # make shim
  make_shim \
    "${TMP_OPTION_SHIM_FILE}" \
    "${application_folder_path}" \
    "${xdg_folder}" \
  ;

  log_unquiet "created ${TMP_OPTION_APPLICATION_FOLDER} folders";
  log_unquiet "created ${TMP_OPTION_SHIM_FILE} shim";

}

# ........................................................................... #
function make_configs {

  local poetry_config_folder="${1}";

  # create poetry config folder
  mkdir \
    -p \
    "${poetry_config_folder}" \
  ;

  # create poetry config file
  cat << __EOF | sed 's/^  //g' > "${poetry_config_folder}/config.toml"
  [virtualenvs]
  create = false
  in-project = true
  path="/dev/null"

  [repositories]
__EOF

  # create poetry auth file
  cat << __EOF | sed 's/^  //g' > "${poetry_config_folder}/auth.toml"
  [http-basic]
__EOF

}

# ........................................................................... #
function make_shim {

  local output_shim_file="${1}";
  local application_folder_path="${2}";
  local xdg_folder="${3}";

  # create poetry wrapper
  cat << __EOF | sed 's/^  //g' > "${output_shim_file}"
  #!/usr/bin/env bash

  # pip maintainers seem not to understand or care about systems engineering
  # workflows
  # https://github.com/sdispater/poetry/issues/1049
  # https://github.com/pypa/pip/issues/6434
  # https://discuss.python.org/t/pip-19-1-and-installing-in-editable-mode-with-pyproject-toml/1553

  if test -z \${VIRTUAL_ENV}; then
   echo "poetry is configured to only work inside virtualenv">&2;
   exit 1;
  else
   export XDG_CONFIG_HOME="${xdg_folder}";
   exec "${application_folder_path}/bin/poetry" "\$@";
  fi
__EOF

  log_verbose "make shim executable";
  chmod \
    ${TMP_CHMOD_VERBOSITY} \
    +x  \
    "${output_shim_file}" \
  ;

}


# ........................................................................... #
# print script version
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

  echo "${opts}";
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
begin "$@";
