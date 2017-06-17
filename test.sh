#!/bin/bash
# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
# note: if this is set to -gt 0 the /etc/hosts part is not recognized ( may be a bug )

version=0.0.1
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  -b|--boxes)
  vagrant_boxes="$2"
  shift # past argument
  ;;
  -u|--update)
  update="$2"
  shift # past argument
  ;;
  -h|--help)
  show_help=true
  shift # past argument
  ;;
  --default)
  DEFAULT=YES
  ;;
  *)
  # unknown option
  echo "Unknown argument: $1"
  echo "Use -h or --help for more information."
  exit 1
  ;;
esac
shift # past argument or value
done

if [ "$show_help" == "true" ]; then
  echo 
  echo "run.sh Version: ${version}"
  echo 
  printf "%-20s %-40s\n" "  -b|--boxes"   "Specifies which boxes to target for this run"
  printf "%-20s %-40s\n" "  -u|--update"  "Forces the script to update regardless of properties"
  printf "%-20s %-40s\n" "  -h|--help"    "Shows the help information"

  exit 0
fi

echo Vagrant Boxes are  = "${vagrant_boxes}"
echo Update             = "${update}"