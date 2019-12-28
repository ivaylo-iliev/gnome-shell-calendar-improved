/* ------------------------------------------------------------------------- */
// eslint configuration for this file
//

/* global imports */
/* global _ */

/* exported formatPastTimeSpan */
/* exported formatFutureTimeSpan */


/* ------------------------------------------------------------------------- */
// enforce strict mode
"use strict";


/* ------------------------------------------------------------------------- */
// system libraries imports
const Gettext = imports.gettext;
const GLib = imports.gi.GLib;


/* ------------------------------------------------------------------------- */
function formatPastTimeSpan(dateTime) {

  let daysAgo;
  let glibDateTime;
  let hoursAgo;
  let minutesAgo;
  let monthsAgo;
  let now;
  let timeSpan;
  let weeksAgo;
  let yearsAgo;

  glibDateTime = GLib.DateTime.new_from_unix_local(dateTime / 1000);
  now = GLib.DateTime.new_now_local();
  timeSpan = now.difference(glibDateTime);

  minutesAgo = Math.abs(timeSpan / GLib.TIME_SPAN_MINUTE);
  hoursAgo = Math.abs(timeSpan / GLib.TIME_SPAN_HOUR);
  daysAgo = Math.abs(timeSpan / GLib.TIME_SPAN_DAY);
  weeksAgo = Math.abs(daysAgo / 7);
  monthsAgo = Math.abs(daysAgo / 30);
  yearsAgo = Math.abs(weeksAgo / 52);

  if (minutesAgo < 1) {
    return Gettext.ngettext(
      "%d minute ago",
      "%d minute ago",
      1).format(1);
  }

  if (hoursAgo < 1) {
    return Gettext.ngettext(
      "%d minute ago",
      "%d minutes ago",
      minutesAgo).format(minutesAgo);
  }

  if (daysAgo < 1) {
    return Gettext.ngettext(
      "%d hour ago",
      "%d hours ago",
      hoursAgo).format(hoursAgo);
  }

  if (daysAgo < 2) {
    return _("Yesterday");
  }

  if (daysAgo < 15) {
    return Gettext.ngettext(
      "%d day ago",
      "%d days ago",
      daysAgo).format(daysAgo);
  }

  if (weeksAgo < 8) {
    return Gettext.ngettext(
      "%d week ago",
      "%d weeks ago",
      weeksAgo).format(weeksAgo);
  }

  if (yearsAgo < 1) {
    return Gettext.ngettext(
      "%d month ago",
      "%d months ago",
      monthsAgo).format(monthsAgo);
  }

  return Gettext.ngettext(
    "%d year ago",
    "%d years ago",
    yearsAgo).format(yearsAgo);
}


/* ------------------------------------------------------------------------- */
function formatFutureTimeSpan(datetime) {

  let daysSince;
  let glibDateTime;
  let hoursSince;
  let minutesSince;
  let monthsSince;
  let now;
  let timeSpan;
  let weeksSince;
  let yearsSince;

  glibDateTime = GLib.DateTime.new_from_unix_local(datetime / 1000);
  now = GLib.DateTime.new_now_local();
  timeSpan = now.difference(glibDateTime);

  minutesSince = Math.abs(timeSpan / GLib.TIME_SPAN_MINUTE);
  hoursSince = Math.abs(timeSpan / GLib.TIME_SPAN_HOUR);
  daysSince = Math.abs(timeSpan / GLib.TIME_SPAN_DAY);
  weeksSince = Math.abs(daysSince / 7);
  monthsSince = Math.abs(daysSince / 30);
  yearsSince = Math.abs(weeksSince / 52);

  if (minutesSince < 1) {
    return Gettext.ngettext(
      "in %d minute",
      "in %d minute",
      1).format(1);
  }

  if (hoursSince < 1) {
    return Gettext.ngettext(
      "in %d minute",
      "in %d minutes",
      minutesSince).format(minutesSince);
  }

  if (daysSince < 1) {
    return Gettext.ngettext(
      "in %d hour",
      "in %d hours",
      hoursSince).format(hoursSince);
  }

  if (daysSince < 2) {
    return _("Yesterday");
  }

  if (daysSince < 15) {
    return Gettext.ngettext(
      "in %d day",
      "in %d days",
      daysSince).format(daysSince);
  }

  if (weeksSince < 8) {
    return Gettext.ngettext(
      "in %d week",
      "in %d weeks",
      weeksSince).format(weeksSince);
  }

  if (yearsSince < 1) {
    return Gettext.ngettext(
      "in %d month",
      "in %d months",
      monthsSince).format(monthsSince);
  }

  return Gettext.ngettext(
    "in %d year",
    "in %d years",
    yearsSince).format(yearsSince);
}
