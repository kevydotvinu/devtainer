FROM ubuntu

ARG USER
ARG UID
ARG GO_VERSION=go

RUN apt-get update && \
    apt-get -y install git gcc make vim zip xz-utils curl jq gpgconf tmux zsh language-pack-en && \
    useradd -u ${UID} -ms /bin/zsh ${USER}

WORKDIR /home/$USER

USER $USER

RUN git config --global --add safe.directory /host && \
    git clone https://github.com/kevydotvinu/dotfiles && \
    cd dotfiles && make nvim && make go GO_VERSION=${GO_VERSION}

CMD /usr/bin/zsh
