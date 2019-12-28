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
const gsCalendar = imports.ui.calendar;
const gsExtensionUtils = imports.misc.extensionUtils;
const gsMain = imports.ui.main;


/* ------------------------------------------------------------------------- */
// extension imports
const Extension = gsExtensionUtils.getCurrentExtension();
const CalendarEventImproved = Extension.imports.lib.calendarEventImproved;
const DBusEventSourceImprovedImproved =
  Extension.imports.lib.dBusEventSourceImprovedImproved;
const EventMessageImproved = Extension.imports.lib.eventMessageImproved;
const SettingsRegistry = Extension.imports.lib.settingsRegistry;
const Utils = Extension.imports.lib.utils;

/* ------------------------------------------------------------------------- */
// globals
const builtinCalendarEventMessage = gsCalendar.EventMessage;
const builtinCalendarDBusEventSource = gsCalendar.DBusEventSource;
const builtinCalendarEvent = gsCalendar.CalendarEvent;

/* ------------------------------------------------------------------------- */
var CalendarImproved = class CalendarImproved {

  constructor() {

    // logger
    this._logger = new Utils.Logger(
      "calendarImproved.js::CalendarImproved"
    );

    // date menu reference
    this._dateMenu = gsMain.panel.statusArea.dateMenu;

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
    gsMain.panel.statusArea.dateMenu._eventSource.disconnectAll();
    // null out event source so it does not try to deallocate itself,
    // since apparently that causes issues
    gsMain.panel.statusArea.dateMenu._eventSource = null;

    // monkeypatch CalendarEvent to CalendarEventImproved
    gsCalendar.CalendarEvent = CalendarEventImproved.CalendarEventImproved;

    // monkey patch EventMessage to our EventMessageImproved
    let EventMessageImprovedClass =
      EventMessageImproved.EventMessageImprovedFactory(
        this._settingsRegistry.boundSettings
      );
    gsCalendar.EventMessage = EventMessageImprovedClass;

    // monkeypatch Calendar.DBusEventSource with our DBusEventSourceImproved
    // for any future use of DBusEventSource
    gsCalendar.DBusEventSource =
      DBusEventSourceImprovedImproved.DBusEventSourceImproved;

    // set new source for existing dateMenu to DBusEventSourceImproved
    gsMain.panel.statusArea.dateMenu._setEventSource(
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
    gsMain.panel.statusArea.dateMenu._eventSource.disconnectAll();
    // null out event source so it does not try to deallocate itself,
    // since apparently that causes issues
    gsMain.panel.statusArea.dateMenu._eventSource = null;

    // monkeypatch CalendarEvent to CalendarEventImproved
    gsCalendar.CalendarEvent = builtinCalendarEvent;

    // monkeypatch Calendar.EventMessage to builtin DBusEventSource
    gsCalendar.DBusEventSource = builtinCalendarDBusEventSource;

    // monkeypatch Calendar.EventMessage with original Calendar.EventMessage
    gsCalendar.EventMessage = builtinCalendarEventMessage;

    // set new source for the existing source event
    gsMain.panel.statusArea.dateMenu._setEventSource(
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
