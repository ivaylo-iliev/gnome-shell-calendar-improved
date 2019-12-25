/* ------------------------------------------------------------------------- */
// eslint configuration for this file
//

/* global imports */
/* global _ */
/* global C_ */

/* exported EventMessageImprovedFactory */


/* ------------------------------------------------------------------------- */
// enforce strict mode
"use strict";


/* ------------------------------------------------------------------------- */
// system libraries imports
const Clutter = imports.gi.Clutter;
const Gettext = imports.gettext;
const GLib = imports.gi.GLib;
const St = imports.gi.St;


/* ------------------------------------------------------------------------- */
// gnome shell imports
const gsCalendar = imports.ui.calendar;
const gsMessageList = imports.ui.messageList;

const gsExtensionUtils = imports.misc.extensionUtils;
const gsUtil = imports.misc.util;


/* ------------------------------------------------------------------------- */
// extensions imports
const Extension = gsExtensionUtils.getCurrentExtension();
const Utils = Extension.imports.lib.utils;


/* ------------------------------------------------------------------------- */
function EventMessageImprovedFactory(settings) {

  /* ----------------------------------------------------------------------- */
  class EventMessageImproved extends gsMessageList.Message {

    /* ..................................................................... */
    constructor(event, date) {

      // call parent constructor with empty title (we set it Later)
      // this behaviour change in 3.32 (see bellow) but still work
      // https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-30/js/ui/calendar.js#L709
      // https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-32/js/ui/calendar.js#L661
      super("", event.summary);
      // store even object for future reference
      this._event = event;

      // store date for future reference
      this._date = date;

      // logger
      this._logger = new Utils.Logger("eventMessageImproved.js");

      // assign settings passing to to the factory method
      this._settings = settings;

      // signals registry for this instance
      this._signalsRegistry = new Utils.SignalsRegistry();

      // set title
      super.setTitle(this._formatEventTime());

      // decorate events
      this._decorateEvents();

    }

    /* ..................................................................... */
    canClose() {
      // always return false for any method that checks that
      return this._settings._canClose;
    }

    close() {
      // apparently _onKeyPressed handler bound to 'key-pressed' event checks
      // Delete/KP_Delete key and calls close method which emits 'close' signal
      // for message object which deletes the even ideally, we should
      // disconnect the even which requires access to messageList meanwhile
      // though let's override close method to stop the deletion via keypress
      if (this._settings._canClose === true) {
        super.close();
      }
    }

    /* ..................................................................... */
    _onClicked() {
      this._logger.debug(this._event.description);
    }

    /* ..................................................................... */
    _decorateEvents() {

      let periodBegin;
      let periodEnd;
      let allDay;
      let now;
      let nowDate;
      let eventStart;

      //let nowTime;
      //let eventStartDate;
      //let eventStartTime;

      periodBegin = gsCalendar._getBeginningOfDay(this._date);
      periodEnd = gsCalendar._getEndOfDay(this._date);
      allDay = (this._event.allDay || (this._event.date <= periodBegin &&
                                       this._event.end >= periodEnd));

      now = new Date();
      nowDate = now.getDate();
      //nowTime = now.getTime();

      eventStart = this._event.date;
      //eventStartDate = this._event.date.getDate();
      //eventStartTime = this._event.date.getTime();

      let eventEnd = this._event.end;
      let eventEndDate = this._event.end.getDate();
      //let eventEndTime = this._event.end.getTime();

      // all day events
      if (allDay) {
        // past all day event events
        if (this._date.getDate() < nowDate) {
          this._setIconByName(this._settings._eventPastAllDayIcon);
        }
        // today's all day event
        else if (this._date.getDate() == nowDate) {
          this._setIconByName(this._settings._eventTodaysAllDayIcon);
        }
        // future all day events
        else if (this._date.getDate() > nowDate) {
          this._setIconByName(this._settings._eventFutureAllDayIcon);
        }
      }
      else {
        // past events
        if (now > eventEnd) {
          // today's past events
          if (nowDate == eventEndDate) {
            this._setIconByName(this._settings._eventTodaysPastIcon);
            this._maybeDimEvent();
            this._maybeCollapseEvent();
            this._maybeSetupEventDimmingAndCollapsingSignals();

          }
          // past events (not today)
          else {
            this._setIconByName(this._settings._eventPastIcon);
          }
          this._setTimeSpanLabelToDates(null, eventEnd);
        }
        // current events
        else if (now >= eventStart && now <= eventEnd) {
          // in progress event
          this._setIconByName(this._settings._eventInProgressIcon);
          // TODO: move logic to _setTimeSpanLabelToDates
          this._setTimeSpanLabelToInProgress();
        }
        // future events
        else if (now < eventStart) {
          this._setIconByName(this._settings._eventFutureIcon);
          this._setTimeSpanLabelToDates(eventStart, null);
        }
      }
    }

    /* ..................................................................... */
    _maybeSetupEventDimmingAndCollapsingSignals() {

      if (this._settings._dimPastEvents === false &&
          this._settings._collapsePastEvents === false) {
        this._signalsRegistry.removeWithLabel("event.dim_and_collapse");
      }
      else {
        // add signal handles to dim and undim on mouse over/out and keyboard
        // focus in/out
        this._signalsRegistry.addWithLabel(
          "event.dim_and_collapse",
          // add key hover event handler
          [
            this.actor,
            "notify::hover",
            this._onPastEventHover.bind(this)
          ],
          // add key focus in event handler
          [
            this.actor,
            "key-focus-in",
            this._onKeyFocusIn.bind(this)
          ],
          // add key focus out event handler
          [
            this.actor,
            "key-focus-out",
            this._onKeyFocusOut.bind(this)
          ]
        );
      }
    }

    /* ..................................................................... */
    _setBuiltInIcon() {
      this._icon = new St.Icon({ icon_name: "x-office-calendar-symbolic" });
      //this.setIcon(this._icon);

      this.actor.connect("style-changed", () => {
        let iconVisible =
          this.actor.get_parent().has_style_pseudo_class("first-child");
        this._icon.opacity = (iconVisible ? 255 : 0);
      });
    }

    /* ..................................................................... */
    _setIconByName(icon_name) {
      if (this._settings._showIcons === true) {
        if (this._settings._enableContextualIcons === true) {
          this._icon = new St.Icon({icon_name: icon_name});
        }
        else if (this._settings._enableContextualIcons === false) {
          this._setBuiltInIcon();
        }
      }
      else if (this._settings._showIcons === false) {
        this._icon = null;
      }

      this.setIcon(this._icon);
    }

    /* ..................................................................... */
    _setTimeSpanLabelToDates(startDatetime, endDatetime) {

      let labels;
      let timeLabel;
      let labelCaption;

      labels = [];
      if (endDatetime !== null) {
        labels.push(_formatPastTimeSpan(endDatetime));
      }
      if (startDatetime !== null) {
        labels.push(_formatFutureTimeSpan(startDatetime));
      }

      labelCaption = labels.join(", ");
      timeLabel = this._createTimeLabel(labelCaption);

      this._maybeSetUpcomingBadge(timeLabel, startDatetime);
      this.setSecondaryActor(timeLabel);
    }

    /* ..................................................................... */
    _setTimeSpanLabelToInProgress() {

      let labelCaption;
      let timeLabel;
      let timeLabelCssStyle;

      labelCaption = Gettext.gettext("in progress");
      timeLabel = this._createTimeLabel(labelCaption);

      if (this._settings._enableBadgeInProgress === true) {
        timeLabelCssStyle = this._makeBadgeCssStyle(
          this._settings._badgeInProgressBackgroundColour,
          this._settings._badgeInProgressTextColour
        );
        timeLabel.set_style(timeLabelCssStyle);
      }
      this.setSecondaryActor(timeLabel);
    }

    /* ..................................................................... */
    _maybeSetUpcomingBadge(timeLabel, startDatetime) {

      let glibDatetime;
      let minutesSince;
      let now;
      let timeSpan;
      let timeLabelCssStyle;

      if (this._settings._enableUpcomingBadge === true) {
        glibDatetime = GLib.DateTime.new_from_unix_local(startDatetime / 1000);
        now = GLib.DateTime.new_now_local();
        timeSpan = now.difference(glibDatetime);
        minutesSince = Math.abs(timeSpan / GLib.TIME_SPAN_MINUTE);

        if (minutesSince < this._settings._badgeUpcomingMinutes) {
          timeLabelCssStyle = this._makeBadgeCssStyle(
            this._settings._badgeUpcomingBackgroundColour,
            this._settings._badgeUpcomingTextColour
          );
          timeLabel.set_style(timeLabelCssStyle);
        }
      }
    }

    /* ..................................................................... */
    _makeBadgeCssStyle(backgroundColour, textColour) {
      return `
        background-color: ${backgroundColour};
        color: ${textColour};
        border-radius: 25px;
        padding-left: 5px;
        padding-right: 5px;
      `;
    }


    /* ..................................................................... */
    _createTimeLabel(caption) {

      let label;

      label = new St.Label({
        style_class: "event-time",
        x_align: Clutter.ActorAlign.START,
        y_align: Clutter.ActorAlign.CENTER
      });

      // set caption when label has been mapped
      this._signalsRegistry.addWithLabel(
        "event.all",
        [
          label,
          "notify::mapped",
          () => {
            if (label.mapped) {
              label.text = caption;
            }
          }
        ]
      );
      return label;
    }

    /* ..................................................................... */
    _maybeUndimEvent() {
      if (this._settings._dimPastEvents === true) {
        this._iconBin.opacity = 255;
        this.titleLabel.opacity = 255;
        this._bodyStack.opacity = 255;
        this._secondaryBin.opacity = 255;
      }
    }

    /* ..................................................................... */
    _maybeDimEvent() {
      if (this._settings._dimPastEvents === true) {
        this._iconBin.opacity = this._settings._dimPastEventsOpacity;
        this.titleLabel.opacity = this._settings._dimPastEventsOpacity;
        this._bodyStack.opacity = this._settings._dimPastEventsOpacity;
        this._secondaryBin.opacity = this._settings._dimPastEventsOpacity;
      }
    }

    /* ..................................................................... */
    _maybeCollapseEvent() {
      if (this._settings._collapsePastEvents === true) {
        this._bodyStack.hide();
      }
    }

    /* ..................................................................... */
    _maybeUncollapseEvent() {
      if (this._settings._collapsePastEvents === true) {
        this._bodyStack.show();
      }
    }

    /* ..................................................................... */
    _onPastEventHover() {
      // if hovering then undim the ever
      if (this.actor.get_hover() === true) {
        this._maybeUndimEvent();
        this._maybeUncollapseEvent();
      }
      // if no longer hovering then dim the event
      else {
        this._maybeDimEvent();
        this._maybeCollapseEvent();
      }
    }

    /* ..................................................................... */
    _onKeyFocusIn() {
      this._maybeUndimEvent();
      this._maybeUncollapseEvent();
    }

    /* ..................................................................... */
    _onKeyFocusOut() {
      this._maybeDimEvent();
      this._maybeCollapseEvent();
    }

    /* ..................................................................... */
    _onDestroy() {
      // destroy all the signals we connected
      this._signalsRegistry.destroy();
      // nothing in parent now, leave this for the future?
      //super._onDestroy();
    }

    /* ..................................................................... */
    _formatEventTime() {

      let allDay;
      let ellipsisChar;
      let periodBegin;
      let periodEnd;
      let rtl;
      let title;

      // ... character used in title for events spanning more then a day
      ellipsisChar = "\u2026";

      // get the datetime beginning of the day for this._date
      periodBegin = gsCalendar._getBeginningOfDay(this._date);
      // get the datetime end of the day for this._date
      periodEnd = gsCalendar._getEndOfDay(this._date);

      // determine if the even spans at least 1 day either explicitly via
      // an even all day flag or by checking if event start and end dates
      // are outside of the this._date day period
      allDay = (this._event.allDay || (this._event.date <= periodBegin &&
                                       this._event.end >= periodEnd));

      // for all day character, either explicitly defined or determined to be
      // because they span most then 1 day set the title to "All day"
      if (allDay) {
        /* Translators: Shown in calendar event list for all day events
         * Keep it short, best if you can use less then 10 characters
         */
        title = C_("event list time", "All Day");
      // for events that do not span days create a title with dash separated
      // starting and ending date
      } else {
        title = gsUtil.formatTime(this._event.date, { timeOnly: true }) +
                " - " +
                gsUtil.formatTime(this._event.end, { timeOnly: true });
      }

      // determine the text direction for current environment
      rtl = Clutter.get_default_text_direction()
            == Clutter.TextDirection.RTL;

      // for events that start before the beginning of the day and are not
      // explicitly marked as all day events prepend "..." character
      // "prepend" is language specific, respecting right/left orientation
      if (this._event.date < periodBegin && !this._event.allDay) {
        if (rtl) {
          title = title + ellipsisChar;
        }
        else {
          title = ellipsisChar + title;
        }
      }

      // for events that stop after the end of the day and are not
      // explicitly marked as all day events append "..." character
      // "append" is language specific, respecting right/left orientation
      if (this._event.end > periodEnd && !this._event.allDay) {
        if (rtl) {
          title = ellipsisChar + title;
        }
        else {
          title = title + ellipsisChar;
        }
      }
      return title;
    }

  }

  return EventMessageImproved;

}

/* ------------------------------------------------------------------------- */
function _formatPastTimeSpan(dateTime) {

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
function _formatFutureTimeSpan(datetime) {

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
