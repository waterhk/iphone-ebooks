#!/bin/bash

# sed -n '/<key>CFBundleVersion<\/key>/{n;p;}' < Info.plist | awk -F '>' '{print $2}' | awk -F '<' '{print $1}'

SVN_REV=`git-svn log --oneline --limit 1 | cut -d ' ' -f 1`
VERSION=`tail -n 1 VERSION`

echo "${VERSION}-${SVN_REV}"
