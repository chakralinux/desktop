#!/bin/sh
#
# This file is executed at kde shutdown.
# Uncomment the following lines to kill the agents
# that were started at session startup.

if [ -x /usr/bin/gpgconf ]; then
  /usr/bin/gpgconf --kill gpg-agent
fi
#
if [ "${SSH_AGENT_PID}" ]; then
  ssh-agent -k
fi
