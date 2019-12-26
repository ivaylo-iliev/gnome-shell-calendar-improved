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
const ExtensionUtils = imports.misc.extensionUtils;
const Calendar = imports.ui.calendar;
const Main = imports.ui.main;


/* ------------------------------------------------------------------------- */
// extension imports
const Extension = ExtensionUtils.getCurrentExtension();
const CalendarEventImproved = Extension.imports.lib.calendarEventImproved;
const DBusEventSourceImprovedImproved = Extension.imports.lib.dBusEventSourceImprovedImproved;
const EventMessageImproved = Extension.imports.lib.eventMessageImproved;
const SettingsRegistry = Extension.imports.lib.settingsRegistry;
const Utils = Extension.imports.lib.utils;

/* ------------------------------------------------------------------------- */
// globals
const builtinCalendarEventMessage = Calendar.EventMessage;
const builtinCalendarDBusEventSource = Calendar.DBusEventSource;
const builtinCalendarEvent = Calendar.CalendarEvent;

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
    this._settingsRegistry = new SettingsRegistry.SettingsRegistry();

  }

  /* ....................................................................... */
  enable() {

    // initialize settingsRegistry
    this._settingsRegistry.init();

    // disconnect existing events for the event source
    Main.panel.statusArea.dateMenu._eventSource.disconnectAll();
    // null out event source so it does not try to deallocate itself,
    // since apparently that causes issues
    Main.panel.statusArea.dateMenu._eventSource = null;

    // monkeypatch CalendarEvent to CalendarEventImproved
    Calendar.CalendarEvent = CalendarEventImproved.CalendarEventImproved;

    // monkey patch EventMessage to our EventMessageImproved
    let EventMessageImprovedClass =
      EventMessageImproved.EventMessageImprovedFactory(
        this._settingsRegistry.boundSettings
      );
    Calendar.EventMessage = EventMessageImprovedClass;

    // monkeypatch Calendar.DBusEventSource with our DBusEventSourceImproved
    // for any future use of DBusEventSource
    Calendar.DBusEventSource = DBusEventSourceImprovedImproved.DBusEventSourceImproved;

    // set new source for existing dateMenu to DBusEventSourceImproved
    Main.panel.statusArea.dateMenu._setEventSource(
      new DBusEventSourceImprovedImproved.DBusEventSourceImproved()
    );

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

    // disconnect existing events for the event source
    Main.panel.statusArea.dateMenu._eventSource.disconnectAll();
    // null out event source so it does not try to deallocate itself,
    // since apparently that causes issues
    Main.panel.statusArea.dateMenu._eventSource = null;

    // monkeypatch CalendarEvent to CalendarEventImproved
    Calendar.CalendarEvent = builtinCalendarEvent;

    // monkeypatch Calendar.EventMessage to builtin DBusEventSource
    Calendar.DBusEventSource = builtinCalendarDBusEventSource;

    // monkeypatch Calendar.EventMessage with original Calendar.EventMessage
    Calendar.EventMessage = builtinCalendarEventMessage;

    // set new source for the existing source event
    Main.panel.statusArea.dateMenu._setEventSource(
      new builtinCalendarDBusEventSource()
    );

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
