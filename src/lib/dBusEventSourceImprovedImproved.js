/* ------------------------------------------------------------------------- */
// eslint configuration for this file
//
/* global imports */

/* exported DBusEventSourceImproved */


/* ------------------------------------------------------------------------- */
// enforce strict mode
"use strict";


/* ------------------------------------------------------------------------- */
// gnome shell imports
const gsCalendar = imports.ui.calendar;
const gsExtensionUtils = imports.misc.extensionUtils;
const gsSignals = imports.signals;


/* ------------------------------------------------------------------------- */
// extension imports
const Extension = gsExtensionUtils.getCurrentExtension();
const CalendarEventImproved = Extension.imports.lib.calendarEventImproved;


/* ------------------------------------------------------------------------- */
// globals


/* ------------------------------------------------------------------------- */
var DBusEventSourceImproved = class DBusEventSourceImproved
  extends gsCalendar.DBusEventSource {

  /* ..................................................................... */
  constructor() {
    // call parent constructor with empty title (we set it Later)
    // this behaviour change in 3.32 (see bellow) but still work
    // eslint-disable-next-line max-len
    // https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-30/js/ui/calendar.js#L709
    // eslint-disable-next-line max-len
    // https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-32/js/ui/calendar.js#L661
    super();
  }

  _onEventsReceived(results /*, error */) {
    let newEvents = [];
    let appointments = results ? results[0] : null;
    if (appointments != null) {
      for (let n = 0; n < appointments.length; n++) {
        let a = appointments[n];

        // eslint-disable-next-line max-len
        // https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-34/src/calendar-server/gnome-shell-calendar-server.c#L919-933
        // log("================================");
        // for (let j = 0; j < a.length; j++) {
        //   log(j + ": " + a[j]);
        // }
        // log("");

        // 0: id,
        // 1: a->summary != NULL ? a->summary : "",
        // 2: a->description != NULL ? a->description : "",
        // 3: (gboolean) a->is_all_day,
        // 4: (gint64) start_time,
        // 5: (gint64) end_time,
        // 6: extras_builder

        let date = new Date(a[4] * 1000);
        let end = new Date(a[5] * 1000);
        let id = a[0];
        let summary = a[1];
        let description = a[2];
        let allDay = a[3];
        let event = new CalendarEventImproved.CalendarEventImproved(
          id,
          date,
          end,
          summary,
          allDay,
          description
        );
        newEvents.push(event);
      }
      newEvents.sort((ev1, ev2) => ev1.date.getTime() - ev2.date.getTime());
    }

    this._events = newEvents;
    this.isLoading = false;
    this.emit("changed");
  }
};
gsSignals.addSignalMethods(DBusEventSourceImproved.prototype);
