/* ------------------------------------------------------------------------- */
// eslint configuration for this file
//

/* exported CalendarEventImproved */


/* ------------------------------------------------------------------------- */
// enforce strict mode
"use strict";


/* ------------------------------------------------------------------------- */
// gnome shell imports


/* ------------------------------------------------------------------------- */
// extension imports


/* ------------------------------------------------------------------------- */
// globals


/* ------------------------------------------------------------------------- */
var CalendarEventImproved = class CalendarEventImproved {

  /* ....................................................................... */
  constructor(id, date, end, summary, allDay, description) {
    this.id = id;
    this.date = date;
    this.end = end;
    this.summary = summary;
    this.description = description;
    this.allDay = allDay;
  }
};

