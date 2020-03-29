// ------------------------------------------------------------------------- //
// eslint configuration for this file
//

/* global imports */

/* exported registerClass */
/* exported getActor */

// ------------------------------------------------------------------------- //
// enforce strict mode
"use strict";


// ------------------------------------------------------------------------- //
// system libraries imports
const GObject = imports.gi.GObject;


// ------------------------------------------------------------------------- //
const VERSION_LIST = imports.misc.config.PACKAGE_VERSION.split(".");

var GNOME_VERSION_ABOVE_334;
if (VERSION_LIST[0] >= 3 && VERSION_LIST[1] > 34) {
  GNOME_VERSION_ABOVE_334 = true;
}
else {
  GNOME_VERSION_ABOVE_334 = false;
}


// ------------------------------------------------------------------------- //
// TODO: change to a function
var registerClass;
{
  if (VERSION_LIST[0] >= 3 && VERSION_LIST[1] > 30) {
    registerClass = GObject.registerClass;
  } else {
    registerClass = (x => x);
  }
}


// ------------------------------------------------------------------------- //
var getActor = function workspaceViewActor(subject) {
  if (GNOME_VERSION_ABOVE_334 === true) {
    return subject;
  }
  else {
    return subject.actor;
  }
};
