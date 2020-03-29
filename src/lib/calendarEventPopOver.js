/* ------------------------------------------------------------------------- */
// eslint configuration for this file
//

/* global imports */

/* exported CalendarEventPopOver */


/* ------------------------------------------------------------------------- */
// enforce strict mode
"use strict";


/* ------------------------------------------------------------------------- */
// system libraries imports
const Clutter = imports.gi.Clutter;
const Pango = imports.gi.Pango;
const St = imports.gi.St;


/* ------------------------------------------------------------------------- */
// gnome shell imports
const gsBoxPointer = imports.ui.boxpointer;
const gsExtensionUtils = imports.misc.extensionUtils;
const gsMain = imports.ui.main;
const gsMessageList = imports.ui.messageList;
const gsPopupMenu = imports.ui.popupMenu;
const gsShellEntry = imports.ui.shellEntry;
const gsUtil = imports.misc.util;


/* ------------------------------------------------------------------------- */
// extension imports
const Extension = gsExtensionUtils.getCurrentExtension();
const Compat = Extension.imports.lib.compat;
const DateTimeUtils = Extension.imports.lib.dateTimeUtils;
const Utils = Extension.imports.lib.utils;


/* ------------------------------------------------------------------------- */
var CalendarEventPopOver = class CalendarEventPopOver {

  /* ....................................................................... */
  constructor (actor, event, settings) {
    let popupMenuOwner;
    let version;

    // initialize logger
    this._logger = new Utils.Logger(
      "calenderEventPopOver.js:CalendarEventPopOver"
    );

    // COMPAT: pre-gnome 3.34 actor compatability
    version = imports.misc.config.PACKAGE_VERSION.split(".");
    if (version[0] >= 3 && version[1] > 32) {
      popupMenuOwner = actor;
    }
    else {
      // older versions access actor property of the owner
      popupMenuOwner = {actor: actor};
    }
    this._popOverMenuManager = new gsPopupMenu.PopupMenuManager(
      popupMenuOwner
    );
    this._popOverMenu = new CalendarEventPopOverMenu(
      actor,
      event,
      settings
    );
    this._popOverMenuManager.addMenu(this._popOverMenu);
  }

  /* ....................................................................... */
  popup() {
    if (this._popOverMenu.isOpen === false) {
      this._popOverMenu.popup();
    }
    else {
      this._popOverMenu.close();
    }

  }

};



/* ------------------------------------------------------------------------- */
class CalendarEventPopOverMenu extends gsPopupMenu.PopupMenu {

  /* ....................................................................... */
  constructor(actor, event, settings) {

    // show on the right, and arrow to the middle
    super(actor, 0.5, St.Side.RIGHT);

    // initialize logger
    this._logger = new Utils.Logger(
      "calenderEventPopOver.js:CalendarEventPopOverMenu"
    );

    // store event
    this._event = event;

    // create content node
    this._content = new CalendarEventPopOverContent(
      this,
      this._event,
      settings
    );

    // add content menu item
    this.addMenuItem(this._content);

    // add it to main ui group so it is a popover
    gsMain.uiGroup.add_actor(this.actor);

    // hide the actor for now
    this.actor.hide();
  }

  popup() {
    this._content.render();
    // show with animation
    this.open(gsBoxPointer.PopupAnimation.FULL);
  }

}


