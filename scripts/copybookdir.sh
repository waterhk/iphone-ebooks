#!/bin/bash

# copybookdir, for Books.app v0.2
# This script copies a local directory into the iPhone's Media/EBooks
# directory.  If you have a single file, use copybook.sh.
# MAJOR LIMITATION: does not currently work with files/directories 
# which contain spaces.

which iphuc > /dev/null

if [ $? = 1 ]; then
    echo "iPHUC does not appear to be installed in your path!"
    exit 1
fi

if [ $# -lt 1 ]; then
    echo "You need to provide a directory!"
    exit 1
fi

FILES=`ls $1`

FULLPATH=`dirname $1`

BASE=`basename $1`

echo "Please connect your iPhone to your computer via USB, 
quit iTunes if it appears, and press enter."
read p

(
    echo "mkdir EBooks"
    echo "cd EBooks"
    echo "mkdir /EBooks/${BASE}"
    echo "cd ${BASE}"
    for i in ${FILES}; do
         echo "putfile ${FULLPATH}/${BASE}/$i $i"
    done
    echo "exit"
) | iphuc

echo ""
echo "Files copied!"

exit 0

