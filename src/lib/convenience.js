/* ------------------------------------------------------------------------- */
// eslint configuration for this file
//
/* global imports */

/* exported getSettings */
/* exported initTranslations */


/* ------------------------------------------------------------------------- */
// enforce strict mode
"use strict";

/*
 * Part of this file comes from gnome-shell-extensions:
 * https://gitlab.gnome.org/GNOME/gnome-shell-extensions/
 */


/* ------------------------------------------------------------------------- */
const Gettext = imports.gettext;
const Gio = imports.gi.Gio;


/* ------------------------------------------------------------------------- */
const gsConfig = imports.misc.config;
const gsExtensionUtils = imports.misc.extensionUtils;


/* ------------------------------------------------------------------------- */
const Extension = gsExtensionUtils.getCurrentExtension();


/* ------------------------------------------------------------------------- */
/**
 * initTranslations:
 * @domain: (optional): the gettext domain to use
 *
 * Initialize Gettext to load translations from extensionsdir/locale.
 * If @domain is not provided, it will be taken from metadata["gettext-domain"]
 */
function initTranslations(domain) {
  let localeDir;

  // Check if this extension was built with "make zip-file", and thus
  // has the locale files in a subfolder
  // otherwise assume that extension has been installed in the
  // same prefix as gnome-shell
  localeDir = Extension.dir.get_child("locale");
  if (localeDir.query_exists(null)) {
    Gettext.bindtextdomain(domain, localeDir.get_path());
  }
  else {
    Gettext.bindtextdomain(domain, gsConfig.LOCALEDIR);
  }
}


/* ------------------------------------------------------------------------- */
/**
 * getSettings:
 * @schema: (optional): the GSettings schema id
 *
 * Builds and return a GSettings schema for @schema, using schema files
 * in extensionsdir/schemas. If @schema is not provided, it is taken from
 * metadata["settings-schema"].
 */
function getSettings(schema) {

  let schemaDir;
  let schemaObj;
  let schemaSource;

  // Check if this extension was built with "make zip-file", and thus
  // has the schema files in a subfolder
  // otherwise assume that extension has been installed in the
  // same prefix as gnome-shell (and therefore schemas are available
  // in the standard folders)
  schemaDir = Extension.dir.get_child("schemas");
  if (schemaDir.query_exists(null)) {
    schemaSource = Gio.SettingsSchemaSource.new_from_directory(
      schemaDir.get_path(),
      Gio.SettingsSchemaSource.get_default(),
      false
    );
  }
  else {
    schemaSource = Gio.SettingsSchemaSource.get_default();
  }

  schemaObj = schemaSource.lookup(schema, true);
  if (!schemaObj) {
    throw new Error(
      "Schema " + schema + " could not be found for extension "
      + Extension.metadata.uuid + ". Please check your installation."
    );
  }

  return new Gio.Settings({
    settings_schema: schemaObj
  });
}
