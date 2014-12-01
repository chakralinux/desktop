#!/bin/sh

# set qt plugin path for kde4/qt4, otherwise qt4 plugin will not picked up by qt4/kde4 application.
QT_PLUGIN_PATH=${QT_PLUGIN_PATH+$QT_PLUGIN_PATH:}/usr/lib/kde4/plugins:/usr/lib/qt/plugins

