FROM linuxserver/ffmpeg:latest

RUN apt-get update && apt-get install -y --no-install-recommends git-core zsh gawk

# invalidate cache if version.json changes
ADD https://api.github.com/repos/azmodude/ffmpeg-transcode/git/refs/heads/main version.json
RUN git clone https://github.com/azmodude/ffmpeg-transcode /transcode && \
    mkdir /encode
WORKDIR /encode

ENTRYPOINT ["/transcode/ffmpeg-transcode-dir.sh"]


