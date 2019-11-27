#!/usr/bin/env python3

# ........................................................................... #
import os
import pytz
import sys
import uuid

from datetime import datetime
from datetime import timedelta

from enum import Enum

from typing import List

from icalendar import Calendar
from icalendar import Event
from icalendar import vCalAddress
from icalendar import vText


# ........................................................................... #
class ParticipantType(Enum):
  CHAIR = "CHAIR"
  REQUIRED = 'REQ-PARTICIPANT'


# ........................................................................... #
class Participant:

  def __init__(self, email:str, name:str, role:ParticipantType):
    self.email:str = email
    self.name:str = name
    self.role:ParticipantType = role

  def to_ical(self):
    participant = vCalAddress("MAILTO:%s" % self.email)
    participant.params["cn"] = vText(self.name)
    participant.params["role"] = vText(self.role)
    return participant


# ........................................................................... #
def main(argv:list):
  output_file_path:str = ""
  error_message:str = ""

  if len(argv) == 1:
    output_file_path = argv[0]
    if is_valid_path(output_file_path):
      make_calendar(output_file_path)
    else:
      print(
        "given output file path is not in an existing folder",
        file=sys.stderr
      )
      sys.exit(1)
  else:
    print(
      "please only provide an output file path",
      file=sys.stderr
    )
    sys.exit(1)

# ........................................................................... #
def add_events(calendar):


  # ~~~~~ #
  events_info = (

    {
      "title": "Event: All day today",
      "day": "all-day",
    },

    {
      "title": "Event: 12am - 4am",
      "day": "today",
      "start": {"hour": 0, "minute": 0},
      "end": {"hour": 4, "minute": 0 },
    },

    {
      "title": "Event: 04am - 08am",
      "day": "today",
      "start": {"hour": 4, "minute": 0},
      "end": {"hour": 8, "minute": 0 },
    },

    {
      "title": "Event: 08am - 12pm",
      "day": "today",
      "start": {"hour": 8, "minute": 0},
      "end": {"hour": 12, "minute": 0 },
    },

    {
      "title": "Event: 12pm - 04pm",
      "day": "today",
      "start": {"hour": 12, "minute": 0},
      "end": {"hour": 16, "minute": 0 },
    },

    {
      "title": "Event: 04pm - 08pm",
      "day": "today",
      "start": {"hour": 16, "minute": 0},
      "end": {"hour": 20, "minute": 0 },
    },

    {
      "title": "Event: 08pm - 12am",
      "day": "today",
      "start": {"hour": 20, "minute": 0},
      "end": {"hour": 23, "minute": 59 },
    },
  )

  # ~~~~~ #
  local_timezone = datetime.astimezone(datetime.now()).tzinfo
  now = datetime.now()
  tomorrow = now + timedelta(days=1)

  # ~~~~~ #
  for event_info in events_info:

    # ~~~~~ #
    if event_info["day"] == "today":

      start_year = now.year
      start_month = now.month
      start_day = now.day
      start_hour = event_info["start"]["hour"]
      start_minute = event_info["start"]["minute"]

      end_year = now.year
      end_month = now.month
      end_day = now.day
      end_hour = event_info["end"]["hour"]
      end_minute = event_info["end"]["minute"]

    elif event_info["day"] == "all-day":

      start_year = now.year
      start_month = now.month
      start_day = now.day
      start_hour = 0
      start_minute = 0

      end_year = tomorrow.year
      end_month = tomorrow.month
      end_day = tomorrow.day
      end_hour = 0
      end_minute = 0

    # add the event to the calendar:
    event = make_event(
      summary=event_info["title"],
      location="Anywhere",
      start_time=datetime(
        year=start_year,
        month=start_month,
        day=start_day,
        hour=start_hour,
        minute=start_minute,
        second=0,
        tzinfo=local_timezone
      ),
      end_time=datetime(
        year=end_year,
        month=end_month,
        day=end_day,
        hour=end_hour,
        minute=end_minute,
        second=0,
        tzinfo=local_timezone
      ),
      organizer=Participant(
        email="organizer@example.com",
        name="Orga Nizer",
        role=ParticipantType.CHAIR
      ),
      attendees=[
        Participant(
          email="participant1@example.com",
          name="Par Ticip, Ant",
          role=ParticipantType.REQUIRED
        ),
        Participant(
          email="participant2@example.com",
          name="Parti, Cipant",
          role=ParticipantType.REQUIRED
        ),
      ]
    )

    # ~~~~~ #
    # add event to the calendar
    calendar.add_component(event)


# ........................................................................... #
def make_calendar(output_file_path:str):

  # calendar instance
  calendar:Calendar = Calendar()

  # ical format version
  calendar.add('version', '2.0')

  # calendar scale
  calendar.add("calscale", "gregorian")

  # meta information about calendar file creator
  calendar.add('prodid', '-//calendar-improved-test//human.experience//')

  # add events to the calendar
  add_events(calendar)

  # write calendar ical file to dist
  with open(output_file_path, 'wb') as ical_file:
    ical_file.write(calendar.to_ical())


# ........................................................................... #
def make_event(
  summary:str,
  location:str,
  start_time:datetime,
  end_time:datetime,
  organizer:Participant,
  attendees:List[Participant]
):

  # make event object
  event = Event()

  # event uuid
  event["uid"] = str(uuid.uuid4())

  # event summary
  event.add("summary", summary)

  # event location
  event["location"] = vText(location)

  # event start date
  event.add("dtstart", start_time)

  # event end date
  event.add("dtend", end_time)

  # event entry creation
  event.add("dtstamp", datetime.utcnow())

  # vent organizer
  event["organizer"] = organizer.to_ical()

  # event priority
  event.add('priority', 5)

  for attendee in attendees:
    event.add('attendee', attendee.to_ical(), encode=0)

  return event

# ........................................................................... #
def is_valid_path(file_path:str):
  parent_folder_path = os.path.dirname(file_path)
  return os.path.isdir(parent_folder_path)


# ########################################################################### #
if __name__ == '__main__':
  main(sys.argv[1:])