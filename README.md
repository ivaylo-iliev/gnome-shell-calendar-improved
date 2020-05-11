# Calendar Improved

Improved, human friendly calendar

![screenshot](https://codeberg.org/human.experience/gnome-shell-calendar-improved/raw/branch/master/media/view_calendar1.png)

## Features

* Show event time labels in "human", with past and future verbiage. Supported languages include:
  - English
  - Translations welcome
* Events
  - Disabling of event deletion [default]
  - Dimming past events [default]
    + configurable opacity [default]
  - Collapsed past event, only showing the title [default]
* Badges
  - Show "In progress" badge for current events [default]
    + configurable background colour and text colour
    + optional theme support for colours
  - Show "Upcoming" badge for upcoming event [default]
    + configurable "minute before" interval [default: 30]
    + configurable background colour and text colour
    + optional theme support for colours
* Icons
  - Show icons [default]
    + Show configurable contextual icons for different types of events [default]
      * In progress event
      * Today's all day event
      * Todays past event
      * Past event
      * Past all day event
      * Future event
      * Future all day event

## Requirements

Gnome Shell

* 3.28
* 3.30
* 3.32
* 3.34
* 3.36

## Installation

Gnome Extensions Site: [https://extensions.gnome.org/extension/2386/calendar-improved/](https://extensions.gnome.org/extension/2386/calendar-improved/)

## Usage

Click on the calendar.

### Preferences

Most features are configurable from the standard gnome extension preferences
dialog.

## Debugging and Development

If you encounter a problem you can enable the debug logs with:
```
dbus-send \
  --session \
  --type=method_call \
  --dest=org.gnome.Shell \
  /org/gnome/Shell \
  org.gnome.Shell.Eval string:"
  window.calendarImproved.debug = true;
  " \
;
```

Then tail the logs using:
```
journalctl \
  /usr/bin/gnome-shell \
  --follow \
  --output=cat \
| grep "\[calendar-improved\]" \
;
```

### Development tool-chain

Most development tasks can be performed use included Makefile.

#### System prerequisites

Development can be done using nested Xorg Xephyr session + gnome-shell or
directly forked off gnome-shell in Wayland.

Xephyr is available in most distributions, please use your package manager
to install it.

Additionally Python 3 (>3.6) and NodeJS >= 11.x are used during development.
Make sure they are installed as well using your package manager and available
in the PATH

#### Makefile

A handy Makefile bootstrap capable of handling most development, once above
system prerequisites are installed. It's strongly suggested you use the
Makefile as it sets up a sandboxed Gnome Shell Extension development
environment.

Set up development tooling using:
```
make develop
```

Now you can make the installed tooling available in your PATH by sourcing
the generated `activate.sh` This will also prepend your terminals BASH
prompt with project name for easier recognition.


Activate the development environment:
```
source activate.sh
```

Note: to restore your environment run:
```
calendar_improved_deactivate
```

To test extension in X use:
```
make x11
```

To test extension in Wayland use:
```
make wayland
```

To build the extension use:
```
make build
```

To build a distribution (zip archive) use:
```
make dist
```

#### Linting

Any code submission will need to be linted against standards in the repository.
Project ESLint specifications are located in `.eslintrc.json`.

To lint code use:
```
make lint
```

## References

* [http://gjs.guide/](http://gjs.guide/)
* [https://gjs-docs.gnome.org/](https://gjs-docs.gnome.org/)
* [https://wiki.gnome.org/Projects/GnomeShell/Development](https://wiki.gnome.org/Projects/GnomeShell/Development)
* [https://developer.gnome.org](https://developer.gnome.org)
* [https://developer.gnome.org/glib/stable/gvariant-text.html](https://developer.gnome.org/glib/stable/gvariant-text.html)
* [https://github.com/zhanghai/gnome-shell-extension-es6-class-codemod](https://github.com/zhanghai/gnome-shell-extension-es6-class-codemod)
* [https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-28/js/ui/calendar.js](https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-28/js/ui/calendar.js)
* [https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-28/js/ui/messageList.js](https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-28/js/ui/messageList.js)
* [https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-30/js/ui/calendar.js](https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-30/js/ui/calendar.js)
* [https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-30/js/ui/messageList.js](https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-30/js/ui/messageList.js)
* [https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-32/js/ui/calendar.js](https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-32/js/ui/calendar.js)
* [https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-32/js/ui/messageList.js](https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-32/js/ui/messageList.js)
* [https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-34/js/ui/calendar.js](https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-34/js/ui/calendar.js)
* [https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-34/js/ui/messageList.js](https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-34/js/ui/messageList.js)

