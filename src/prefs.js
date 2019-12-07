/* ------------------------------------------------------------------------- */
// eslint configuration for this file
//
/* global imports */
/* global window */


/* exported buildPrefsWidget */
/* exported init */


/* ------------------------------------------------------------------------- */
// enforce strict mode
"use strict";


/* ------------------------------------------------------------------------- */
// enable global used for debugging
window.calendarImproved = {
  debug: false,
};


/* ------------------------------------------------------------------------- */
// language libraries
//const Lang = imports.lang;


/* ------------------------------------------------------------------------- */
// system libraries imports
const Gdk = imports.gi.Gdk;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Gtk = imports.gi.Gtk;


/* ------------------------------------------------------------------------- */
// gnome shell imports
const gsExtensionUtils = imports.misc.extensionUtils;


/* ------------------------------------------------------------------------- */
// gnome shell imports
const Extension = gsExtensionUtils.getCurrentExtension();


/* ------------------------------------------------------------------------- */
// extension imports
const Convenience = Extension.imports.lib.convenience;
const Utils = Extension.imports.lib.utils;

/* ------------------------------------------------------------------------- */
function init() {
}


/* ------------------------------------------------------------------------- */
function buildPrefsWidget() {

  let preferencesContainer;

  // create preferences container
  preferencesContainer = new PreferencesContainer();

  // show preferences container
  preferencesContainer.showAll();

  // return preferences top level widget to be embedded into preferences window
  return preferencesContainer.getTopLevelWidget();
}


/* ------------------------------------------------------------------------- */
class PreferencesContainer {

  /* ....................................................................... */
  constructor() {

    let settingsSchemaId;
    let preferencesGladeFilePath;

    // initialize preferences logger
    this._logger = new Utils.Logger("prefs.js:PreferencesContainer");

    // get extension setting schema id
    settingsSchemaId = Extension.metadata["settings-schema"];

    // get settings object
    this._settings = Convenience.getSettings(settingsSchemaId);

    // compose preferences.glade path
    preferencesGladeFilePath = GLib.build_filenamev([
      Extension.dir.get_path(),
      "ui",
      "preferences.glade",
    ]);

    // create builder from preferences glade file
    this._builder = Gtk.Builder.new_from_file(preferencesGladeFilePath);

    // get top level widget
    this._topLevelWidget = this._builder.get_object("preferences_viewport");

    // bind settings
    this._bindSettings();

    // connect all the widget signals to their handles
    // this._builder.connect_signals_full(
    //   this._connector.bind(this)
    // );
  }

  /* ....................................................................... */
  showAll() {
    // show top level widget and it's children except those that have
    // show_all set to false
    this._topLevelWidget.show_all();
  }

  /* ....................................................................... */
  getTopLevelWidget() {
    // return top level widget
    return this._topLevelWidget;
  }

  /* ....................................................................... */
  _bindSettings() {
    this._bindEventTabSettings();
    this._bindBadgesTabSettings();
    this._bindIconsTabSettings();
  }

  /* ....................................................................... */
  _bindEventTabSettings() {

    // bind enable settings to active property of badge switches
    this._bindSettingsToGuiElement(
      [
        ["disable-event-deletion", "disable_event_deletion_switch"],
        ["dim-past-events", "dim_past_events_switch"],
        ["collapse-past-events", "collapse_past_events_switch"]
      ],
      "active"
    );

    // bind enable settings to sensitive property of boxes containing dependent
    // GUI elements
    this._bindSettingsToGuiElement(
      [
        [
          "dim-past-events",
          "dim_past_events_opacity_box"
        ],
      ],
      "sensitive"
    );

    // bind setting to a Scale via adjustment workarounds
    this._bindSettingsToScaleViaAdjustment([
      // dim past event opacity bindings
      [
        "dim-past-events-opacity",
        "dim_past_events_opacity_scale"
      ],
    ]);

    this._bindToolButtonClickToSettingReset([
      [
        "dim_past_events_opacity_reset_button",
        "dim-past-events-opacity"
      ]
    ]);


  }

  /* ....................................................................... */
  _bindToolButtonClickToSettingReset(elementsToSettings) {

    // go over each element id and setting id set and bind the tw
    for (let [elementId, settingId] of elementsToSettings) {
      this._builder.get_object(elementId).connect(
        "clicked",
        () => {
          this._settings.reset(settingId);
        }
      );
    }
  }

  /* ....................................................................... */
  // _connector(builder, object, signal, handler) {
  //   object.connect(
  //     signal,
  //     this._signalHandler[handler].bind(this)
  //   );
  // }


