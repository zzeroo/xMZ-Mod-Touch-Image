#!/bin/bash

# Helper
NUM_CPU=`grep -c "^processor" /proc/cpuinfo`
alias make="make -j$[$NUM_CPU + 1]"

# Functions and logic
# Bold echo commands
bold=$(tput bold)
normal=$(tput sgr0)
# echo "this is ${bold}bold${normal} but this isn't"
echo_b(){ echo -e ${bold}$1${normal}; }


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
	echo -e "-o, --output_dir\tWere should the output files created."
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
  if [[ ! x"${simulate}" == "xtrue" ]]; then
    echo_b "$1"
  fi
}

# Simulate, debug and call the command given as the only one parameter
# If the verbose var is set (via environent or parameter -v, --verbose)
# the command is echoed before calling
run() {
  if [[ x"${simulate}" == "xtrue" ]]; then
		echo "$1"
  elif [[ x"${verbose}" == "xtrue" && ! x"${simulate}" == "xtrue" ]]; then
		echo ">> $1"
		eval "$1"
		# in verbose mode each command follows an empty line
		echo
	else
		eval "$1" &>/dev/null
	fi
}

