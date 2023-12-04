FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y \
  git \
  curl \
  htop \
  iputils-ping \
  vim \
  fish \
  openssh-client \
  unrar \
  axel \
  whois \
  fzf \
  cmake \
  build-essential \
  virtualenv \
  nethogs \
  iftop \
  net-tools \
  apt-transport-https \
  yarn \
  ansible \ 
  awscli \
  software-properties-common \
  wget \
  openvpn \
  sudo \
  unzip


RUN wget https://releases.hashicorp.com/vault/1.3.2/vault_1.3.2_linux_amd64.zip
RUN unzip vault_1.3.2_linux_amd64.zip
RUN mv vault /usr/local/bin/

RUN echo "tizi ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN useradd -rm -d /work -s /bin/fish -g root -G sudo -u 1000 tizi
WORKDIR '/work'

USER tizi

#RUN curl -L https://get.oh-my.fish | fish

CMD apt-get update
ENTRYPOINT ["/bin/fish"]
