#!/bin/bash

FC_PATH=/usr/share/freecol

java -Xmx512M -jar $FC_PATH/FreeCol.jar "$@" --freecol-data $FC_PATH/data --no-intro
