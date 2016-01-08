#!/bin/bash
SCRIPTVERSION=0.0.1
# Bold echo commands
bold=$(tput bold)
normal=$(tput sgr0)
# echo "this is ${bold}bold${normal} but this isn't"
function echo_b { echo -e ${bold}$1${normal}; }

function show_help {
echo
echo -e "`basename $0`\t\t[-o|--output_dir]"
echo
echo_b "Arguments:"
echo "-o | --output_dir\tWere should the output files created."
echo
echo "Script version: ${SCRIPTVERSION}"
}




# Main part of the script

# Option parser
getopt --test > /dev/null
if [[ $? != 4 ]]; then
	echo "I’m sorry, `getopt --test` failed in this environment."
	exit 1
fi

SHORT=o:hv
LONG=output:,help,verbose

PARSED=`getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@"`
if [[ $? != 0 ]]; then
	exit 2
fi
eval set -- "$PARSED"

while true; do
	case "$1" in
		-o|--output_dir)
			OUTPUT_DIR="$2"
			shift 2 # past argument
			;;
		-v|--verbose)
			verbose=true
			shift # past argument
			;;
		-h|--help)
			show_help
			shift # past argument
			;;
		--)
			shift
			break
			;;
	esac
done


