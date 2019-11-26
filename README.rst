#################
Calendar Improved
#################

Improved, human friendly Gnome Shell calendar.

.. image:: https://human.experience/gnome-shell-extension-calendar-improved/media/view_calendar1.png

Features
========

* Human friendly event time, with past and future wording
* Supported languages

  - English
  - Translations welcome

* Events

  - Disabling of event deletion [default]

  - Dimming of past events [default]

    + configurable opacity [default]

  - Collapsing of past event, showing only event time [default]

* Badges

  - Show "In progress" badge for current events [default]

    + configurable background colour and text colour
    + optional theme support for colours

  - Show "Upcoming" badge for upcoming event [default]

     + configurable "minute before" interval [default: 300]
     + configurable background colour and text colour
     + optional theme support for colours

* Icons

  - Show icons [default]

    + Show configurable contextual icons for different event types [default]

      * In progress event

      * Today's all day event

      * Todays past event

      * Past event

      * Past all day event

      * Future event

      * Future all day event


Requirements
============

Gnome Shell

* 3.28
* 3.30
* 3.32
* 3.34


Installation
============

Gnome Extensions Site: https://extensions.gnome.org/extension/2386/calendar-improved/


Usage
=====

Click on the calendar and any day that has event.


Preferences
-----------

Most features are configurable from the standard gnome extension preferences
dialog.


Debugging and Development
=========================

If you encounter a problem you can enable the debug logs with;

.. code-block:: shell

    busctl \
      --user \
      call org.gnome.Shell \
      /org/gnome/Shell \
      org.gnome.Shell Eval \
        s 'window.calendar_improved.debug = true;' \
    ;


Then tail the logs use:

.. code-block:: shell

   journalctl /usr/bin/gnome-shell -f -o cat | grep "\[calendar-improved\]"


Development tool-chain
----------------------

Most development tasks can be done use include Makefile

System prerequisites
~~~~~~~~~~~~~~~~~~~~

Development can be done using nested Xorg Xephyr session + gnome-shell or
directly forked off gnome-shell in Wayland.

Xephyr is available in most distributions, please use your package manager
to install it.

Additionally Python 3 (>3.6) and NodeJS >= 11.x are used during development.
Make sure they are installed as well using your package manager and available
in the path


Makefile
~~~~~~~~

A handy Makefile bootstrap capable of handling most development, once above
system prerequisites are installed. It's strongly suggested you use it as it
sets up an isolated Gnome Shell Extension development environment.

Setting up development tooling

.. code-block:: shell

  make develop


Now you can make all the installed tooling available in your PATH by sourcing
a generated `activate.sh`. This will also prepend bash prompt with
`(calender-improved)`

.. code-block:: shell

  source activate.sh


To restore your environment run:

.. code-block:: shell

  calendar_improved_deactivate


To test extension in X use:

.. code-block:: shell

  make x11


To test extension in Wayland use:

.. code-block:: shell

  make wayland


To build the extension use

.. code-block:: shell

  make build


To build a distribution (zip archive) use

.. code-block:: shell

  make dist


Linting
~~~~~~~

Any code submission will need to be linted against standards in the repository

Code should match ESLint specifications in .eslint config file included in the
codebase.

Run linter

.. code-block:: shell

    make lint


References
==========

* https://gjs-docs.gnome.org/
* https://wiki.gnome.org/Projects/GnomeShell/Development
* https://developer.gnome.org
* https://github.com/zhanghai/gnome-shell-extension-es6-class-codemod
* https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-28/js/ui/calendar.js
* https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-28/js/ui/messageList.js
* https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-30/js/ui/calendar.js
* https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-30/js/ui/messageList.js
* https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-32/js/ui/calendar.js
* https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-32/js/ui/messageList.js
* https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-34/js/ui/calendar.js
* https://gitlab.gnome.org/GNOME/gnome-shell/blob/gnome-3-34/js/ui/messageList.js
