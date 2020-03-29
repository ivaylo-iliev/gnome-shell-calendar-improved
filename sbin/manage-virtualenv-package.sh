#!/usr/bin/env bash

# ########################################################################### #
#
#  Download virtualenv source distribution tar archive, extract it to
#  application folder and create a shim to virtualenv
#
#  Dependencies
#
#   - bash
#   - codeutils
#   - sed
#   - grep
#   - jq
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
#SCRIPT_FOLDER="$(cd $(dirname "${0}") && pwd -P)";


# ........................................................................... #
# version
TMP_PROGRAM_VERSION="1.0";


# ........................................................................... #
TMP_OPTION_INSTALL=0;
TMP_OPTION_CLEAN=0;
TMP_OPTION_VIRTUALENV_VERSION="";
TMP_OPTION_APPLICATION_FOLDER="";
TMP_OPTION_SHIM_FILE="";
TMP_OPTION_SHIM_VIRTUALENV_ARGUMENTS="";
TMP_OPTION_PARENT_DOWNLOAD_URL="";
TMP_OPTION_PYTHON_PATH="";
TMP_OPTION_CURL_PATH="";
# genetic argument flags
TMP_OPTION_VERBOSE=0;
TMP_OPTION_QUIET=0;
TMP_OPTION_DEBUG=0;


# ........................................................................... #
# various command verbosity flags
TMP_RM_VERBOSITY="";
TMP_CHMOD_VERBOSITY="";


# ........................................................................... #
# prefix of virtualenv, used in folder, file and download url creation
# unlikely to change, currently just a re-usable variable
TMP_VIRTUALENV_PREFIX="virtualenv-"

# ........................................................................... #
# print script usage
function usage {
    echo "\
Usage: ${SCRIPT_NAME} [OPTIONS]

Options:

  -i, --install
    install virtualenv package and shim, can be used with --clean/-c

  -c, --clean
    remove the application folder and shim

  -e, --virtualenv-version <virtualenv version>
    required. version of virtualenv to manage. if set to 'latest' a version is
    looked up and retrieved from pypi.org

  -a, --application-folder <folder path>
    required, folder that will contain the installation

  -s, --shim-file <file path>
    required, path where executable of virtualen shim will be placed.
    typically, inside a bin folder

  -o, --shim-virtualenv-arguments <quoted string>
    optional, quote string containing set of argument to give to virtualenv

  -n, --python-path <file path>
    optional, path to python
    defaults to 'python3'

  -d, --curl-path <file path>
    optional, path to curl
    defaults to 'curl'

  -p, --parent-download-url <url>
    optional, URL for the parent location of virtualenv source distribution.
    when combined with version make up download URL defaults to official
    PyPI URL

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

  # run install or run operation
  if [ ${TMP_OPTION_INSTALL} == 1 ]; then
    install_virtualenv;
  elif [ ${TMP_OPTION_CLEAN} == 1 ]; then
    clean_virtualenv;
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

  short_args="i c e: a: s: o: n: d: p:";
  short_args+="v q ";
  short_args+="h";
  long_args+="install clean virtualenv-version: application-folder: ";
  long_args+="shim-file: shim-virtualenv-arguments: python-path: curl-path ";
  long_args+="parent-download-url: ";
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

      # store virtualenv version value
      --virtualenv-version | -e )
        TMP_OPTION_VIRTUALENV_VERSION="${2}";
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

      # store shim file value
      --shim-virtualenv-arguments | -o )
        TMP_OPTION_SHIM_VIRTUALENV_ARGUMENTS="${2}";
        shift;
        ;;

      # store parent download url value
      --parent-download-url | -p )
        TMP_OPTION_PARENT_DOWNLOAD_URL="${2}";
        shift;
        ;;

      # store python path
      --python-path | -n)
        TMP_OPTION_PYTHON_PATH="${2}";
        shift;
        ;;

      # store curl path
      --curl-path | -d)
        TMP_OPTION_CURL_PATH="${2}";
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
          echo "Unknown positional arguments(s) given: $*">&2;
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
        echo "Unknown argument(s) given: $*">&2;
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
    abort "please specify application folder using -a/--application-folder" 1;
  fi

  # check if shim file is specified, if not abort with message
  if [ "${TMP_OPTION_SHIM_FILE}" == "" ]; then
    abort "please specify shim file path using -s/--shim-file" 1;
  fi

  # validate options that are needed for install
  if [ ${TMP_OPTION_INSTALL} == 1 ]; then

    # validate that we have virtualenv command
    if [ "${TMP_OPTION_VIRTUALENV_VERSION}" == "" ]; then
      msg="please specify virtualenv version using --virtualenv-version/-e";
      abort "${msg}" 1;
    fi

    # validate that we have parent download url
    if [ "${TMP_OPTION_PARENT_DOWNLOAD_URL}" == "" ]; then
      # use pypi url
      TMP_OPTION_PARENT_DOWNLOAD_URL="https://files.pythonhosted.org/";
      TMP_OPTION_PARENT_DOWNLOAD_URL+="packages/source/v/virtualenv/";
    fi

    # check if python path is specified and if not set to 'python3'
    if [ "${TMP_OPTION_PYTHON_PATH}" == "" ]; then
      TMP_OPTION_PYTHON_PATH="python3";
    fi

    # check if curl path is specified and if not set to 'curl'
    if [ "${TMP_OPTION_CURL_PATH}" == "" ]; then
      TMP_OPTION_CURL_PATH="curl";
    fi

  fi

  # if debug then turn on verbosity
  if [ ${TMP_OPTION_DEBUG} -eq 1 ]; then
    TMP_OPTION_VERBOSE=1;
  fi

  # if verbose the set gpg, rm, mkdir verbosity
  if [ ${TMP_OPTION_VERBOSE} -eq 1 ]; then
    TMP_RM_VERBOSITY="--verbose";
    TMP_CHMOD_VERBOSITY="--verbose";
  else
    TMP_RM_VERBOSITY="";
    TMP_CHMOD_VERBOSITY="";
  fi

  # if quiet, set verbosity to 0 and enforce the quietest options for
  # those utilities that have it
  if [ ${TMP_OPTION_QUIET} -eq 1 ]; then
    TMP_OPTION_VERBOSE=0;
    TMP_RM_VERBOSITY="";
    TMP_CHMOD_VERBOSITY="--silent";
  fi

  # get the latest version if asked for
  if [ "${TMP_OPTION_VIRTUALENV_VERSION}" == "latest" ]; then
    TMP_OPTION_VIRTUALENV_VERSION="$(latest_virtualenv_version)";
  fi

}


