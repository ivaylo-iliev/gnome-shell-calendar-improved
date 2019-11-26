#!/usr/bin/env bash

# ########################################################################### #
#
# Extract Gnome Shell resource files
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
SCRIPT_FOLDER="$(cd $(dirname ${0}); pwd -P)";

# ........................................................................... #
# version
TMP_PROGRAM_VERSION="1.0"

# ........................................................................... #
# gnome shell resouce archive
TMP_GNOME_SHELL_RESOURCE_ARCHIVE="/usr/lib/gnome-shell/libgnome-shell.so";


# ........................................................................... #
function usage {
  echo "
NAME:

  ${SCRIPT_NAME} - Extract Gnome Shell resource files

SYNOPSIS:

  ${SCRIPT_NAME} FOLDER [RESOURCE_ARCHIVE]

OPTIONS

  FOLDER
    required, extract resource files to this folder. Folder will be created
    and should not exist before hand

  RESOURCE_ARCHIVE
    optional, location of resource archive to extract.
    defaults to: ${TMP_GNOME_SHELL_RESOURCE_ARCHIVE}
";

}


# ........................................................................... #
function main {

  # extract gnome shell resources
  extract_gnome_shell_resources "$@";

}


# ........................................................................... #
function extract_gnome_shell_resources {

  local output_folder="${1:-}";
  local resource_archive="${2:-${TMP_GNOME_SHELL_RESOURCE_ARCHIVE}}";


  local resource_file;
  local target_resource_file;
  local target_resource_parent_folder;

  # check if outfolder is not empty, is not print usage and exit with error
  # code 1
  if [ "${output_folder}" == "" ]; then
    usage >&2;
    exit 1
  fi

  # check if output folder already exists and if not print error and exit with
  # error code 1
  if [ -e "${output_folder}" ]; then
    echo "error: "${output_folder}" already exists" >&2;
    exit 1;
  fi

  # check if resouce archive exists, if not exit with error
  if [ ! -e "${resource_archive}" ]; then
    echo "error: "${resource_archive}" does not exists" >&2;
    exit 1;
  fi

  # create output folder and it's paretns
  mkdir \
    --parents \
    "${output_folder}" \
  ;

  # change into output folder
  cd "${output_folder}";

  # go over all the gnome shell resources and extract them to file
  for resource_file in $(gresource list "${resource_archive}"); do

    # remove /org/gnome/shell from front of the resource string
    target_resource_file="${resource_file/#\/org\/gnome\/shell\/}";
    # get target resource parent folder
    target_resource_parent_folder="$(dirname ${target_resource_file})";

    # create parent folders to contain extracted resource file
    mkdir \
      --parents \
      "${target_resource_parent_folder}" \
    ;

    echo "extracting: ${target_resource_file}";

    # extract resource to target file
    gresource extract \
      "${resource_archive}" \
      "${resource_file}" \
    > "${target_resource_file}";

  done

  # tell user how to use the use the extracted files
  echo "";
  echo "to run Gnome Shell with these extracted source files use:";
  echo "  GNOME_SHELL_JS=${output_folder} gnome-shell";
  echo "globally: put GNOME_SHELL_JS variable into /etc/environment and restart";
  echo "";

}


# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #
main "$@";
