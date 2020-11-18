#!/bin/bash

# get dimension to crop a video by it's (possible) black borders

DIMENSIONS=$(ffmpeg -ss 00:02:30 -i "$1" -vf "cropdetect=24:16:0" \
    -strict -2 -an -f rawvideo -t 00:05 -y /dev/null 2>&1 | \
    # find lines containing crop information
    sed -n 's/crop=/&/p' | \
    # delete everything but the last of them
    sed '$!d' | \
    # extract crop dimensions
    sed -e 's/.*crop=//;s/).*$//')

if [[ "$2" == '-q' ]]; then
    echo "${DIMENSIONS}"
else
    echo "Preview: ffplay -vf crop=${DIMENSIONS} $1"
    echo "Encode: ffmpeg -i '${1}' -vf crop=${DIMENSIONS} -c:a copy output.mkv"
fi
