/* ------------------------------------------------------------------------- */
// eslint configuration for this file
//
/* global imports */

/* exported CalendarImproved */


/* ------------------------------------------------------------------------- */
// enforce strict mode
"use strict";


/* ------------------------------------------------------------------------- */
// gnome shell imports
const Calendar = imports.ui.calendar;
const Main = imports.ui.main;
const ExtensionUtils = imports.misc.extensionUtils;


/* ------------------------------------------------------------------------- */
// extension imports
const Extension = ExtensionUtils.getCurrentExtension();
const eventMessageImproved = Extension.imports.lib.eventMessageImproved;
const settingsRegistry = Extension.imports.lib.settingsRegistry;
const Utils = Extension.imports.lib.utils;


/* ------------------------------------------------------------------------- */
// globals
const builtinCalendarEventMessage = Calendar.EventMessage;


/* ------------------------------------------------------------------------- */
var CalendarImproved = class CalendarImproved {

  constructor() {

    // logger
    this._logger = new Utils.Logger(
      "calendarImproved.js::CalendarImproved"
    );

    // date menu reference
    this._dateMenu = Main.panel.statusArea.dateMenu;

    // event section reference
    this._eventsSection = this._dateMenu._messageList._eventsSection;

    // signals registry
    this._signalsRegistry = new Utils.SignalsRegistry();

    // settings registry
    this._settingsRegistry = new settingsRegistry.SettingsRegistry();

  }

  /* ....................................................................... */
  enable() {

    // initialize settingsRegistry
    this._settingsRegistry.init();

    let EventMessageImprovedClass =
      eventMessageImproved.EventMessageImprovedFactory(
        this._settingsRegistry.boundSettings
      );
    Calendar.EventMessage = EventMessageImprovedClass;

    // monkeypatch Calendar.EventMessage with our EventMessage improved
    //Calendar.EventMessage = eventMessageImproved.EventMessageImproved;

    // connect date menu "open-state-changed" signal so we can refresh the menu
    // drop down with any event needed to be dimmed as default setup does not
    // reload today events
    this._signalsRegistry.addWithLabel(
      "calendarImproved",
      [
        this._dateMenu.menu,
        "open-state-changed",
        this._dateMenuOpenStateChanged.bind(this)
      ]
    );

    // reload all the events for today to update the UI elements
    this._reloadEvents();
  }


  /* ....................................................................... */
  disable() {
    // monkeypatch Calendar.EventMessage with original Calendar.EventMessage
    Calendar.EventMessage = builtinCalendarEventMessage;

    // disconnect all signals we connected
    this._signalsRegistry.destroy();

    // destroy settingsRegistry
    this._settingsRegistry.destroy();

    // reload all the events for today to update the UI elements
    this._reloadEvents();
  }


  /* ....................................................................... */
  _reloadEvents() {
    // go over all the messages in the events sections registry, delete each
    // entry from the registry and remove the event message ui panel
    this._eventsSection._messageById.forEach((message, id) => {
      this._eventsSection._messageById.delete(id);
      this._eventsSection.removeMessage(message);
    });

    // reload all the events in the events sections
    this._eventsSection._reloadEvents();
  }


  /* ....................................................................... */
  _dateMenuOpenStateChanged(menu, isOpen) {
    // reload events if date menu is open
    if (isOpen === true) {
      this._reloadEvents();
    }
  }

};
