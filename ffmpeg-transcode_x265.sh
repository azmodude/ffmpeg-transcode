#!/bin/zsh
#
# (re-)encode a video file another (possibly better compressed) file.
# x265 version.

ffmpeg=$(command -v ffmpeg)
ffprobe=$(command -v ffprobe || command -v ffmpeg.ffprobe)

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
audio_type=$(${ffprobe} -v error -select_streams a:0 \
    -show_entries stream=codec_name -of default=nw=1 "${_file}"| cut -d'=' -f2)
if [[ ${audio_type} == 'aac' ]]; then
    audio='-acodec copy'
else
    audio='-acodec libfdk_aac -b:a 96k'
fi

# always transcode for now
audio='-acodec libfdk_aac -b:a 96k'
# create title for ffmpeg metadata
_title=$(echo "${(C)_file:r}" | sed -r 's/[-_.]/ /g')

preset='fast'
# $=audio forces word splitting. Else we would pass in -acodec... with ' quotes
# zsh does it that way, bash does not
if [[ ${_vf} != "" ]]; then
    ${ffmpeg} -i "${_file}" -vf ${_vf} -vcodec libx265 \
    -preset ${preset} -crf 27 -movflags +faststart $=audio -strict -2 \
    -metadata title="${_title}" \
    "${_outputdir}/${_filebase:r}.mp4"
else
    ${ffmpeg} -i "${_file}" -vcodec libx265 \
    -preset ${preset} -crf 27 -movflags +faststart $=audio -strict -2 \
    -metadata title="${_title}" \
    "${_outputdir}/${_filebase:r}.mp4"
fi

