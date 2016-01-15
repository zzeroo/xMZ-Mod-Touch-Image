#!/bin/bash

# Functions and logic
# Bold echo commands
bold=$(tput bold)
normal=$(tput sgr0)
# echo "this is ${bold}bold${normal} but this isn't"
echo_b(){ echo -e ${bold}$1${normal}; }

# This function is called in show_help() function and prints and example string,
# if a example string is given.
# The examples can be defined on each script on top with the EXAMPLE="" env var.
example() {
  if [[ ! "x${EXAMPLE}" = "x" ]]; then
    echo_b "Example:"
    echo -e "\t$1"
    echo
  fi
}

# Show help, how is the programm called
show_help(){
	echo
	echo -e "Usage: `basename $0`\t[-o|--output_dir] [-v|--verbose] [-s|--simulate] [-f|--force] [-h|--help]"
	echo
	echo_b "Arguments:"
  echo -e "-o, --output_dir\tWere should the output files created (default: current working dir)"
  echo -e "-c, --container_dir\tWhere is the container store path (default: /var/lib/container/)"
  echo -e "-d, --distribution\tDebian distribution used by debootstrap (default: sid)"
	echo -e "-v, --verbose\t\tShow witch command was called."
	echo -e "-s, --simulate\t\tPrint each command, but don't execute it."
	echo -e "-f, --force\t\tOverride existing files, DANGER!"
	echo -e "-h, --help\t\tShow this output."
	echo
  example "${EXAMPLE}"
	echo "Script version: ${SCRIPTVERSION}"
	exit 1
}

# Debug
debug() {
  # Only print if we not in sumulate mode
  if [[ ! x"${SIMULATE}" == "xtrue" ]]; then
    echo_b "$1"
  fi
}

# Simulate, debug and call the command given as the only one parameter
# If the verbose var is set (via environent or parameter -v, --verbose)
# the command is echoed before calling
run() {
  if [[ x"${SIMULATE}" == "xtrue" ]]; then
		echo "$1"
  elif [[ x"${VERBOSE}" == "xtrue" && ! x"${SIMULATE}" == "xtrue" ]]; then
		echo ">> $1"
		eval "$1"
		# in verbose mode each command follows an empty line
		echo
	else
		eval "$1" &>/dev/null
	fi
}

