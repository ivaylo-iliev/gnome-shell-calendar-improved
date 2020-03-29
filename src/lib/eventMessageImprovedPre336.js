/* ------------------------------------------------------------------------- */
// eslint configuration for this file
//

/* global imports */
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
const gsExtensionUtils = imports.misc.extensionUtils;
const gsMessageList = imports.ui.messageList;
const gsUtil = imports.misc.util;


/* ------------------------------------------------------------------------- */
// extensions imports
const Extension = gsExtensionUtils.getCurrentExtension();
const CalendarEventPopOver = Extension.imports.lib.calendarEventPopOver;
const Compat = Extension.imports.lib.compat;
const DateTimeUtils = Extension.imports.lib.dateTimeUtils;
const Utils = Extension.imports.lib.utils;

/* ------------------------------------------------------------------------- */
var EventMessageImproved;
function EventMessageImprovedFactory(settings) {

  // if already defined return the global instance (ugh, this seems wrong)
  // probably need bind
  if (EventMessageImproved !== undefined) {
    return EventMessageImproved;
  }

  /* ----------------------------------------------------------------------- */
  EventMessageImproved = Compat.registerClass34(class EventMessageImproved
    extends gsMessageList.Message {

    /* ..................................................................... */
    constructor(event, date) {

      // call parent constructor with empty title (we set it Later)
      // this behaviour change in 3.32 (see bellow) but still work
      // eslint-disable-next-line max-len
      // https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-30/js/ui/calendar.js#L709
      // eslint-disable-next-line max-len
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

      // init popover
      this._popOver = null;

      // in gnome 3.36 the _onClicked method and signal was removed
      // so put it back in
      if (Compat.GNOME_VERSION_ABOVE_334 === true) {
        this.connect("clicked", this._onClicked.bind(this));
      }
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
      if (this._settings._enableEventPopover === true ) {
        if (this._popOver === null) {
          this._popOver = new CalendarEventPopOver.CalendarEventPopOver(
            Compat.getActor(this),
            this._event,
            this._settings
          );
        }
        this._popOver.popup();
      }
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
            Compat.getActor(this),
            "notify::hover",
            this._onPastEventHover.bind(this)
          ],
          // add key focus in event handler
          [
            Compat.getActor(this),
            "key-focus-in",
            this._onKeyFocusIn.bind(this)
          ],
          // add key focus out event handler
          [
            Compat.getActor(this),
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

      Compat.getActor(this).connect("style-changed", () => {
        let iconVisible = Compat.getActor(this).get_parent()
          .has_style_pseudo_class("first-child");
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
        labels.push(DateTimeUtils.formatPastTimeSpan(endDatetime));
      }
      if (startDatetime !== null) {
        labels.push(DateTimeUtils.formatFutureTimeSpan(startDatetime));
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
        this._iconBin.child.set_height(16);
        this._iconBin.child.set_width(16);
      }
    }

    /* ..................................................................... */
    _maybeUncollapseEvent() {
      if (this._settings._collapsePastEvents === true) {
        this._bodyStack.show();
        // reset height and width
        this._iconBin.child.set_height(-1);
        this._iconBin.child.set_width(-1);
      }
    }

    /* ..................................................................... */
    _onPastEventHover() {
      // if hovering then undim the ever
      if (Compat.getActor(this).get_hover() === true) {
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

  });

  return EventMessageImproved;

}
