#!/bin/zsh

# (re-)encode a video file another (possibly better compressed) file.
# x264 version.

ffmpeg=$(command -v ffmpeg)
ffprobe=$(command -v ffprobe || command -v ffmpeg.ffprobe)
preset="slow"

parse_options()
{
    local -a file filter _help

    zparseopts -K -- i:=file f:=filter o:=outputdir h=_help
    if [[ $file == "" || $outputdir == "" || "$_help" != "" ]]; then
        echo Usage: ffmpeg-encode.sh "-i input -o outputdirectory [-f filters]"
        exit 1
    fi

    _file=$file[2]
    _filebase=$(basename ${_file})
    _vf=$filter[2]
    _outputdir=$outputdir[2]

}
parse_options $*

if [[ -z ${_outputdir} ]]; then
    if [[ ! -d ./done ]]; then
        mkdir ./done
    fi
    _outputdir='./done'
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
if [ -e ${_outputdir}/${_file} ]; then
    _outfile=${_filebase:r}_reencode.${_filebase:e}
else
    _outfile=${_filebase:r}.mp4
fi

# get resolution
resolution=$(${ffprobe} -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "${_file}")
if [[ $(echo $resolution | sed -r 's/^([0-9]+).*/\1/') -gt 2500 ]]; then
    vcodec="x265"
else
    vcodec="x264"
fi

_common_options='-hide_banner -loglevel warning -stats'
# $=audio forces word splitting. Else we would pass in -acodec... with ' quotes
# zsh does it that way, bash does not
if [[ ${vcodec} == "x264" ]]; then
    if [[ ${_vf} != "" ]]; then
        set -x
        ${ffmpeg} ${=_common_options} -i "${_file}" -vf ${_vf} -vcodec libx264 \
        -profile:v high -level 4.1 -map_metadata 0:g \
        -preset "${preset}" -crf 23 \
        -movflags faststart ${=audio} -strict -2 \
        -metadata title="${_title}" \
        "${_outputdir}/${_outfile}"
        [ $? -eq 0 ] || exit 1
        set +x
    else
        set -x
        ${ffmpeg} ${=_common_options} -i "${_file}" -vcodec libx264 -profile:v high -level 4.1 \
        -map_metadata 0:g -preset "${preset}" -crf 23 -movflags faststart \
        ${=audio} -strict -2 -metadata title="${_title}" \
        "${_outputdir}/${_outfile}"
        [ $? -eq 0 ] || exit 1
        set +x
    fi
else
    if [[ ${_vf} != "" ]]; then
        set -x
        ${ffmpeg} ${=_common_options} -i "${_file}" -vf ${_vf} -vcodec libx265 \
        -map_metadata 0:g \
        -preset "${preset}" -crf 28 \
        -movflags faststart ${=audio} -strict -2 \
        -metadata title="${_title}" \
        "${_outputdir}/${_outfile}"
        [ $? -eq 0 ] || exit 1
        set +x
    else
        set -x
        ${ffmpeg} ${=_common_options} -i "${_file}" -vcodec libx265 \
        -map_metadata 0:g -preset "${preset}" -crf 28 -movflags faststart \
        ${=audio} -strict -2 -metadata title="${_title}" \
        "${_outputdir}/${_outfile}"
        [ $? -eq 0 ] || exit 1
        set +x
    fi
fi

