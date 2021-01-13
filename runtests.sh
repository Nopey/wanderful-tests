#!/usr/bin/env bash
# Magnus Larsen
# Created January 13th, 2020
# TODO: Refractor into functions
# TODO: Reevaluate language used for clarity (pass/fail/bug etc)


# Integrity checks
if [ ! -f lab ]; then
   echo
   echo "FATAL ERROR: Missing 'lab' symlink."
   echo "Please make a symlink to your labx binary named 'lab'."
   exit 1
fi
if [ ! -d testPass ]; then
   echo
   echo "FATAL ERROR: Missing 'testPass' directory."
   echo "Please clone the repository, downloading runtests.sh alone is not enough"
   # (Unless of course, you're writing your own tests)
   exit 1
fi
if [ ! -d testFail ]; then
   echo
   echo "FATAL ERROR: Missing 'testFail' directory."
   echo "Please clone the repository, downloading runtests.sh alone is not enough"
   # (Unless of course, you're writing your own tests)
   exit 1
fi

b="$(tput bold)"
r="$(tput sgr0)"

# Ensure the ** syntax works for the two for loops
shopt -s globstar

# Run all tests that are supposed to pass
testPassCount=0
testPassBug=0
for i in testPass/**/*.wan; do
   if [ ! -f "$i" ]; then
      echo
      echo "${b}Warning:${r} $i does not exist"
      echo "Perhaps there are no tests in testPass?"
      continue
   fi

   ((testPassCount++))
   ./lab < "$i" > testOut.txt 2>&1
   if [ ! 0 -eq "$?" ]; then
      ((testPassBug++))
      echo
      echo "${b}BUG IN:${r} $i"
      echo "${b}LAB OUTPUT:${r}"
      cat testOut.txt
      echo
   fi
done

# And all that are supposed to fail
testFailCount=0
testFailBug=0
for i in testFail/**/*.wan; do
   if [ ! -f "$i" ]; then
      echo
      echo "${b}Warning:${r} $i does not exist"
      echo "Perhaps there are no tests in testFail?"
      continue
   fi

   ((testFailCount++))
   ./lab < "$i" > testOut.txt 2>&1
   if [ 0 -eq "$?" ]; then
      ((testFailBug++))
      echo
      echo "${b}BUG IN:${r} $i"
      echo "${b}LAB OUTPUT:${r}"
      cat testOut.txt
      echo
   fi
done

echo
echo "${b}REPORT:${r}"
echo "$testPassCount tests that expect pass."
[ 0 -eq "$testPassBug" ] &&
   echo " ${b}OK.${r}" ||
   echo " ${b}BUG:${r} $testPassBug of those failed (false-negatives)"

echo "$testFailCount tests that expect failure."
[ 0 -eq "$testFailBug" ] &&
   echo " ${b}OK.${r}" ||
   echo " ${b}BUG:${r} $testFailBug of those passed instead (false-positives)"
echo

rm -f testOut.txt

[ 0 -eq "$testPassBug" ] &&
   [ 0 -eq "$testFailBug" ] &&
   exit 0

exit 1
# echo yay
# ./lab
