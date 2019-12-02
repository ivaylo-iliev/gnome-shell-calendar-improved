#!/usr/bin/env bash

# ########################################################################### #
#
# Manage Yarn package installation
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
TMP_OPTION_YARN_VERSION="";
TMP_OPTION_APPLICATION_FOLDER="";
TMP_OPTION_SHIM_FILE="";
TMP_OPTION_PARENT_DOWNLOAD_URL="";
TMP_OPTION_NODE_PATH="";
TMP_OPTION_CURL_PATH="";
# genetic argument flags
TMP_OPTION_VERBOSE=0;
TMP_OPTION_QUIET=0;
TMP_OPTION_DEBUG=0;


# ........................................................................... #
# various command verbosity flags
TMP_CURL_VERBOSITY="";
TMP_RM_VERBOSITY="";
TMP_CHMOD_VERBOSITY="";


# ........................................................................... #
# prefix of yarn, used in folder, file and download url creation
# unlikely to change, currently just a re-usable variable
TMP_YARN_PREFIX="yarn-v"


# ........................................................................... #
function usage {
  echo "
NAME:

  ${SCRIPT_NAME} - Manage Yarn package installation

SYNOPSIS:

  ${SCRIPT_NAME} [options]

OPTIONS

  -i, --install
    install yarn packages and it's shim, can be used with --clean/-c

  -c, --clean
    remove the application folder and shims

  -e, --yarn-version <version>
    required, version of yarn to manage

  -a, --application-folder <folder path>
    required, folder that will contain the installation

  -s, --shim-file <file path>
    required, path where executable of yarn shim will be placed
    typically, inside project bin folder

  -p, --parent-download-url <url>
    optional, URL to download package from via curl
    defaults to official Yarn download URL

  -n, --node-path <file path>
    optional, path to node
    defaults to 'node'

  -d, --curl-path <file path>
    optional, path to curl
    defaults to 'curl'

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

  # run install or run operation
  if [ ${TMP_OPTION_INSTALL} == 1 ]; then
    install_yarn_package_and_shim;
  elif [ ${TMP_OPTION_CLEAN} == 1 ]; then
    clean_yarn_package_and_shim;
  else
    alert "BUG: do nothing, you should have never seen this message" 2;
  fi

}


# ........................................................................... #
# get script params and store them
function process_script_arguments {

  local short_args;
  local long_args;
  local processed_args;

  short_args="i c e: a: s: p: n: d: ";
  short_args+="v q";
  short_args+="h";
  long_args="install clean yarn-version: application-folder: shim-file: ";
  long_args+="parent-download-url: node-path: curl-path: ";
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

      # store yarn version value
      --yarn-version | -e )
        TMP_OPTION_YARN_VERSION="${2}";
        shift;
        ;;

      # store application folder path
      --application-folder | -a)
        TMP_OPTION_APPLICATION_FOLDER="${2}";
        shift;
        ;;

      # store shims
      --shim-file | -s)
        TMP_OPTION_SHIM_FILE="${2}";
        shift;
        ;;

      # store package specification folder path
      --parent-download-url | -p)
        TMP_OPTION_PARENT_DOWNLOAD_URL="${2}";
        shift;
        ;;

      # store node path
      --node-path | -n)
        TMP_OPTION_NODE_PATH="${2}";
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

    # validate that we have yarn version
    if [ "${TMP_OPTION_YARN_VERSION}" == "" ]; then
      abort "please specify yarn version using --yarn-version/-e" 1;
    fi

    # validate that we have parent download url
    if [ "${TMP_OPTION_PARENT_DOWNLOAD_URL}" == "" ]; then
      # use official url
      TMP_OPTION_PARENT_DOWNLOAD_URL="https://yarnpkg.com/";
      TMP_OPTION_PARENT_DOWNLOAD_URL+="downloads/${TMP_OPTION_YARN_VERSION}/";
    fi

    # check if node path is specified and if not set to 'node'
    if [ "${TMP_OPTION_NODE_PATH}" == "" ]; then
      TMP_OPTION_NODE_PATH="node";
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
    TMP_CURL_VERBOSITY="--verbose";
    TMP_RM_VERBOSITY="--verbose";
    TMP_CHMOD_VERBOSITY="--verbose";
  else
    TMP_CURL_VERBOSITY=""
    TMP_RM_VERBOSITY="";
    TMP_CHMOD_VERBOSITY="";
  fi

  # if quiet, set verbosity to 0 and enforce the quietest options for
  # those utilities that have it
  if [ ${TMP_OPTION_QUIET} -eq 1 ]; then
    TMP_OPTION_VERBOSE=0;
    TMP_CURL_VERBOSITY="--silent"
    TMP_RM_VERBOSITY="";
    TMP_CHMOD_VERBOSITY="--silent";
  fi

}


