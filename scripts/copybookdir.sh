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
    echo "Usage: $0 /path/to/directory"
    echo "You need to provide a directory!"
    echo ""
    echo "WARNING: This script will copy over every visible"
    echo "file in the directory you specify!  Make sure you're"
    echo "entering the correct directory and that it contains only"
    echo ".txt or .htm(l) files."
    echo ""

    exit 1
fi

OLDPWD=${PWD}
cd "$1"

if [ $? = 1 ]; then
    echo "Error: bad directory."
    exit 1
fi

FILES=`ls`

FULLPATH=${PWD}

BASE=`basename $1`

echo "Please connect your iPhone to your computer via USB
and press enter."
read p

(
    echo "mkdir EBooks"
    echo "cd EBooks"
    echo "mkdir /EBooks/${BASE}"
    echo "cd ${BASE}"
    for i in ${FILES}; do
         echo "putfile ${FULLPATH}/$i $i"
    done
    echo "exit"
) | iphuc > /tmp/iphuc.out

grep Failed /tmp/iphuc.out

if [ $? = 1 ]; then
    echo ""
    echo "The following files have been copied:"
    for i in ${FILES}; do
	echo "   ${FULLPATH}/$i $i"
    done
    cd ${OLDPWD}
    exit 0
else
    echo ""
    echo "Errors occurred.  Some files may not have been copied."
    echo "See /tmp/iphuc.out for details."
    cd ${OLDPWD}
    exit 1
fi