/* ------------------------------------------------------------------------- */
var CalendarEventPopOverContent = Compat.registerClass32(
  class CalendarEventPopOverContent extends gsPopupMenu.PopupBaseMenuItem {

    /* ..................................................................... */
    _init(parent, event, settings) {
      super._init({
        activate: false,
        reactive: true,
        hover: false,
        can_focus: false
      });

      // initialize logger
      this._logger = new Utils.Logger(
        "calenderEventPopOver.js:CalendarEventPopOverContent"
      );

      this._parent = parent;
      this._event = event;
      this._settings = settings;

      // COMPAT: pre-gnome 3.34 actor compatability
      this._clutterActor = Compat.getActor(this);

      this._id = null;
      this._summary = null;
      this._duration = null;
      this._description = null;

    }

    /* ..................................................................... */
    render() {
      let summary;
      let dateSpan;
      let description;
      let maxWidth;
      let maxHeight;
      let btnEdit;

      // destroy any previous childreb before creating them
      this._clutterActor.destroy_all_children();

      // control box
      this._contextBox = new St.BoxLayout({
        style_class: "calendar-improved-layout",
        vertical: true,
        x_expand: true,
        y_expand: true,
      });
      this._clutterActor.add_actor(this._contextBox);

      // create scrollview and add it to the actor
      this._scrollView = new St.ScrollView({
        x_fill: true,
        y_fill: true,
        y_align: St.Align.START,
        overlay_scrollbars: true,
      });
      this._contextBox.add_actor(this._scrollView);

      // create vertical layout that will contain all the information
      // and added it to context box
      this._eventInfoBox = new St.BoxLayout({
        style_class: "calendar-improved-layout",
        vertical: true,
        x_expand: true,
        y_expand: true,
      });
      this._scrollView.add_actor(this._eventInfoBox);

      // create summary with highlighted urls and add it to context box
      summary = this._event.summary.trim();
      this._summary = this._makeURLHighlighter(summary);
      this._eventInfoBox.add_actor(this._summary);

      // create duration and if exists, recuring text
      dateSpan = this._formatDateSpan();
      this._duration = this._makeURLHighlighter(dateSpan);
      this._eventInfoBox.add_actor(this._duration);

      // strip all whitespace from the descriptions
      description = this._event.description.trim();
      // if trimmed description text exists, create description with
      // highlighted urls and add it to content box
      if (description.length > 0 ) {
        this._description = this._makeURLHighlighter(description);
        this._eventInfoBox.add_actor(this._description);
      }

      // create and add edit button the opens gnome-calendar
      btnEdit = new St.Button({
        label: "Edit",
        style_class: "message-list-clear-button button",
        can_focus: true,
      });
      // align to the left
      btnEdit.set_x_align(Clutter.ActorAlign.END);
      btnEdit.connect("button-press-event", () => {
        // close parent menu
        this._parent.close();
        // open event in gnome calendar
        this._openEventInGnomeCalendar();
        return Clutter.EVENT_STOP;
      });
      this._contextBox.add_actor(btnEdit);

      // TODO: try to redo this in css?
      // resize down to max height and max width if over
      // do it in a loop because restricting one dimmension resize the other
      // so we do it in a loom till both are below or equal to maxHeight
      // and maxWidth
      maxWidth = this._settings._eventPopoverWidth;
      maxHeight = this._settings._eventPopoverHeight;
      let parentActor = this._parent.actor;
      while (parentActor.height > maxHeight
             || parentActor.width > maxWidth) {

        if (parentActor.width > maxWidth) {
          parentActor.set_width(maxWidth);
        }

        if (parentActor.height > maxHeight) {
          parentActor.set_height(maxHeight);
        }

      }

    }

    /* ..................................................................... */
    _formatDateSpan() {
      let dateSpan;
      let recurringDate;
      let recurringText;

      [, , recurringDate] = this._event.id.split("\n");
      // compose recuring text
      if (recurringDate.length > 0) {
        recurringText = "\nRecuring";
      }
      else {
        recurringText = "";
      }
      dateSpan = ""
        + DateTimeUtils.formatSimpleDateTime(this._event.date)
        + " - \n"
        + DateTimeUtils.formatSimpleDateTime(this._event.end)
        + recurringText;

      return dateSpan;

    }

    /* ..................................................................... */
    _makeURLHighlighter(text, multiLine=true) {
      let urlHighlighter;

      urlHighlighter = new gsMessageList.URLHighlighter(
        text,
        true,
        multiLine
      );

      let urlHighlighterActor = Compat.getActor(urlHighlighter);
      urlHighlighterActor.clutter_text.ellipsize = Pango.EllipsizeMode.NONE;

      return urlHighlighterActor;
    }

    /* ..................................................................... */
    _openEventInGnomeCalendar() {
      let eventUuidArray;
      let eventUuid;

      // compose gnome calendar uuid from event.id, which contains
      // calendar uuid, event uuid, and optionally event recurrence timestamp
      // all separated by new lines
      // meanwhile the event id given to gnome calendar should have all of
      // the above element separated by ":" with the recurrence timestamp
      // being optional
      eventUuidArray = this._event.id.split("\n");
      // if recurrance timestamp is missing join only the first to element
      // using ":" separator, otherwise join all of them
      if (eventUuidArray[2] === "") {
        eventUuid = eventUuidArray.splice(0,2).join(":");
      }
      else {
        eventUuid = eventUuidArray.join(":");
      }
      // run gnome calendar
      gsUtil.spawn(
        [
          "gnome-calendar",
          "--uuid",
          eventUuid
        ]
      );
    }

    /* ..................................................................... */
    _openEventInEvolutionCalendar() {
      let eventUuidArray;
      let eventURI;

      /* ugh, this works only if evoluton is already open
       * otherwise we get
       * (evolution:14976): module-calendar-WARNING **: 21:28:03.363:
       * (/build/evolution-86Sr5C/evolution-3.28.5/src/modules/calendar/
       * e-cal-base-shell-backend.c:727):
       * e_cal_base_shell_backend_util_handle_uri: code should not be reached
      */

      // https://gitlab.gnome.org/GNOME/gnome-shell/issues/262#note_541033
      // https://gitlab.gnome.org/GNOME/evolution/issues/509#note_541031

      eventUuidArray = this._event.id.split("\n");
      // if recurrance timestamp is missing join only the first to element
      // using ":" separator, otherwise join all of them
      if (eventUuidArray[2] === "") {
        eventURI = "calendar:///?source-uid=%s&comp-uid=%s"
          .format(...eventUuidArray.splice(0,2));

      }
      else {
        eventURI = "calendar:///?source-uid=%s&comp-uid=%s&comp-rid=%s"
          .format(...eventUuidArray);
      }

      gsUtil.spawn(
        [
          "evolution",
          eventURI
        ]
      );

    }

    /* ..................................................................... */
    _makeEntry(params, multiLine=true) {
      let entry;

      /* example:
        this._description = this._makeEntry(
          {
            text: description,
            style_class: "message-description",
            track_hover: false,
            reactive: true,
            can_focus: true,
          }
        );
      */

      // clutter bug?: combination of
      // single_line_mode=false/selectable=true/editable=false
      // generates an insane amount of following errors:
      //   (gnome-shell:151119): Clutter-CRITICAL **: 00:01:02.804:
      //   clutter_input_focus_set_input_panel_state: assertion
      //   'clutter_input_focus_is_focused (focus)' failed
      entry = new St.Entry(params);
      entry.clutter_text.editable = false;
      entry.clutter_text.selectable = true;
      if (multiLine === true) {
        entry.clutter_text.single_line_mode = false;
        entry.clutter_text.line_wrap = true;
        entry.clutter_text.line_wrap_mode = Pango.WrapMode.WORD_CHAR;
      }
      gsShellEntry.addContextMenu(entry);

      return entry;
    }

  }

);
