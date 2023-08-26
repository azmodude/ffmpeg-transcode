#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# don't process empty globs

shopt -s nullglob

[[ -z "${1}" ]] && source='.' || source="${1}"
[[ -z "${2}" ]] && preset='slow' || preset="${2}"

[[ ! -d ./encoded ]] && mkdir ./encoded

echo "Size of Directory before transcoding: $(du -hs --exclude "${source}/encoded/*" "${source}" | cut -f -1)"

set -vx
find "${source}" \
    -maxdepth 1 \
    ! -path "./encoded/*" \
    \( -iname \*.flv \
    -o -iname \*.f4v \
    -o -iname \*.wmv \
    -o -iname \*.mov \
    -o -iname \*.mkv \
    -o -iname \*.mp4 \
    -o -iname \*.avi \
    -o -iname \*.mpg \) \
    -print0 | while read -d $'\0' file; do
    echo "${file}"
    filename=$(basename -- "${file}")
    extension="${filename##*.}"
    filename_no_extension="${filename%.*}"

    "${SCRIPT_DIR}/ffmpeg-transcode.sh" -i "${file}" \
        -p "${preset}"  \
        -o encoded && [[ -f "encoded/${filename_no_extension}.mp4" ]] && rm -f "${file}"
#        -p "${preset}" -f "crop=$(${SCRIPT_DIR}/ffmpeg-cropdetect.sh "${file}" -q)" \
done

echo "Size of directory after transcoding: $(du -hs "${source}/encoded" | cut -f -1)"
