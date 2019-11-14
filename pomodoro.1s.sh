#!/bin/bash
#
# <bitbar.title>Pomodoro Timer</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Goran Gajic</bitbar.author>
# <bitbar.author.github>gorangajic</bitbar.author.github>
# <bitbar.desc>Pomodoro Timer that uses Pomodoro Technique™</bitbar.desc>
# <bitbar.image>http://i.imgur.com/T0zFY89.png</bitbar.image>

WORK_TIME=25
BREAK_TIME=5

SAVE_LOCATION=$HOME/tmp/bitbar-promodo
TOMATO='🍅'
WORK='👔'
BREAK='☕'

AUTO_NEXT_STATE=

WORK_TIME_IN_SECONDS=$((WORK_TIME * 60))
BREAK_TIME_IN_SECONDS=$((BREAK_TIME * 60))

CURRENT_TIME=$(date +%s)

if [ -f "$SAVE_LOCATION" ];
then
    DATA=$(cat "$SAVE_LOCATION")

else
    DATA="$CURRENT_TIME|0"
fi

TIME=$(echo "$DATA" | cut -d "|" -f1)
STATUS=$(echo "$DATA" | cut -d "|" -f2)
NOTIFIED_STATUS=$(echo "$DATA" | cut -d "|" -f3)


function saveStatus {
    echo "$1|$2|$3" > "$SAVE_LOCATION";
}


function breakMode {
    saveStatus $CURRENT_TIME "break" "break"
}


function breakTime {
    saveStatus $TIME $STATUS "break"
}


function notifyBreak {
    notify-send "$TOMATO Pomodoro" "☕ Take a rest"
    paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga &
}


function workMode {
    saveStatus $CURRENT_TIME "work" "work"
}


function workTime {
    saveStatus $TIME $STATUS "work"
}


function notifyWork {
    notify-send "$TOMATO Pomodoro" "👔 Time to do something"
    paplay /usr/share/sounds/freedesktop/stereo/window-attention.oga &
}


case "$1" in
"work")
    workMode
    exit
  ;;
"break")
    breakMode
    exit
  ;;
"disable")
    saveStatus $CURRENT_TIME "disable" "disable"
    exit
  ;;
esac


function timeLeft {
    local FROM=$1
    local TIME_DIFF=$((CURRENT_TIME - TIME))
    local TIME_LEFT=$((FROM - TIME_DIFF))
    echo "$TIME_LEFT";
}

function getSeconds {
    echo $(($1 % 60))
}

function getMinutes {
    echo $(($1 / 60))
}

function printTime {
    SECONDS=$(getSeconds "$1")
    MINUTES=$(getMinutes "$1")

    if [ "$2" == "" ]; then
      printf "%s %02d:%02d\n" "$3" "$MINUTES" "$SECONDS"
    else
      printf "%s %02d:%02d| color=%s\n" "$3" "$MINUTES" "$SECONDS"  "$2"
    fi
}

case "$STATUS" in
# STOP MODE
"disable")
    echo "$TOMATO"
  ;;
"work")
    TIME_LEFT=$(timeLeft $WORK_TIME_IN_SECONDS)
    if (( "$TIME_LEFT" < 0 )); then
        printTime "-$TIME_LEFT" "red" "$WORK"
        if "$AUTO_NEXT_STATE" ; then
            breakMode
            notifyBreak
        else
            breakTime
            if [ "$NOTIFIED_STATUS" != "break" ]; then
                notifyBreak
            fi
        fi
    else
      printTime "$TIME_LEFT" "" "$WORK"
    fi
  ;;
"break")
    TIME_LEFT=$(timeLeft $BREAK_TIME_IN_SECONDS)
    if (("$TIME_LEFT" < 0)); then
        printTime "-$TIME_LEFT" "red" "$BREAK"
        if "$AUTO_NEXT_STATE" ; then
            workMode
            notifyWork
        else
            workTime
            if [ "$NOTIFIED_STATUS" != "work" ]; then
                notifyWork
            fi
        fi
    else
      printTime "$TIME_LEFT" "" "$BREAK"
    fi
  ;;
esac

echo "---";
echo "👔 Work | bash=\"$0\" param1=work terminal=false"
echo "☕ Break | bash=\"$0\" param1=break terminal=false"
echo "🔌 Disable | bash=\"$0\" param1=disable terminal=false"
