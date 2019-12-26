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
const ExtensionUtils = imports.misc.extensionUtils;
const Main = imports.ui.main;
const PopupMenu = imports.ui.popupMenu;
const BoxPointer = imports.ui.boxpointer;
const MessageList = imports.ui.messageList;


/* ------------------------------------------------------------------------- */
// extension imports
const Extension = ExtensionUtils.getCurrentExtension();
const Utils = Extension.imports.lib.utils;


/* ------------------------------------------------------------------------- */
// globals


/* ------------------------------------------------------------------------- */
var CalendarEventPopOver = class CalendarEventPopOver {

  /* ....................................................................... */
  constructor (actor, event) {
    this._popOverMenu = new CalendarEventPopOverMenu(actor, event);
    this._popOverMenuManager = new PopupMenu.PopupMenuManager(actor);
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
class CalendarEventPopOverMenu extends PopupMenu.PopupMenu {

  /* ....................................................................... */
  constructor(actor, event) {

    // TODO: actor bit here for 3.28
    // show on the right, and arrow to the middle
    super(actor, 0.5, St.Side.RIGHT);

    // store event
    this._event = event;

    // add content menu item
    this.addMenuItem(new CalendarEventPopOverContent(this._event));

    // add it to main ui group so it is a popover
    Main.uiGroup.add_actor(this.actor);

    // hide the actor for now
    this.actor.hide();
  }

  popup() {
    this.open(BoxPointer.PopupAnimation.FULL);
  }

}


/* ------------------------------------------------------------------------- */
var CalendarEventPopOverContent = Utils.registerClass(
  class CalendarEventPopOverContent extends PopupMenu.PopupBaseMenuItem {

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

      // create layout
      // this._contentBox = new St.BoxLayout({
      //   style_class: "message-content",
      //   vertical: true,
      //   x_expand: true
      // });

      // make body label
      this._bodyLabel = new MessageList.URLHighlighter("",true, true);
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
      this.add_actor(this._bodyLabel);

    }

    /* ..................................................................... */
    _render2() {

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
      this.add_actor(this._bodyLabel);

    }

  }
);
