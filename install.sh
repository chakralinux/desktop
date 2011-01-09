#!/bin/bash

PACKAGE_LIST=""

for i in $*
do
  PACKAGE_LIST=$PACKAGE_LIST" ./_repo/local/"$i"*"
done

sudo pacman -U --noconfirm $PACKAGE_LIST
