#!/usr/bin/env make -f

# ########################################################################### #
#
# Basic project commands
#
# Prerequisites
#  - make
#  - coreutils
#  - gnome-shell-extension-tool
#
# ########################################################################### #
#
# http://clarkgrubb.com/makefile-style-guide


# ........................................................................... #
# warn about undefined variables
MAKEFLAGS += --warn-undefined-variables


# ........................................................................... #
# set make shell to bash
SHELL := /usr/bin/env bash
# set bash flags to exit on exit, to test and quit for unset variables
# and to quit failers iwhen pipe
SHELLFLAGS := -o errexit -o nounset -o pipefail -c
# set default goal to all
DEFAULT_GOAL := all
# delete all make suffixes
.SUFFIXES:


# ........................................................................... #
# project support folders
PROJECT = $(CURDIR)
PROJECT_SBIN = $(PROJECT)/sbin
PROJECT_BOOTSTRAP = $(PROJECT_SBIN)/bootstrap
PROJECT_BIN = $(PROJECT)/bin
PROJECT_BIN_APPS = $(PROJECT_BIN)/.apps
PROJECT_BUILD = $(PROJECT)/_build
PROJECT_DIST = $(PROJECT)/_dist


# ........................................................................... #
# project name
NAME = Calendar Improved
# project slug, used in file name creations
SLUG = calendar-improved
# project version
VERSION = 1
# project description
DESCRIPTION = Calendar Improved Gnome Shell Extension


# ........................................................................... #
# gnome shell extension uuid
UUID = $(SLUG)@human.experience
BASE_MODULES = \
	assets \
	extension.js \
	lib \
	metadata.json \
	prefs.js \
	schemas \
	ui
EXTRA_MODULES = \
	LICENSE
TOLOCALIZE =

# ........................................................................... #
# local install
LOCAL_INSTALLBASE = ~/.local/share/gnome-shell/extensions
LOCAL_INSTALLNAME = $(UUID)


# ........................................................................... #
YARN_VERSION = 1.19.1
VIRTUALENV_VERSION = 16.7.8
PYTHON_VERSION = 3
POETRY_VERSION = 1.0.0b7


# ........................................................................... #
define PROJECT_USAGE

BOOTSTRAP

	develop
		install minimal tooling for development

CLEANUP

	clean
		clean minimal tools, except sublime project files

	purge
		clean up everything created by 'develop'

TESTING:

	x11
		debug extension using Xephyr nested session

	wayland
		debug extension using Wayland

BUILD:

	build
		build extenion in project build folder

	clean_build
		remove project build folder and built extension

	dist
	  build project extension zipfile distribution

	 clean_dist
	   remove project extension zipfile distribution

EDITOR SUPPORT: Sublime Text 3

	sublime_config
		write out $(SLUG).sublime-project in the project folder

	clean_sublime
		remove $(SLUG).sublime-project & $(SLUG).sublime-workspace

INFORMATION

	make help
		print this screen

	make about
		print out project name and description

	make info
		print various project variables

endef
export PROJECT_USAGE


# ........................................................................... #
#_PRE_$(SLUG_ENV)_PATH = $(PATH)
#_PRE_$(SLUG_ENV)_PATH = ""
# upper case the SLUG
SLUG_ENV_LOWER =  $(shell echo $(SLUG) | sed 's/-/_/g')
SLUG_ENV_UPPER =  $(shell echo $(SLUG_ENV_LOWER) | sed 's/-/_/g' | tr '[:lower:]' '[:upper:]')

define PROJECT_ACTIVATE_SH
# store pre-project activate PATH
export _PRE_$(SLUG_ENV_UPPER)_PATH="$${PATH}";

# store pre-project bash prompt
export _PRE_$(SLUG_ENV_UPPER)_PS1="$${PS1}"

# prepend project bin to PATH
export PATH="$(PROJECT_BIN):$${PATH}";

function $(SLUG_ENV_LOWER)_deactivate {
	export PATH="$${_PRE_$(SLUG_ENV_UPPER)_PATH}";
	export PS1="$${_PRE_$(SLUG_ENV_UPPER)_PS1}";
}

# prepend current bash prompt with [<project slug>]
export PS1="($(SLUG))$${PS1}";
endef
export PROJECT_ACTIVATE_SH


