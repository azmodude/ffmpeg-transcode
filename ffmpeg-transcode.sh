#!/bin/zsh

# (re-)encode a video file another (possibly better compressed) file.
# x264 version.

ffmpeg=$(command -v ffmpeg)
ffprobe=$(command -v ffprobe || command -v ffmpeg.ffprobe)

parse_options()
{
    local -a file filter _help

    zparseopts -K -- i:=file p:=preset f:=filter o:=outputdir h=_help
    if [[ $file == "" || $outputdir == "" || "$_help" != "" ]]; then
        echo Usage: ffmpeg-encode.sh "-i input -o outputdirectory [-f filters]"
        exit 1
    fi

    _file=$file[2]
    _preset=$preset[2]
    _filebase=$(basename "$_file")
    _vf=$filter[2]
    _outputdir=$outputdir[2]

}
parse_options "$@"

if [[ -z ${_outputdir} ]]; then
    if [[ ! -d ./done ]]; then
        mkdir ./done
    fi
    _outputdir='./done'
fi

echo "--------------------------------------------------------------------------------"
size_before=$(du -hs "$_file" | cut -f1)
echo "Size of ${_filebase} before transcode: ${size_before}"

duration=$("$ffprobe" -v error -select_streams v:0 -show_entries stream=duration \
    -of default=noprint_wrappers=1:nokey=1 -sexagesimal "$_file")
echo "Duration of ${_filebase}: ${duration}"

# get dimension to crop a video by it's (possible) black borders, skipping to minute three first, process 3 minutes
# The leading < /dev/null IS IMPORTANT, else ffmpeg drops into command mode, reading stdin
cropsize=$(< /dev/null ffmpeg -ss 00:03:00 -i "$_file" -vf cropdetect -t 00:03:00 -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1)
echo "Cropsize of ${_filebase} is: ${cropsize}"
# keep 1080p at 1080
# make this an array, so it expands to nothing if it is actually empty down below
filter=()
if [[ "${cropsize}" != "crop=1920:1072:0:4" ]]; then
  filter+="-vf '${cropsize}'"
fi

# if audio stream isn't aac, transcode. Else just copy it.
#audio_type=$(${ffprobe} -v error -select_streams a:0 \
#    -show_entries stream=codec_name -of default=nw=1 "${_file}"| cut -d'=' -f2)
#if [[ ${audio_type} == 'aac' ]]; then
#    audio='-acodec copy'
#else
#    audio='-acodec libfdk_aac -b:a 96k'
#fi

# always transcode for now
# audio='-acodec libfdk_aac -b:a 96k'
audio='-c:a libfdk_aac -profile:a aac_he_v2 -b:a 32k'

# create title for ffmpeg metadata
# (C)=Capitalize words,:t=only filename,:r=no extension
_title=$(echo "${(C)_file:t:r}" | sed -r 's/[-_.]/ /g')

# if file already exists in outputdir, rename output
if [ -e "$_outputdir/$_file" ]; then
    _outfile=${_filebase:r}_reencode.${_filebase:e}
else
    _outfile=${_filebase:r}.mp4
fi

# get resolution
resolution=$("$ffprobe" -v error -select_streams v:0 -show_entries \
    stream=width,height -of csv=s=x:p=0 "$_file")
if [[ $(echo "$resolution" | sed -r 's/^([0-9]+).*/\1/') -gt 2500 ]]; then
    vcodec="x265"
else
    vcodec="x264"
fi

_common_options='-nostdin -hide_banner -loglevel warning -stats'
# $=audio forces word splitting. Else we would pass in -acodec... with ' quotes
# zsh does it that way, bash does not
if [[ ${vcodec} == "x264" ]]; then
    set -x
    time "$ffmpeg" "${=_common_options}" -i "$_file" "${filter[@]}" -vcodec libx264 \
    -profile:v high -level 4.1 -map_metadata 0:g \
    -preset "$_preset" -crf 23 \
    -movflags faststart "${=audio}" -strict -2 \
    -metadata title="$_title" \
    "${_outputdir}/${_outfile}"
    [ $? -eq 0 ] || exit 1
    set +x
else
    set -x
    time "$ffmpeg" "${=_common_options}" -i "$_file" "${filter[@]}" -vcodec libx265 \
    -map_metadata 0:g \
    -preset "$_preset" -crf 28 \
    -movflags faststart "${=audio}" -strict -2 \
    -metadata title="$_title" \
    "${_outputdir}/${_outfile}"
    [ $? -eq 0 ] || exit 1
    set +x
fi

size_after=$(du -hs "${_outputdir}/${_outfile}" | cut -f1)
echo "Size of ${_outfile} after transcode: ${size_after}"
echo "--------------------------------------------------------------------------------"
