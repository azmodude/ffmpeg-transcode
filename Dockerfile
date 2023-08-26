FROM linuxserver/ffmpeg:latest

RUN apt-get update && apt-get install -y --no-install-recommends git-core zsh
RUN git clone https://github.com/azmodude/ffmpeg-transcode /transcode && \
    mkdir /encode
WORKDIR /encode

ENTRYPOINT ["/transcode/ffmpeg-transcode-dir.sh"]