# ........................................................................... #
define SUBLIME_CONFIG
{
	"folders": [
	{
		"path": "$(PROJECT)",
		"file_include_patterns": [
		],
		"file_exclude_patterns": [
			"activate.sh",
			"schemas/gschemas.compile"
		],
		"folder_include_patterns": [
		],
		"folder_exclude_patterns": [
			"_build",
			"bin",
			"_dist"
		],
	},
	]
}
endef
export SUBLIME_CONFIG


# ........................................................................... #
all: help


# ........................................................................... #
help:
	@echo "$$PROJECT_USAGE" \
	| sed $$'s/\t/  /g' \
	;


# ........................................................................... #
develop: yarn_application eslint_application virtualenv_application \
	poetry_application make_ical_calendar_application sublime_config


# ........................................................................... #
clean: clean_project_bin clean_build clean_dist


# ........................................................................... #
purge: clean clean_sublime


# ........................................................................... #
project_bin:
	@echo "create project bin";
	@# make project bin
	@mkdir \
	  -p \
	  $(PROJECT_BIN) \
	;
	@# create apps folder in project bin for application that are more then one
	@# script
	@mkdir \
	  -p \
	  $(PROJECT_BIN_APPS)

	@echo "create project activate.sh";
	@echo "$$PROJECT_ACTIVATE_SH" \
	| sed $$'s/\t/  /g' \
	> $(PROJECT)/activate.sh;


# ........................................................................... #
clean_project_bin:
	@echo "clean project bin";
	@echo "clean project activate.sh";
	@rm \
	  -r \
	  -f \
	  $(PROJECT)/activate.sh \
	  $(PROJECT_BIN) \
	;


# ........................................................................... #
yarn_application: project_bin
	@echo "install yarn";
	@$(PROJECT_SBIN)/manage-yarn-package.sh \
	  --install \
	  --clean \
	  --yarn-version $(YARN_VERSION) \
	  --application-folder $(PROJECT_BIN_APPS)/yarn \
	  --shim-file $(PROJECT_BIN)/yarn \
	  --quiet \
	;


# .................................`.......................................... #
clean_yarn_application:
	@echo "clean yarn";
	@$(PROJECT_SBIN)/manage-yarn-package.sh \
	  --clean \
	  --application-folder $(PROJECT_BIN_APPS)/yarn \
	  --shim-file $(PROJECT_BIN)/yarn \
	  --quiet \
	;


# ........................................................................... #
eslint_application: project_bin
	@echo "install eslint";
	@$(PROJECT_SBIN)/manage-npm-packages-via-yarn.sh \
	  --install \
	  --clean \
	  --packages-specification-folder $(PROJECT_SBIN)/eslint \
	  --application-folder $(PROJECT_BIN_APPS)/eslint \
	  --shim-file $(PROJECT_BIN)/eslint \
	  --yarn-command $(PROJECT_BIN)/yarn \
	  --quiet \
	;


# ........................................................................... #
clean_eslint_application:
	@echo "clean eslint";
	@$(PROJECT_SBIN)/manage-npm-packages-via-yarn.sh \
	  --clean \
	  --application-folder $(PROJECT_BIN_APPS)/eslint \
	  --shim-file $(PROJECT_BIN)/eslint \
	  --quiet \
	;


# ........................................................................... #
virtualenv_application:
	@echo "install virtualenv";
	@$(PROJECT_SBIN)/manage-virtualenv-package.sh \
	  --install \
	  --clean \
	  --virtualenv-version $(VIRTUALENV_VERSION) \
	  --application-folder $(PROJECT_BIN_APPS)/virtualenv \
	  --shim-file $(PROJECT_BIN)/virtualenv \
	  --quiet \
	;


# .................................`.......................................... #
clean_virtualenv_application:
	@echo "clean virtualenv";
	@$(PROJECT_SBIN)/manage-virtualenv-package.sh \
	  --clean \
	  --application-folder $(PROJECT_BIN_APPS)/virtualenv \
	  --shim-file $(PROJECT_BIN)/virtualenv \
	  --quiet \
	;


