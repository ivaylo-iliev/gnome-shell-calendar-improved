/* ------------------------------------------------------------------------- */
// eslint configuration for this file
//
/* global imports */
/* global window */


/* exported init */
/* exported disable */
/* exported enable */


/* ------------------------------------------------------------------------- */
// enforce strict mode
"use strict";


/* ------------------------------------------------------------------------- */
// enable global used for debugging
window.calendarImproved = {
  debug: false,
};


/* ------------------------------------------------------------------------- */
// gnome shell imports
const ExtensionUtils = imports.misc.extensionUtils;


/* ------------------------------------------------------------------------- */
// extension imports
const Extension = ExtensionUtils.getCurrentExtension();
const CalendarImproved = Extension.imports.lib.calendarImproved;


/* ------------------------------------------------------------------------- */
// extension globals
var calendarImprovedInstance;


/* ------------------------------------------------------------------------- */
function init() {
  calendarImprovedInstance = null;
}


/* ------------------------------------------------------------------------- */
function enable() {
  calendarImprovedInstance = new CalendarImproved.CalendarImproved();
  calendarImprovedInstance.enable();
}


/* ------------------------------------------------------------------------- */
function disable() {
  calendarImprovedInstance.disable();
  calendarImprovedInstance = null;
}