  /* ....................................................................... */
  _bindBadgesTabSettings() {

    // bind enable settings to active property of badge switches
    this._bindSettingsToGuiElement(
      [
        ["enable-in-progress-badge", "enable_in_progress_badge_switch"],
        ["enable-upcoming-badge", "enable_upcoming_badge_switch"],
      ],
      "active"
    );

    // bind enable settings to sensitive property of boxes containing dependent
    // GUI elements
    this._bindSettingsToGuiElement(
      [
        ["enable-in-progress-badge", "in_progress_badge_box"],
        ["enable-upcoming-badge", "upcoming_badge_box"]
      ],
      "sensitive"
    );

    // bind colour settings to ColorButtons via EntryBuffer workarounds
    this._bindSettingsToColorButtonsViaEntryBuffer([
      // in progress background colour bindings
      [
        "badge-in-progress-background-colour",
        "in_progress_badge_background_colorbutton",
        "in_progress_badge_background_entrybuffer",
      ],
      // in progress text colour bindings
      [
        "badge-in-progress-text-colour",
        "in_progress_badge_text_colorbutton",
        "in_progress_badge_text_entrybuffer",
      ],
      // upcoming background colour bindings
      [
        "badge-upcoming-background-colour",
        "upcoming_badge_background_colorbutton",
        "upcoming_badge_background_entrybuffer",
      ],
      // upcoming text colour bindings
      [
        "badge-upcoming-text-colour",
        "upcoming_badge_text_colorbutton",
        "upcoming_badge_text_entrybuffer",
      ],
    ]);

    // bind upcoming minute setting to spinbutton
    this._bindSettingsToGuiElement(
      [
        [
          "badge-upcoming-minutes",
          "upcoming_badge_minutes_before_spinbutton",
        ],
      ],
      "value"
    );

    this._bindToolButtonClickToSettingReset([
      [
        "in_progress_badge_background_reset_button",
        "badge-in-progress-background-colour"
      ],
      [
        "in_progress_badge_text_reset_button",
        "badge-in-progress-text-colour"
      ],
      [
        "upcoming_badge_minutes_before_reset_button",
        "badge-upcoming-minutes"
      ],
      [
        "upcoming_badge_background_reset_button",
        "badge-upcoming-background-colour"
      ],
      [
        "upcoming_badge_text_reset_button",
        "badge-upcoming-text-colour"
      ]
    ]);
  }

  /* ....................................................................... */
  _bindIconsTabSettings() {

    // bind enable settings to active property of icon switches
    this._bindSettingsToGuiElement(
      new Map([
        ["show-icons","show_icons_switch"],
        ["enable-contextual-icons", "enable_contextual_icons_switch"],
      ]),
      "active"
    );

    // bind enable settings to sensitive property of boxes containing dependent
    // GUI elements
    this._bindSettingsToGuiElement(
      [
        ["show-icons", "enable_contextual_icons_box"],
        ["enable-contextual-icons", "icons_list_box"],
      ],
      "sensitive"
    );

    // bind icon settings to text property of entry boxes
    this._bindSettingsToGuiElement(
      [
        ["event-icon-in-progress", "in_progress_event_entry"],
        ["event-icon-todays-all-day", "todays_all_day_event_entry"],
        ["event-icon-todays-past", "todays_past_event_entry"],
        ["event-icon-past", "past_event_entry"],
        ["event-icon-past-all-day", "past_all_day_event_entry"],
        ["event-icon-future", "future_event_entry"],
        ["event-icon-future-all-day", "future_all_day_event_entry"],
      ],
      "text"
    );

    // bind icon settings to icon-name property of images
    this._bindSettingsToGuiElement(
      [
        ["event-icon-in-progress", "in_progress_event_image"],
        ["event-icon-todays-all-day", "todays_all_day_event_image"],
        ["event-icon-todays-past", "todays_past_event_image"],
        ["event-icon-past", "past_event_image"],
        ["event-icon-past-all-day", "past_all_day_event_image"],
        ["event-icon-future", "future_event_image"],
        ["event-icon-future-all-day", "future_all_day_event_image"],
      ],
      "icon-name"
    );

    this._bindToolButtonClickToSettingReset([
      ["in_progress_event_reset_button", "event-icon-in-progress"],
      ["todays_all_day_event_reset_button", "event-icon-todays-all-day"],
      ["todays_past_event_reset_button", "event-icon-todays-past"],
      ["past_event_reset_button", "event-icon-past"],
      ["past_all_day_event_reset_button", "event-icon-past-all-day"],
      ["future_event_reset_button", "event-icon-future"],
      ["future_all_day_event_reset_button", "event-icon-future-all-day"]
    ]);

  }

  /* ....................................................................... */
  _bindSettingsToGuiElement(
    settingsToElements,
    propertyName,
    bindFlags=Gio.SettingsBindFlags.DEFAULT) {

    // go over each setting id and element Id set and bind the two
    for (let [settingId, elementId] of settingsToElements) {
      this._settings.bind(
        settingId,
        this._builder.get_object(elementId),
        propertyName,
        bindFlags
      );
    }
  }

