#!/bin/bash

getopt --test > /dev/null
if [[ $? != 4 ]]; then
	echo "I’m sorry, `getopt --test` failed in this environment."
	exit 1
fi

SHORT=o:svfh
LONG=output:,simulate,verbose,force,help

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
		-s|--simulate)
			simulate=true
			shift # past argument
			;;
		-v|--verbose)
			verbose=true
			shift # past argument
			;;
		-f|--force)
			force=true
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

# Parameter setup
# If output dir is not given as parameter, use the current dir.
[ x"${OUTPUT_DIR}" = x ] && OUTPUT_DIR=`pwd`

