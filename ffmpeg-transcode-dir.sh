#!/bin/bash

# don't process empty globs
shopt -s nullglob

[[ -z "${1}" ]] && source='.' || source="${1}"
[[ -z "${2}" ]] && preset='slow' || preset="${1}"

[[ ! -d ./encoded ]] && mkdir ./encoded

echo "Size of Directory before transcoding: $(du -hs --exclude "${source}/encoded/*" "${source}" | cut -f -1)"

for file in $(find "${source}" \
    -maxdepth 1 \
    ! -path "./encoded/*" \
    \( -iname \*.flv \
    -o -iname \*.f4v \
    -o -iname \*.wmv \
    -o -iname \*.mov \
    -o -iname \*.mkv \
    -o -iname \*.mp4 \
    -o -iname \*.avi \
    -o -iname \*.mpg \) | sort -R); do
    filename=$(basename -- "$file")
    extension="${filename##*.}"
    filename="${filename%.*}"

    ffmpeg-transcode.sh -i "${file}" \
        -p "${preset}" -f "crop=$(ffmpeg-cropdetect.sh "${file}" -q)" \
        -o encoded && [[ -f "encoded/${filename}.mp4" ]] && rm -f "${file}"
done

echo "Size of directory after transcoding: $(du -hs "${source}/encoded" | cut -f -1)"
