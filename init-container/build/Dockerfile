FROM ubuntu:latest
RUN apt update \
    && apt install -y curl gnupg software-properties-common apt-transport-https ca-certificates inotify-tools \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt install -y docker-ce-cli
