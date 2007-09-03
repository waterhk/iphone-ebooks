#!/bin/bash

# copybookdir, for Books.app v0.2
# This script copies a local directory into the iPhone's Media/EBooks
# directory.  If you have a single file, use iPHUC directly.
# MAJOR LIMITATION: does not currently work with files/directories 
# which contain spaces.

# set -x

which iphuc > /dev/null

OLDPWD=${PWD}

if [ $? = 1 ]; then
    echo "iPHUC does not appear to be installed in your path!"
    exit 1
fi

if [ $# -lt 1 ]; then
    echo "Usage: $0 /path/to/directory"
    echo "You need to provide a directory!"
    echo
    echo "WARNING: This script will copy over every visible"
    echo "file in the directory you specify!  Make sure you're"
    echo "entering the correct directory and that it contains only"
    echo ".txt or .htm(l) files."
    echo

    exit 1
fi

cd "$1"

if [ $? = 1 ]; then
    echo "Error: bad directory."
    exit 1
fi

FULLPATH=$(echo $PWD)
echo $FULLPATH
BASE=$(echo $(basename "$1") | sed 's/ /\\ /g')


echo "Please connect your iPhone to your computer via USB
and press enter."
read p

(
    echo "mkdir EBooks"
    echo "cd EBooks"
    echo "mkdir /EBooks/${BASE}"
    echo "cd ${BASE}"
    for f in "$FULLPATH/"*; do
         f=`echo $f | sed 's/ /\\\\ /g'`
         n=`basename "$f"`
         echo "putfile $f $n"
    done
    echo "exit"
) | iphuc > /tmp/iphuc.out

grep Failed /tmp/iphuc.out

if [ $? = 1 ]; then
    echo
    echo "The following files have been copied:"
    for f in "$FULLPATH/"*; do
         n=`basename "$f"`
         echo "   $f $n"
    done
    exit 0
else
    echo
    echo "Errors occurred.  Some files may not have been copied."
    echo "See /tmp/iphuc.out for details."
    exit 1
fi

cd "$OLDPWD"
