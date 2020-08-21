#!/bin/bash
# ---------------------------------------------------------------------------
# setup.sh - EdgeIQ Evaluation Kit Setup Script

# Copyright 2020, root <root@raspberrypi>
# All rights reserved.

# Usage: setup.sh [-h|--help] [-v] [-eU] [-eP] [-gU] [-gI] [-eS]

# Revision history:
# 2020-08-21 Created by new_script ver. 3.3
# ---------------------------------------------------------------------------

PROGNAME=${0##*/}
VERSION="0.1"

clean_up() { # Perform pre-exit housekeeping
  return
}

error_exit() {
  echo -e "${PROGNAME}: ${1:-"Unknown Error"}" >&2
  clean_up
  exit 1
}

graceful_exit() {
  clean_up
  exit
}

signal_exit() { # Handle trapped signals
  case $1 in
    INT)
      error_exit "Program interrupted by user" ;;
    TERM)
      echo -e "\n$PROGNAME: Program terminated" >&2
      graceful_exit ;;
    *)
      error_exit "$PROGNAME: Terminating on unknown signal" ;;
  esac
}

usage() {
  echo -e "Usage: $PROGNAME [-h|--help] [-v] [-eU] [-eP] [-gU] [-gI] [-eS]"
}

help_message() {
  cat <<- _EOF_
  $PROGNAME ver. $VERSION
  EdgeIQ Evaluation Kit Setup Script

  $(usage)

  Options:
  -h, --help  Display this help message and exit.
  -v  Verbose logging
  -eU  EdgeIQ Username
  -eP  EdgeIQ Password
  -gU  Gateway Unique ID (EdgeIQ local service uses MAC address of first ethernet interface reported by ifconfig
  -gI  Gateway IP Address
  -eS  EdgeIQ SmartEdge Version

  NOTE: You must be the superuser to run this script.

_EOF_
  return
}

# Trap signals
trap "signal_exit TERM" TERM HUP
trap "signal_exit INT"  INT

# Check for root UID
if [[ $(id -u) != 0 ]]; then
  error_exit "You must be the superuser to run this script."
fi

# Parse command-line
while [[ -n $1 ]]; do
  case $1 in
    -h | --help)
      help_message; graceful_exit ;;
    -v)
      echo "Verbose logging" ;;
    -eU)
      echo "EdgeIQ Username" ;;
    -eP)
      echo "EdgeIQ Password" ;;
    -gU)
      echo "Gateway Unique ID (EdgeIQ local service uses MAC address of first ethernet interface reported by ifconfig" ;;
    -gI)
      echo "Gateway IP Address" ;;
    -eS)
      echo "EdgeIQ SmartEdge Version" ;;
    -* | --*)
      usage
      error_exit "Unknown option $1" ;;
    *)
      echo "Argument $1 to process..." ;;
  esac
  shift
done

# Main logic

graceful_exit