# ........................................................................... #
poetry_application:
	@echo "install poetry";
	@$(PROJECT_SBIN)/manage-poetry-package.sh \
	  --install \
	  --clean \
	  --poetry-version $(POETRY_VERSION) \
	  --application-folder $(PROJECT_BIN_APPS)/poetry \
	  --shim-file $(PROJECT_BIN)/poetry \
	  --virtualenv-command "$(PROJECT_BIN)/virtualenv --no-download" \
	  --quiet \
	;


# ........................................................................... #
clean_poetry_application:
	@echo "clean poetry";
	@$(PROJECT_SBIN)/manage-poetry-package.sh \
	  --clean \
	  --poetry-version $(POETRY_VERSION) \
	  --application-folder $(PROJECT_BIN_APPS)/poetry \
	  --shim-file $(PROJECT_BIN)/poetry \
	  --quiet \
	;


# ........................................................................... #
make_ical_calendar_application: clean_make_ical_calendar_application
	@echo "install make_ical_calendar";
	@$(PROJECT_BIN)/virtualenv \
	  --quiet \
	  --no-download \
	  --prompt "(make_ical_calendar$(PYTHON_VERSION))" \
	  $(PROJECT_BIN_APPS)/make_ical_calendar \
	;

	@# install make_ical_calendar dependencies using poetry
	@$(SHELL) -c " \
	  source $(PROJECT_BIN_APPS)/make_ical_calendar/bin/activate && \
	  cd $(PROJECT_SBIN)/make_ical_calendar && \
	  $(PROJECT_BIN)/poetry \
	    install \
	    --quiet \
	";

	@# make a shim make_ical_calendar using venv python
	@echo "#!/usr/bin/env bash" > $(PROJECT_BIN)/make_ical_calendar;
	@echo "" >> $(PROJECT_BIN)/make_ical_calendar;
	@echo 'exec $(PROJECT_BIN_APPS)/make_ical_calendar/bin/python3 "$(PROJECT_SBIN)/make_ical_calendar/make_ical_calendar.py" "$$@";' >> $(PROJECT_BIN)/make_ical_calendar;
	@chmod +x $(PROJECT_BIN)/make_ical_calendar;


# ........................................................................... #
clean_make_ical_calendar_application:
	@echo "clean make_ical_calendar";
	@rm \
	  -r \
	  -f \
	  $(PROJECT_BIN_APPS)/make_ical_calendar \
	  $(PROJECT_BIN)/make_ical_calendar \
	;


# ........................................................................... #
x11:
	@echo "gnome shell x11 debug session"
	@$(PROJECT_SBIN)/gnome-shell-session-debug.sh \
	  x11 \
	  $(PROJECT) \
	  $(UUID) \
	;


# ........................................................................... #
wayland:
	@echo "gnome shell wayland debug session"
	@$(PROJECT_SBIN)/gnome-shell-session-debug.sh \
	  wayland \
	  $(PROJECT) \
	  $(UUID) \
	;


# ........................................................................... #
lint:
	@echo "eslint ."
	@$(PROJECT_BIN)/eslint \
	  $(PROJECT) \
	;

# ........................................................................... #
schemas:
	@echo "glib-compile-schemas ./schemas/"
	@glib-compile-schemas $(PROJECT)/schemas/


# ........................................................................... #
extension: schemas


# ........................................................................... #
install: install-local


# ........................................................................... #
enable-extension-local:
	@# enable gnome shell extensions
	gnome-shell-extension-tool \
	  --enable-extension=ENABLE \
	  $(UUID) \
	;


# ........................................................................... #
disable-extension-local:
	@# disable gnome shell extensions
	gnome-shell-extension-tool \
	  --disable-extension=DISABLE \
	  $(UUID) \
	;


# ........................................................................... #
reload-extension-local:
	@# reload gnome shell extensions
	gnome-shell-extension-tool \
	  --reload-extension=RELOAD \
	  $(UUID) \
	;


