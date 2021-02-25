#!/usr/bin/env bash
# Magnus Larsen, 2021

# TODO: Reevaluate language used for clarity (pass/fail/bug etc)

# Blacklist is used to disable tests that are for later labs.
# Tests containing a blacklisted word in the filename will be ignored
# So, to only run tests for lab 1, define:
# blacklist="lab2 lab3 lab4 lab5 lab6"
blacklist="lab2Only lab4 lab5 lab6"

function is_not_blacklisted() {
   # filename to compare against blacklist
   i="$1"

   for blackitem in $blacklist; do
      if [[ "$i" == *"$blackitem"* ]]; then
         return 1
      fi
   done
   return 0
}

# STATISTICS
# How many tests ran?
testCount=0
# How many tests failed?
bugCount=0
# How many tests were ignored by the blacklist?
blacklistHits=0

# FORMATTING
# bold for headings
b="$(tput bold)"
# red for errors
e="$(tput bold)$(tput setaf 1)"
r="$(tput sgr0)"

# Ensure the ** syntax works for globbing recursively
shopt -s globstar


function run_tests() {
   for i in "$@"; do
      if [ ! -f "$i" ]; then
         echo
         echo "${e}Warning:${r} $i does not exist"
         echo "Usually, this means a glob didn't match any tests."
         continue
      fi
      is_not_blacklisted "$i" &&
      run_test "$i" ||
      ((blacklistHits++))
   done
}

function run_test() {
   # test to run, such as testPass/davidSample.wan
   i=$1

   # Prevent filesystem race conditions with unique name, including PID ($$)
   log="testOut_$(hostname)_${$}.txt"
   # Run Lab, capturing stdout and stderr
   ./lab < "$i" > "$log" 2>&1
   # Capture the error code from the binary
   ret="$?"

   # if there's a bug, set to 1.
   bug=0
   # The file containing expected output, only set for `testText`s
   o=

   if   [[ "$i" == **"testPass"** ]]; then
      ((bug=ret))
   elif [[ "$i" == **"testFail"** ]]; then
      ((bug=!ret))
   elif [[ "$i" == **"testText"** ]]; then
      o="$i.out.txt"

      diff "$log" "$o" > /dev/null 2>&1
      bug="$?"
   else
      echo "${e}FATAL ERROR:${r} Unknown test type."
      echo "Test: '$i'"
      exit 1
   fi

   ((testCount++))
   if [ 0 -ne "$bug" ]; then
      ((bugCount++))
      echo
      echo "${b}BUG IN:${r} $i"
      # echo "\"$(realpath lab)\" < \"$(realpath $i)\""
      echo "${b}LAB OUTPUT:${r}"
      cat "$log"
      if [ "$o" ]; then
        echo "- - - - - - - - "
        echo
        echo "${b}EXPECTED LAB OUTPUT:${r}"
        cat "$o"
      fi
      echo "################"
      echo
   fi

   rm "$log"
}

function display_report() {
   echo
   echo "${b}REPORT:${r}"
   echo "$testCount tests ran."
   echo "$blacklistHits were ignored by the blacklist: '$blacklist'."
   [ 0 -eq "$bugCount" ] &&
      echo " ${b}OK.${r} (No bugs)" ||
      echo " ${b}BUG:${r} $bugCount tests reported a bug"

   echo
}

# Go to wanderful repo
cd "$(dirname "$(realpath "$0")")"

# Integrity checks
if [ ! -f lab ]; then
   echo
   echo "FATAL ERROR: Missing 'lab' symlink."
   echo "Please make a symlink to your labx binary named 'lab'."
   exit 1
fi

run_tests testPass/**/*.wan testFail/**/*.wan testText/**/*.wan

display_report

[ 0 -ne $bugCount ] && exit 1
exit 0
