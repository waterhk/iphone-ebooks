#!/bin/bash

# This script copies a local directory into the iPhone's Media/EBooks
# directory.  If you have a single file, use copybook.sh.

which iphuc > /dev/null

if [ $? = 1 ]; then
    echo "iPHUC does not appear to be installed in your path!"
    exit 1
fi

FILES=`ls $1`

echo $FILES
