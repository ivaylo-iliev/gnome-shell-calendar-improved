// ------------------------------------------------------------------------- //
// eslint configuration for this file
//

/* global imports */

/* exported GNOME_VERSION_ABOVE_334 */
/* exported registerClass34 */
/* exported registerClass32 */
/* exported registerClass30 */
/* exported getActor */


// ------------------------------------------------------------------------- //
// enforce strict mode
"use strict";


// ------------------------------------------------------------------------- //
// system libraries imports
const GObject = imports.gi.GObject;


// ------------------------------------------------------------------------- //
const VERSION_LIST = imports.misc.config.PACKAGE_VERSION.split(".");


// ------------------------------------------------------------------------- //
var GNOME_VERSION_ABOVE_334;
if (VERSION_LIST[0] >= 3 && VERSION_LIST[1] > 34) {
  GNOME_VERSION_ABOVE_334 = true;
}
else {
  GNOME_VERSION_ABOVE_334 = false;
}


// ------------------------------------------------------------------------- //
var registerClass34;
{
  if (VERSION_LIST[0] >= 3 && VERSION_LIST[1] > 34) {
    registerClass34 = GObject.registerClass;
  } else {
    registerClass34 = (x => x);
  }
}


// ------------------------------------------------------------------------- //
var registerClass32;
{
  if (VERSION_LIST[0] >= 3 && VERSION_LIST[1] > 32) {
    registerClass32 = GObject.registerClass;
  } else {
    registerClass32 = (x => x);
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
