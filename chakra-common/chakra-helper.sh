#!/bin/bash
# chakra-helper v1.1

# ----------------------------------------------------------------------------  #
# "THE BEER-WARE LICENSE" (Revision 42):                                        #
# konwhald@hotmail.fr wrote this file. As long as you retain this notice you    #
# can do whatever you want with this stuff. If we meet some day, and you think  #
# this stuff is worth it, you can buy me a beer in return. Konwhald             #
# ----------------------------------------------------------------------------  #

TITLE="Chakra Helper"
TMPFILE=$(mktemp)
LC_ALL=C
PACMANCONF=/etc/pacman.conf
ICON="/usr/share/icons/oxygen/scalable/places/start-here-branding.svg"

main() {
    COMMAND="$( \
    kdialog \
        --title "$TITLE" \
        --inputbox "Command to run?" "" \
        --icon "$ICON" \
    )"

    echo "» uname -a" >> $TMPFILE
    uname -a >> $TMPFILE
    echo "================================================================" >> $TMPFILE
    echo "» grep -v '^$' $PACMANCONF | grep -v '^ *#'" >> $TMPFILE
    grep -v '^$' $PACMANCONF | grep -v '^ *#' >> $TMPFILE
    echo "================================================================" >> $TMPFILE
    echo "» $COMMAND" >> $TMPFILE
    eval $COMMAND >> $TMPFILE 2>> $TMPFILE

    if [ -x /usr/bin/chakra-paste ]; then
        URL="$(chakra-paste "$TMPFILE")"
        kdialog \
            --title "$TITLE" \
            --msgbox "The report is available at: \n \
$URL \n\n \
Local copy: \n \
$TMPFILE \n\n \
Search for similar issues on the web. If you don't find any, \n \
create a new topic on the forum with a clear and detailed \n \
explanation of what you are trying to do, what actually happens \n \
and what you expected to happen along with this URL." \
            --icon "$ICON"
        echo "The report is available at: $URL (local copy: $TMPFILE)."
    else
        kdialog \
            --title "$TITLE" \
            --error "\"chakra-paste\" is not installed on your system, \n\n \
paste the report on paste.chakra-project.org. \n \
Search for similar issues on the web. If you don't find any, \n \
create a new topic on the forum with a clear and detailed \n \
explanation of what you are trying to do, what actually happens \n \
and what you expected to happen along with this URL." \
            --icon "$ICON"
        kdialog \
            --title "$TITLE" \
            --textbox "$TMPFILE" 590 330 \
            --icon "$ICON"
    fi
}

if [ "$1" = --help ] || [ "$1" = -h ]; then
    echo "chakra-helper, version 1.1"
    echo "Generate a report for support purposes."
    echo "Original author: Konwhald <konwhald@hotmail.fr>"
else
    main $*
fi
