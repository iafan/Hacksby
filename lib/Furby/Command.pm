# Copyright (C) 2013 Igor Afanasyev, https://github.com/iafan/Hacksby

package Furby::Command;

use Furby::Command::Dictionary;

# Commands marked with "!" are available in the official iOS Furby app (i.e. they are supposed to work one way or another)
# The potential range for commands is [0..1023]. Some of the command codes missing from this list are just used as
# Furby responses (see Furby::Command::Dictionary)

# When the command is understood (e.g. the food was accepted), Furby will respond with his current personality type [900..905].

my $description = {
    #...
    '350' => '', #! food, tasty ("mmm, yum")
    #...
    '352' => 'Any small eatable tasty stuff (like peanut)', #!
    '353' => 'Any bigger soft eatable tasty stuff (like banana)', #!
    '354' => 'Any suckable tasty stuff (like oysters, sphagetti)', #!
    '355' => 'Any drinkable(?) tasty stuff', #!
    '356' => 'Any hard eatable but not tasty stuff (like chicken bone)', #! 
    #...
    '358' => 'Any small not tasty stuff (like pepperoni)', #!
    '359' => 'Any bigger soft not tasty stuff (like asparagus)', #!
    '360' => 'Any suckable not tasty stuff ', #!
    '361' => '', #!
    #...
    '368' => '', #!
    #...
    '370' => '', #!
    '371' => '', #!
    '372' => 'Any suckable tasty stuff (like beans)', #! "ooh!"
    '373' => '', #!
    '374' => '', #!
    #...
    '376' => '', #!
    '377' => '', #!
    '378' => '', #!
    '379' => '', #!
    '380' => '', #!
    #...
    '382' => '', #!
    '383' => '', #!
    '384' => '', #!
    '385' => '', #!
    '386' => '', #!
    #...
    '388' => '', #!
    '389' => '', #!
    '390' => '', #!
    '391' => '', #!
    '392' => '', #!
    #...
    '394' => '', #!
    '395' => '', #!
    '396' => '', #!
    '397' => '', #!
    '398' => '', #!
    #...
    '400' => '', #!
    '401' => '', #!
    '402' => '', #!
    '403' => '', #!
    #...
    '410' => '', #! something hot?
    #...
    '412' => '', #! something hot?
    '413' => '', #! something hot?
    '414' => '', #!
    '415' => '', #!
    '416' => '', #!
    '417' => 'Any non-eatable stuff (toilet paper, pillow, etc)', #!
    '418' => '', #!
    '419' => '', #!
    '420' => '', #!
    '421' => '', #!
    '422' => '', #!
    '423' => '', #!
    '424' => '', #!
    '425' => '', #!
    #...
    '700' => 'Event: I\'m bored / sleepy', # does various silly things depending on personality
    '701' => 'Event: Burp',
    '702' => 'Event: Chew-chew',
    '703' => 'Event: You touched my head or side, you turned me on a side',
    '704' => 'Event: Fart',
    '705' => 'Event: I woke up!', # sent on Furby wakeup, even before it pronounces the 'Good morning' phrase
    '706' => 'Event: (?)', # sent at random when Furby is idle (like ping, or searching for other Furbys?). Responds with '721'
    '707' => 'Event: (?)', # sent at random when Furby is idle (like ping, or searching for other Furbys?). Responds with '722'
    '708' => 'Event: (?)', #  speech: dang-dang-dang-da..... Responds with '723'
    '709' => 'Event: (?)', #  speech: bo-ga-di-di-do ... dang-dang-dang-da..... Responds with '724'
    '710' => 'Event: Me happy (also when head or back is touched)',
    '711' => 'Event: cough-cough-cough',
    '712' => 'Event: Me hungry! / Kah Ay-tay!',
    '713' => 'Event: You touched my tummy; also sent on its own like <touch my tummy, please?> / As command: imitate tummy touch(?)', #<
    '714' => '', #  something that he dislikes (vomit like sound, changes eyes)
    '715' => '', #  something he dislikes? speaks rapidly
    '716' => 'Event: Me happy (you touched my side or back, or head)',
    '717' => 'Event: Achoo!',
    '718' => 'Event: Yawn (I\'m going to sleep) / As command: Yawn!', # when sent as a command, will yawn / sent automatically twice when Furby is going into deep sleep mode
    '719' => 'Event: Whisper, whisper, he-he-he',
    '720' => '', #  something he dislikes, "uh oh kaa tee, do?"
    '721' => 'Event: got a command 706 (plus sings a song); as command: sing that song', #! handshake?
    '722' => 'Event: got a command 707 (plus sings a song); as command: sing that song', #! handshake?
    '723' => 'Event: got a command 708 (plus sings a song); as command: sing that song', #! handshake?
    '724' => 'Event: got a command 709 (plus sings a song); as command: sing that song', #! handshake?
    #...
    '760' => '', #  "love friend, nay nay noo la"
    '761' => '', #  "day-dee"
    '762' => '', #  "meila koo mei ta, meila koo mei ta, like mua, mua, mua" (kiss)
    '763' => '', #  "ka tulu ata, ata, ata, ata" (song)
    '764' => '', #  "witi wati to to, blah blah blah blah blah, blah" (song)
    '765' => '', #  "(fart) oh-ho-ho, tu lu li ku!"
    '766' => '', #  "boda tei ta eу ku, shaa!"
    #...
    '780' => 'Event: I\'ve got command 790',
    '781' => 'Event: I\'ve got command 791',
    #...
    '790' => '', #  "ee day do lay lo la!". Responds with '780'
    '791' => '', #  "u nai bo li day". Responds with '781'
    #...
    '813' => 'Request: What\'s your personality?', #! used to initate handshake step 1 and get the current personality type
    #...
    '820' => 'Hypnotize for 1 minute', #! this command is sent by iOS app immediately on application start and every 40 seconds. Responds with current character type (90x).
    #...
    '830' => '', #!
    '831' => '', #
    '832' => '', #!
    #...
    '850' => '', #  "yeah mi mi be day mu ha ha", "yeah, yeah, yeah! oh yeah yeah!"
    '851' => '', #  "mmm, ka tulu, me like", "haa"
    '852' => '', #  "oh-oh-oh-oh!", "dude, no!"
    '853' => '', #  "grrrh ko ko" something he dislikes
    '854' => '', #  "grrrh ko ko", "ka bu ku do"
    '855' => '', #  "ka happy dude", "a ha pee pee day", "yeah nice good boo tai naba"
    '856' => '', #  "u-ho-ho, a-ho-ho", "blah blah blah blah"
    '857' => '', #  "a ha! bu da to to", "u ha, he-he-he"
    '858' => '', #  "ha? du?"
    '859' => '', #  "a ha", "oh, kah hey hey, I see"
    '860' => '', #  "ahaa.. be day loo ney", "haa", "um, mmm, hm"
    '861' => '', #  "huh" (bored?)
    '862' => 'Command: Sleep!', #! sleep (for several seconds)
    '863' => 'Command: Laugh!', #! laugh
    '864' => 'Command: Burp!', #! burp
    '865' => 'Command: Fart!', #! fart/poo
    '866' => 'Command: Purr!', #! purr
    '867' => 'Command: Sneeze!', #! long sneeze
    '868' => 'Command: Sing!', #! sing
    '869' => 'Command: Talk!', #! talk
    '870' => '', #  "me tay, yes, yes!" (hearts in his eyes), "di do dude, good friend"
    '871' => '', #  "ah bu to lu, no like"
    '872' => '', #  says some rap
    '873' => '', #  sings: "di-di-di-di, tam-da-di dam"
    '874' => '', #  eating motion
    '875' => '', #  angry bite, "he-he-he"
    '876' => '', #  chewing/sucking sound (like when someone puts a finger in his mouth)
    '877' => '', #  suck in
    '878' => '', #  ingest
    '879' => '', #  short sneeze, "like pea" (or something else, depending on personality)
    '880' => '', #! motion (dislike)
    '881' => '', # "oh-hoo ha-ha" (or "ha-haa" like something scary or hot)
    '882' => '', #! "ah ha me bee dey, nice good!", purr
    '883' => '', #  tasty: "mmm, yum", "ha haa!"
    '884' => '', #  not tasty (vomit-like)
    '885' => '', #  "oooh"
    '886' => '', #  "chew chew ooh"
    '887' => '', #! "aaah" (exclamation) (changes eyes to 'burning' in warrior mode)
    '888' => '', #  "aaah"
    '889' => '', #! motion (sings "ahh-tahoo")
    '890' => '', #  "baby"
    '891' => '', #  "ka ay tay oooh", "purr grrr uh oh"
    '892' => '', #  "mmm, good food"
    '893' => '', #
    #...
    '900' => 'I have no personality developed yet...',
    '901' => 'I\'m a princess!',
    '902' => 'I\'m a diva!',
    '903' => 'I\'m a warrior!',
    '904' => 'I\'m a joker!',
    '905' => 'I\'m a gossip queen!',
    '906' => 'My personality is #906 [SNUGGLEBY]',
    '907' => 'My personality is #907 [SASSBY]',
    '908' => 'My personality is #908 [SCOFFBY]',
    '909' => 'My personality is #909 [CHUCKLEBY]',
    '910' => 'My personality is #910 [GASSBY]',
    '911' => 'My personality is #911 [LATEBY]',
};

sub description {
    my $command = shift;
    return $description->{$command} || Furby::Command::Dictionary::description($command);
}

1;