# ........................................................................... #
function latest_virtualenv_version {

  "${TMP_OPTION_CURL_PATH}" \
    --silent \
    --get \
    --header 'Host: pypi.org' \
    --header 'Accept: application/json' \
    https://pypi.org/pypi/virtualenv/json \
  | jq -r '.info.version'
}

# ........................................................................... #
function clean_virtualenv {

  # remove existing application folder and shim
  rm \
    ${TMP_RM_VERBOSITY} \
    -r \
    -f \
    "${TMP_OPTION_APPLICATION_FOLDER}" \
    "${TMP_OPTION_SHIM_FILE}" \
  ;
  log_unquiet "removed ${TMP_OPTION_APPLICATION_FOLDER} folder";
  log_unquiet "removed ${TMP_OPTION_SHIM_FILE} shim";

}


# ........................................................................... #
function install_virtualenv {

  local msg;
  local virtualenv_folder;
  local virtualenv_download_url;
  local application_parent_folder;

  # compose virtualenv folder, download url, and application parent folder
  virtualenv_folder="${TMP_OPTION_APPLICATION_FOLDER}"
  virtualenv_folder+="/${TMP_VIRTUALENV_PREFIX}";
  virtualenv_folder+="${TMP_OPTION_VIRTUALENV_VERSION}";

  virtualenv_download_url="${TMP_OPTION_PARENT_DOWNLOAD_URL}";
  virtualenv_download_url+="${TMP_VIRTUALENV_PREFIX}";
  virtualenv_download_url+="${TMP_OPTION_VIRTUALENV_VERSION}.tar.gz";

  application_parent_folder="$(dirname "${TMP_OPTION_APPLICATION_FOLDER}")";
  not_clean=0;

  # verity application folder exists
  if [ ! -d "${application_parent_folder}" ]; then
    msg="application folder parent folder must already exist, since we can ";
    msg+="only clean up the last folder in the applicaiton folder path";
    abort "${msg}" 1;
  fi

  # if clean option specified then clean virtualenv
  if [ ${TMP_OPTION_CLEAN} == 1 ]; then
    clean_virtualenv;
  else
    # check if virtualenv folder already exists
    if [ -e "${virtualenv_folder}" ]; then
      echo "${virtualenv_folder} already exists">&2;
      not_clean=1;
    fi
    # check if shim file already exists
    if [ -e "${TMP_OPTION_SHIM_FILE}" ]; then
      echo "${TMP_OPTION_SHIM_FILE} already exists">&2;
      not_clean=1;
    fi
    # if either of above exists then error out
    if [ ${not_clean} == 1 ]; then
      msg="please use --clean/-c option to remove existing virtualenv ";
      msg+="installation and shim before install";
      abort "${msg}" 1;
    fi
  fi

  # create application folder
  mkdir \
    -p \
    "${TMP_OPTION_APPLICATION_FOLDER}" \
  ;

  # download and untar source dist tarball
  "${TMP_OPTION_CURL_PATH}" \
    --silent \
    --fail \
    --show-error \
    --location \
    --output - \
    "${virtualenv_download_url}" \
  | tar \
      -C "${TMP_OPTION_APPLICATION_FOLDER}" \
      -x \
      -z \
  ;

  # create virtualenv.py shim
  make_shim "${TMP_OPTION_SHIM_FILE}" \
  ;

  log_unquiet "created ${TMP_OPTION_APPLICATION_FOLDER} folders";
  log_unquiet "created ${TMP_OPTION_SHIM_FILE} shim";

}


# ........................................................................... #
function make_shim {

  local output_shim_file="${1}";
  local application_folder_path;

  application_folder_path="$(cd "${TMP_OPTION_APPLICATION_FOLDER}" && pwd -P)";
  application_folder_path+="/${TMP_VIRTUALENV_PREFIX}";
  application_folder_path+="${TMP_OPTION_VIRTUALENV_VERSION}";

  cat << __EOF | sed 's/^  //g' > "${output_shim_file}"
  #!/usr/bin/env bash

  # run virtualenv
  exec "${TMP_OPTION_PYTHON_PATH}" \\
    "${application_folder_path}/virtualenv.py" \\
__EOF

  # virtualenv argements if exist
  if [ "${TMP_OPTION_SHIM_VIRTUALENV_ARGUMENTS}" != "" ]; then
    cat << ____EOF | sed 's/^  //g' >> "${output_shim_file}"
      ${TMP_OPTION_SHIM_VIRTUALENV_ARGUMENTS} \\
____EOF
  fi

  cat << __EOF | sed 's/^  //g' >> "${output_shim_file}"
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
  # shellcheck disable=SC2181
  if [ $? != 0 ]; then
    # strip out header text for unrecognized and invalid options
    # and replace it with our own arguments text
    # strip out the single quotes surronding each quote
    # shellcheck disable=SC1117
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
    exit "${exit_code}";
}


# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
begin "$@";