  /* ....................................................................... */
  _bindSettingsToScaleViaAdjustment(settingsToElements) {
    for (let [settingId, scaleId] of settingsToElements) {
      this._createScaleBindings(settingId, scaleId);
    }
  }

  /* ....................................................................... */
  _createScaleBindings(settingId, scaleId) {
    // create binding between setting and Adjustment attached to Scale
    // since can not bind to Scale itself
    this._settings.bind(
      settingId,
      this._builder.get_object(scaleId).get_adjustment(),
      "value",
      Gio.SettingsBindFlags.DEFAULT
    );
  }

  /* ....................................................................... */
  _bindSettingsToColorButtonsViaEntryBuffer(settingsToElements) {
    for (let [settingId, colorButtonId, entryBufferId] of settingsToElements) {
      this._createColorButtonBindings(settingId, colorButtonId, entryBufferId);
    }
  }

  /* ....................................................................... */
  /**
   * Creates settings to ColorButton bindings using EntryBuffer element as
   * workaround for binding the setting
   *
   * @param  {String}  settingId      The setting identifier
   * @param  {String}  colorButtonId  The color button identifier
   * @param  {String}  entryBufferId  The entry buffer identifier
   */
  _createColorButtonBindings(settingId, colorButtonId, entryBufferId) {

    let rgba;
    let hexColor;

    // set the RGBA of current setting to ColorButton
    hexColor = this._settings.get_string(settingId);
    rgba = new Gdk.RGBA();
    rgba.parse(hexColor);
    this._builder.get_object(colorButtonId).set_rgba(rgba);

    // create binding between setting and entry buffer component
    this._settings.bind(
      settingId,
      this._builder.get_object(entryBufferId),
      "text",
      Gio.SettingsBindFlags.DEFAULT
    );

    // bind EntryBuffer of updating text property to update ColorButton RGBA
    this._builder.get_object(entryBufferId).connect(
      "notify::text",
      this._entryBufferToColorButtonHandlerFactory(colorButtonId)
    );

    // bind change of color on color button to update the setting
    this._builder.get_object(colorButtonId).connect(
      "notify::color",
      this._colorButtonToSettingHandlerFactory(settingId)
    );

  }

  /* ....................................................................... */
  _entryBufferToColorButtonHandlerFactory(colorButtonId) {

    let eventHandlerFunc;

    // create  handler function to handle EntryBuffer element updates
    eventHandlerFunc = function _colorButtonToEntryBufferHandler(entryBuffer) {
      let rgba;

      // make new RGBA object
      rgba = new Gdk.RGBA();

      // set tot the colour text from entryBuffer
      rgba.parse(entryBuffer.get_text());

      // set rgba object on the the ColorButton
      this._builder.get_object(colorButtonId).set_rgba(rgba);
    };

    // return "this" bound event handler
    return eventHandlerFunc.bind(this);
  }

  /* ....................................................................... */
  _colorButtonToSettingHandlerFactory(settingId) {

    let eventHandlerFunc;

    eventHandlerFunc = function _colorButtonToEntryBufferHandler(colorButton) {

      let rgba;
      let hexColor;
      let currentSettingHexColor;

      // get RGBA colour object from the ColorButton
      rgba = colorButton.get_rgba();

      // convert RGBA color to hex color
      hexColor = this._rgbaToColourHex(rgba);

      // get current setting hex color
      currentSettingHexColor = this._settings.get_string(settingId);

      // update the setting only if does not it match so we avoid updating
      // default to same value
      if (currentSettingHexColor != hexColor) {
        this._settings.set_string(settingId, hexColor);
      }
    };

    // return "this" bound event handler
    return eventHandlerFunc.bind(this);
  }

  /* ....................................................................... */
  /**
   * Return "#" prepended hex 6 character colour representation from a passed
   * in RGBA object (RGBA = Red, Green, Blue, Alpha opactiy).
   *
   * @param      {Gdk.RGBA}  rgba - Gdk RGBA object contain color information
   * @return     {string} - "#" prepended, 6 character color value (#a51560)
   */
  _rgbaToColourHex(rgba) {

    let hexColor;

    // start color hex with #
    hexColor = "#";

    // go over each color channel, convert it to padded hex and append to
    // colorHex
    for (let colorChannelValue of [rgba.red, rgba.green, rgba.blue]) {
      let colorInteger;

      // compose a color channel integer
      colorInteger = colorChannelValue * 255;
      // for all decimal values below 16 which convert to single character in
      // hex (last being 15 = a) convert to hex string and pre-pad it with "0"
      if (colorInteger < 16) {
        hexColor = hexColor +  "0" + colorInteger.toString(16);
      }
      else {
        // otherwise just convert to hex which will be 2 character
        hexColor = hexColor + colorInteger.toString(16);
      }
    }

    return hexColor;
  }

}
