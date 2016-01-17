#!/bin/bash

getopt --test > /dev/null
if [[ $? != 4 ]]; then
	echo "I’m sorry, `getopt --test` failed in this environment."
	exit 1
fi

SHORT=o:c:e:d:svfh
LONG=output:,container_dir:,environment:,distribution:,simulate,verbose,force,help

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
		-c|--container_dir)
			CONTAINER_DIR="$2"
			shift 2 # past argument
			;;
		-e|--environment)
			ENVIRONMENT="$2"
			shift 2 # past argument
			;;
		-d|--distribution)
			DISTRIBUTION="$2"
			shift 2 # past argument
			;;
		-s|--simulate)
			SIMULATE=true
			shift # past argument
			;;
		-v|--verbose)
			VERBOSE=true
			shift # past argument
			;;
		-f|--force)
			FORCE=true
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

# Parameter setup, default values
# If output dir is not given as parameter, use the current dir.
[ x"${OUTPUT_DIR}" = x ] && OUTPUT_DIR="`pwd`"
# TODO: replace hard coded CONTAINER_DIR paths in the scripts
# If container_dir is not set, we use the systemd-nspawn default path
[ x"${CONTAINER_DIR}" = x ] && CONTAINER_DIR="/var/lib/container"
# default environent: production
[ x"${ENVIRONMENT}" = x ] && ENVIRONMENT="production"
# If distribution is not given as parameter we use debian sid.
[ x"${DISTRIBUTION}" = x ] && DISTRIBUTION="jessie"





