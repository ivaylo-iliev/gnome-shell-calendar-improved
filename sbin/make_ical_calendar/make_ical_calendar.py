#!/usr/bin/env python3

# ........................................................................... #
import os
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

  big_string = "very early event\nWarehouse narrative towards hacker gang long-chain hydrocarbons shoes rebar media stimulate courier concrete. Neon wristwatch office chrome assassin kanji sub-orbital sentient A.I. corrupted drugs cyber. Alcohol computer spook euro-pop DIY tanto boy voodoo god denim monofilament shrine corporation vehicle pen apophenia render-farm San Francisco. Singularity dissident jeans drone meta-paranoid industrial grade math-apophenia courier numinous into 3D-printed. Realism weathered Chiba chrome tube pre-youtube face forwards post. Dome denim digital rebar carbon rain corrupted 8-bit into drone narrative-space dead vinyl. Office modem paranoid tower long-chain hydrocarbons woman wonton soup rifle table. Saturation point tanto wonton soup ablative construct A.I. urban pistol post-tattoo receding.\nDecay 8-bit face forwards pen tower youtube cartel drone alcohol dolphin shoes footage construct. Silent pistol network beef noodles shoes hotdog geodesic papier-mache tanto drugs fetishism franchise advert Tokyo realism skyscraper table. 8-bit artisanal knife apophenia dead Shibuya jeans warehouse tube hacker spook franchise realism ablative digital claymore mine augmented reality. Military-grade j-pop systema decay katana sunglasses convenience store sign sprawl marketing grenade bomb. Chrome dolphin savant tiger-team post-table tube office numinous physical shoes computer faded market plastic. Long-chain hydrocarbons bomb A.I. hacker sensory face forwards Shibuya skyscraper systema pre. Cyber-sprawl chrome franchise otaku military-grade beef noodles tube. Sensory nano-euro-pop pen convenience store computer table refrigerator. Rifle sentient pistol shrine youtube media knife.\n Corporation free-market pen construct military-grade-space table engine. Girl savant youtube San Francisco monofilament long-chain hydrocarbons receding. Hacker nodal point assassin bomb gang katana chrome physical kanji order-flow knife. Claymore mine pen free-market DIY nodal point stimulate computer sub-orbital warehouse. Systemic footage-ware disposable construct industrial grade soul-delay cartel cyber-post. Uplink industrial grade urban free-market-ware wonton soup camera car realism fetishism euro-pop gang table A.I. weathered woman. Order-flow car rifle dolphin garage dome digital convenience store range-rover numinous cyber-humann\n\nace forwards jeans carbon nodality silent car industrial grade bridge. Sign man corrupted saturation point courier-space footage meta. Fetishism render-farm tattoo kanji construct youtube tiger-team cartel drone modem dome grenade engine film. Military-grade knife garage render-farm smart-skyscraper pre-tank-traps bomb 3D-printed tattoo uplink range-rover. Tattoo boy motion film assault knife semiotics tanto tiger-team table Tokyo corrupted car tower military-grade hotdog face forwards."

  # ~~~~~ #
  events_info = (

    {
      "title": "Event: All day today",
      "description": big_string,
      "day": "all-day",
    },

    {
      "title": "Event: 12am - 4am",
      "description": "very early event\nhow are you\n\ntoday\nAt https://google.com",
      "day": "today",
      "start": {"hour": 0, "minute": 0},
      "end": {"hour": 4, "minute": 0 },
    },

    {
      "title": "Event: 04am - 08am",
      "description": "early event",
      "day": "today",
      "start": {"hour": 4, "minute": 0},
      "end": {"hour": 8, "minute": 0 },
    },

    {
      "title": "Event: 08am - 12pm",
      "description": "morning event",
      "day": "today",
      "start": {"hour": 8, "minute": 0},
      "end": {"hour": 12, "minute": 0 },
    },

    {
      "title": "Event: 12pm - 04pm",
      "description": "afternoon event",
      "day": "today",
      "start": {"hour": 12, "minute": 0},
      "end": {"hour": 16, "minute": 0 },
    },

    {
      "title": "Event: 04pm - 08pm",
      "description": "late afternoon event",
      "day": "today",
      "start": {"hour": 16, "minute": 0},
      "end": {"hour": 20, "minute": 0 },
    },

    {
      "title": "Event: 08pm - 12am",
      "description": "evening event",
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
      description=event_info["description"],
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
  description:str,
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

  # event description
  event.add("description", description)

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
