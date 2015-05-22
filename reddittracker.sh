#!/bin/sh
# reddittracker.sh, a utility to track the success of a post on reddit
# Copyright (C) 2012,2015  Alicia <alicia@ion.nu>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Modified Alicia's code to suit conky 

thread="$1"
if [ "$thread" = "" -o "$thread" = "-h" -o "$thread" = "--help" ]; then
  echo "Usage: ${0} <reddit thread URL>"
  exit 1
fi
regexp="/<div class=\"score\"><span class=\"number\">/{s/.*<div class=\"score\"><span class=\"number\">//;s/<.*//;s/,//g;p;}"
score=0
maxscore=0
now="`date +%s`"
newscore="`curl -s "${thread}?x=$now" | sed -n -e "$regexp" `"
if [ "$newscore" = "" ]; then continue; fi # Overloads and stuff I guess
if [ "$newscore" -gt "$maxscore" ]; then
  maxscore="$newscore"
fi
if [ "$newscore" != "$score" ]; then
  score="$newscore"
  echo "$thread - ${score} points"   
fi
