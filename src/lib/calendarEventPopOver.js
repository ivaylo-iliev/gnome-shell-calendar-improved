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

/* ------------------------------------------------------------------------- */
// extension imports
const Extension = gsExtensionUtils.getCurrentExtension();
const Utils = Extension.imports.lib.utils;


/* ------------------------------------------------------------------------- */
var CalendarEventPopOver = class CalendarEventPopOver {

  /* ....................................................................... */
  constructor (actor, event) {
    let popupMenuOwner;

    // COMPAT: pre-gnome 3.34 actor compatability
    let version = imports.misc.config.PACKAGE_VERSION.split(".");
    if (version[0] >= 3 && version[1] > 32) {
      popupMenuOwner = actor;
    }
    else {
      // older versions access actor property of the owner
      popupMenuOwner = {actor:actor};
    }
    this._popOverMenuManager = new gsPopupMenu.PopupMenuManager(
      popupMenuOwner
    );
    this._popOverMenu = new CalendarEventPopOverMenu(actor, event);
    this._popOverMenuManager.addMenu(this._popOverMenu);
  }

  /* ....................................................................... */
  popup() {
    if (this._popOverMenu.isOpen === false) {
      this._popOverMenu.popup();
    }
  }

};


/* ------------------------------------------------------------------------- */
class CalendarEventPopOverMenu extends gsPopupMenu.PopupMenu {

  /* ....................................................................... */
  constructor(actor, event) {

    // show on the right, and arrow to the middle
    super(actor, 0.5, St.Side.RIGHT);

    // store event
    this._event = event;

    // add content menu item
    this.addMenuItem(new CalendarEventPopOverContent(this._event));

    // add it to main ui group so it is a popover
    gsMain.uiGroup.add_actor(this.actor);

    // hide the actor for now
    this.actor.hide();
  }

  popup() {
    this.open(gsBoxPointer.PopupAnimation.FULL);
  }

}


/* ------------------------------------------------------------------------- */
var CalendarEventPopOverContent = Utils.registerClass(
  class CalendarEventPopOverContent extends gsPopupMenu.PopupBaseMenuItem {

    /* ..................................................................... */
    _init(event) {
      super._init({
        activate: false,
        reactive: true,
        hover: false,
        can_focus: false
      });

      this._event = event;

      this._bodyText = "";
      this._useBodyMarkup = true;

      this._render2();

    }

    /* ..................................................................... */
    _render() {
      let clutterActor;

      // create layout
      // this._contentBox = new St.BoxLayout({
      //   style_class: "message-content",
      //   vertical: true,
      //   x_expand: true
      // });

      // make body label
      this._bodyLabel = new gsMessageList.URLHighlighter("",true, true);
      // style body label actor
      //this._bodyLabel.actor.add_style_class_name("message-body");

      // add body label to the context box
      //this._contentBox.add_actor(this._bodyLabel.actor);

      // set body to event description
      this._bodyText = this._event.description;
      this._bodyLabel.setMarkup(
        this._event.description,
        this._useBodyMarkup
      );

      // add content box to this menu
      // COMPAT: pre-gnome 3.34 actor compatability
      clutterActor = (this instanceof Clutter.Actor) ? this : this.actor;
      clutterActor.add_actor(this._bodyLabel);

    }

    /* ..................................................................... */
    _render2() {
      let clutterActor;

      // create layout
      // this._contentBox = new St.BoxLayout({
      //   style_class: "message-content",
      //   vertical: true,
      //   x_expand: true
      // });

      // this works, however generates an insane amount of following errors:
      //   (gnome-shell:151119): Clutter-CRITICAL **: 00:01:02.804:
      //   clutter_input_focus_set_input_panel_state: assertion
      //   'clutter_input_focus_is_focused (focus)' failed
      //
      this._bodyLabel = new St.Entry({
        text: this._event.description,
        style_class: "search-entry",
        name: "body-label",
        track_hover: false,
        reactive: true,
        can_focus: true
      });
      this._bodyLabel.clutter_text.editable = false;
      this._bodyLabel.clutter_text.selectable = true;
      this._bodyLabel.clutter_text.single_line_mode = false;
      this._bodyLabel.clutter_text.line_wrap = true;
      this._bodyLabel.clutter_text.line_wrap_mode = Pango.WrapMode.WORD_CHAR;

      // add body label to the context box
      //this._contentBox.add_actor(this._bodyLabel);

      // add content box to this menu
      // COMPAT: pre-gnome 3.34 actor compatability
      clutterActor = (this instanceof Clutter.Actor) ? this : this.actor;
      clutterActor.add_actor(this._bodyLabel);

    }

  }
);