# ........................................................................... #
function install_yarn_package_and_shim {

  local msg;
  local yarn_folder;
  local yarn_download_url;
  local application_parent_folder;

  # compose yarn folder, download url, and application parent folder
  yarn_folder="${TMP_OPTION_APPLICATION_FOLDER}"
  yarn_folder+="/${TMP_YARN_PREFIX}";
  yarn_folder+="${TMP_OPTION_YARN_VERSION}";

  yarn_download_url="${TMP_OPTION_PARENT_DOWNLOAD_URL}";
  yarn_download_url+="${TMP_YARN_PREFIX}";
  yarn_download_url+="${TMP_OPTION_YARN_VERSION}.tar.gz";

  application_parent_folder="$(dirname ${TMP_OPTION_APPLICATION_FOLDER})"
  not_clean=0;

  # verity application folder exists
  if [ ! -d "${application_parent_folder}" ]; then
    msg="application folder parent folder must already exist, since we can ";
    msg+="only clean up the last folder in the applicaiton folder path";
    abort "${msg}" 1;
  fi

  # if clean option specified then clean yarn
  if [ ${TMP_OPTION_CLEAN} == 1 ]; then
    clean_yarn_package_and_shim;
  else
    # check if yarn folder already exists
    if [ -e "${yarn_folder}" ]; then
      echo "${yarn_folder} already exists">&2;
      not_clean=1;
    fi
    # check if shim file already exists
    if [ -e "${TMP_OPTION_SHIM_FILE}" ]; then
      echo "${TMP_OPTION_SHIM_FILE} already exists">&2;
      not_clean=1;
    fi
    # if either of above exists then error out
    if [ ${not_clean} == 1 ]; then
      msg="please use --clean/-c option to remove existing yarn installation ";
      msg+="and shim before install";
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
    ${TMP_CURL_VERBOSITY} \
    --fail \
    --show-error \
    --location \
    --output - \
    "${yarn_download_url}" \
  | tar \
      -C "${TMP_OPTION_APPLICATION_FOLDER}" \
      -x \
      -z \
  ;

  # create yarn shim
  make_shim "${TMP_OPTION_SHIM_FILE}";

  log_unquiet "created ${TMP_OPTION_APPLICATION_FOLDER} folders">&2;
  log_unquiet "created ${TMP_OPTION_SHIM_FILE} shim">&2;

}


# ........................................................................... #
function make_shim {

  local output_shim_file="${1}";
  local application_folder_path;

  application_folder_path="$(cd ${TMP_OPTION_APPLICATION_FOLDER} && pwd -P)";
  application_folder_path+="/${TMP_YARN_PREFIX}";
  application_folder_path+="${TMP_OPTION_YARN_VERSION}";

  cat << __EOF | sed 's/^  //g' > "${output_shim_file}"
  #!/usr/bin/env bash

  # run yarn
  exec "${TMP_OPTION_NODE_PATH}" \\
    "${application_folder_path}/bin/yarn.js" \\
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
function clean_yarn_package_and_shim {

  local output_shim_file;
  local msg;

  msg="remove yarn installation folder: ";
  msg+="${TMP_OPTION_APPLICATION_FOLDER}";
  log_unquiet "${msg}";
  rm \
    ${TMP_RM_VERBOSITY} \
    -r \
    -f \
    "${TMP_OPTION_APPLICATION_FOLDER}" \
  ;

  log_verbose "remove yarn shim";
  clean_shim "${TMP_OPTION_SHIM_FILE}";

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
main "$@";
