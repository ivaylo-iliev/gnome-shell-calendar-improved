/* ------------------------------------------------------------------------- */
// eslint configuration for this file
//

/* global imports */

/* exported SettingsRegistry */
/* exported EventMessageImproved2 */
/* exported EventMessageImprovedFactory */


/* ------------------------------------------------------------------------- */
// enforce strict mode
"use strict";


/* ------------------------------------------------------------------------- */
// system libraries imports


/* ------------------------------------------------------------------------- */
// gnome shell imports
const gsExtensionUtils = imports.misc.extensionUtils;


/* ------------------------------------------------------------------------- */
// extensions imports
const Extension = gsExtensionUtils.getCurrentExtension();
const Convenience = Extension.imports.lib.convenience;
const Utils = Extension.imports.lib.utils;


/* ------------------------------------------------------------------------- */
var SettingsRegistry = class SettingsRegistry {

  /* ....................................................................... */
  constructor() {
    let settingsSchemaName;

    this._boundSettings = new Object();

    // null-out all the properties
    this._boundSettings._canClose = null;
    this._boundSettings._dimPastEvents = null;
    this._boundSettings._dimPastEventsOpacity = null;
    this._boundSettings._collapsePastEvents = null;
    this._boundSettings._enableBadgeInProgress = null;
    this._boundSettings._badgeInProgressBackgroundColour = null;
    this._boundSettings._badgeInProgressTextColour = null;
    this._boundSettings._enableUpcomingBadge = null;
    this._boundSettings._badgeUpcomingMinutes = null;
    this._boundSettings._badgeUpcomingBackgroundColour = null;
    this._boundSettings._badgeUpcomingTextColour = null;
    this._boundSettings._showIcons = null;
    this._boundSettings._enableContextualIcons = null;
    this._boundSettings._eventInProgressIcon = null;
    this._boundSettings._eventTodaysAllDayIcon = null;
    this._boundSettings._eventTodaysPastIcon = null;
    this._boundSettings._eventPastIcon = null;
    this._boundSettings._eventPastAllDayIcon = null;
    this._boundSettings._eventFutureIcon = null;
    this._boundSettings._eventFutureAllDayIcon = null;

    // initialize logger
    this._logger = new Utils.Logger(
      "settingsRegistry.js:SettingsRegistry"
    );

    // signals registry
    this._signalsRegistry = new Utils.SignalsRegistry();

    // get settings
    settingsSchemaName = Extension.metadata["settings-schema"];
    this._settings = Convenience.getSettings(settingsSchemaName);

    this._settingsIdsToProperty = [
      ["disable-event-deletion", "_canClose", this._invertedBoolean],
      ["dim-past-events", "_dimPastEvents", this._boolean],
      ["dim-past-events-opacity", "_dimPastEventsOpacity", this._integer],
      ["collapse-past-events", "_collapsePastEvents", this._boolean],
      ["enable-in-progress-badge", "_enableBadgeInProgress", this._boolean],
      ["badge-in-progress-background-colour",
        "_badgeInProgressBackgroundColour", this._string],
      ["badge-in-progress-text-colour", "_badgeInProgressTextColour",
        this._string],
      ["enable-upcoming-badge", "_enableUpcomingBadge", this._boolean],
      ["badge-upcoming-minutes", "_badgeUpcomingMinutes", this._integer],
      ["badge-upcoming-background-colour", "_badgeUpcomingBackgroundColour",
        this._string],
      ["badge-upcoming-text-colour", "_badgeUpcomingTextColour", this._string],
      ["show-icons", "_showIcons", this._boolean],
      ["enable-contextual-icons", "_enableContextualIcons", this._boolean],
      ["event-icon-in-progress", "_eventInProgressIcon", this._string],
      ["event-icon-todays-all-day", "_eventTodaysAllDayIcon", this._string],
      ["event-icon-todays-past", "_eventTodaysPastIcon", this._string],
      ["event-icon-past", "_eventPastIcon", this._string],
      ["event-icon-past-all-day", "_eventPastAllDayIcon", this._string],
      ["event-icon-future", "_eventFutureIcon", this._string],
      ["event-icon-future-all-day", "_eventFutureAllDayIcon", this._string],
      ["enable-event-popover", "_enableEventPopover", this._boolean],
      ["event-popover-width", "_eventPopoverWidth", this._integer],
      ["event-popover-height", "_eventPopoverHeight", this._integer],
    ];

  }

  /* ....................................................................... */
  init() {
    for (let [settingId, propertyName, updateFunc]
      of this._settingsIdsToProperty) {

      // bind the function to "this"
      let updateMethod = updateFunc.bind(this);

      // update the setting right now
      this._boundSettings[propertyName] = updateMethod(settingId);

      // add a signal
      this._signalsRegistry.addWithLabel(
        "settingsManager",
        [
          this._settings,
          `changed::${settingId}`,
          this._updatePropertyFromSettingFactory(
            settingId,
            propertyName,
            updateMethod
          )
        ]
      );
    }
  }

  /* ....................................................................... */
  destroy() {
    this._signalsRegistry.destroy();
  }

  /* ....................................................................... */
  get boundSettings() {
    return this._boundSettings;
  }

  /* ....................................................................... */
  _updatePropertyFromSettingFactory(settingId, propertyName, updateMethod) {
    return function _updatePropertyFromSetting() {
      this._boundSettings[propertyName] = updateMethod(settingId);
    }.bind(this);
  }

  /* ....................................................................... */
  _boolean(settingId) {
    return this._settings.get_boolean(settingId);
  }

  /* ....................................................................... */
  _invertedBoolean(settingId) {
    return !this._boolean(settingId);
  }

  /* ....................................................................... */
  _string(settingId) {
    return this._settings.get_string(settingId);
  }

  /* ....................................................................... */
  _integer(settingId) {
    return this._settings.get_int(settingId);
  }

};