# ........................................................................... #
install-local: build
	@# remove any existing install
	@rm \
	  --recursive \
	  --force \
	  $(LOCAL_INSTALLBASE)/$(LOCAL_INSTALLNAME) \
	;

	@# create folder for new install
	@mkdir \
	  --parents \
	  $(LOCAL_INSTALLBASE)/$(LOCAL_INSTALLNAME) \
	;

	@# copy over everything in build to installation folder
	@cp \
	  --recursive \
	  $(PROJECT_BUILD)/* \
	  $(LOCAL_INSTALLBASE)/$(LOCAL_INSTALLNAME)/ \
	;

	@# remove build folder if exists
	@rm \
	  --recursive \
	  --force \
	  $(PROJECT_BUILD) \
	;


# ........................................................................... #
build: clean_build extension
	@echo "create project build"
	@mkdir \
	  --parents \
	  $(PROJECT_BUILD) \
	 ;
	@cp \
	  --recursive \
	  $(BASE_MODULES) \
	  $(EXTRA_MODULES) \
	  $(PROJECT_BUILD) \
	 ;
#	mkdir -p _build/schemas;
#	cp schemas/*.xml _build/schemas/l
#	cp schemas/gschemas.compiled _build/schemas/=;
#	mkdir -p _build/locale
#	for l in $(MSGSRC:.po=.mo) ; do \
#		lf=_build/locale/`basename $$l .mo`; \
#		mkdir -p $$lf; \
#		mkdir -p $$lf/LC_MESSAGES; \
#		cp $$l $$lf/LC_MESSAGES/nos-dash.mo; \
#	done;


# ........................................................................... #
clean_build:
	@echo "clean project build";
	@rm \
		-r \
		-f \
		$(PROJECT_BUILD) \
	;

# ........................................................................... #
dist: build
	@echo "create project distribution"
	@mkdir \
	  --parents \
	  $(PROJECT_BUILD) \
	;
	@mkdir \
	  --parents \
	  $(PROJECT_DIST) \
	;
	@cd $(PROJECT_BUILD) && \
	zip \
	  --quiet \
	  --recurse-paths \
	  "$(PROJECT_DIST)/$(UUID).zip" \
	  . \
	;


# ........................................................................... #
clean_dist: clean_build
	@echo "clean project distribution"
	@rm \
	  --force \
	  --recursive \
	  $(PROJECT_DIST)	\
	;


# ........................................................................... #
sublime_config:
	@echo "create project sublime text3 configuration"
	@echo "$$SUBLIME_CONFIG" \
	| sed $$'s/\t/  /g' \
	> $(PROJECT)/.$(SLUG).sublime-project;


# ........................................................................... #
open_sublime:
	@subl \
		-a $(PROJECT)/.$(SLUG).sublime-project \
	;


# ........................................................................... #
clean_sublime:
	@# wipe sublime project cruft
	@echo "clean project .$(SLUG).sublime-project";
	@echo "clean project .$(SLUG).sublime-workspace";
	@rm \
		-f \
		$(PROJECT)/.$(SLUG).sublime-project \
		$(PROJECT)/.$(SLUG).sublime-workspace \
	;


# ........................................................................... #
info:
	@echo "NAME              : $(NAME)"
	@echo "VERSION           : $(VERSION)"
	@echo "SLUG              : $(SLUG)"
	@echo "PROJECT           : $(PROJECT)"
	@echo "PROJECT_SBIN      : $(PROJECT_SBIN)"
	@echo "PROJECT_BIN       : $(PROJECT_BIN)"


# ........................................................................... #
about:
	@echo $(DESCRIPTION)


# ........................................................................... #
# prints out all targets here as phony
makefile_phony:
	@echo ".PHONY: \\";
	@grep -o "^[a-z_\-\_\.]*:" Makefile \
	| sed 's/:$$/\\/g' \
	| tr -d '\n' \
	| sed 's/\\$$//g' \
	| sed 's/\\/\\ /g' \
	| tr ' ' '\n' \
	| sed 's/\\$$/ \\/g' \
	| sed 's/^/  /g' \
	;
	@echo "";

# ........................................................................... #
.PHONY: \
  all \
  help \
  develop \
  clean \
  purge \
  project_bin \
  clean_project_bin \
  yarn_application \
  clean_yarn_application \
  eslint_application \
  clean_eslint_application \
  virtualenv_application \
  clean_virtualenv_application \
  poetry_application \
  clean_poetry_application \
  make_ical_calendar_application \
  clean_make_ical_calendar_application \
  wayland \
  lint \
  schemas \
  extension \
  install \
  build \
  clean_build \
  dist \
  clean_dist \
  sublime_config \
  open_sublime \
  clean_sublime \
  info \
  about \
  makefile_phony
