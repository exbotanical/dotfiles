# Select the distro with --build-arg DISTRO=ubuntu|arch
# and the image with --target integ (.dev/integ-test.bash) or --target dev (.dev/boot-dev.bash).
ARG DISTRO=ubuntu

FROM ubuntu:24.04 AS base-ubuntu
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bash ca-certificates curl git i3-wm jq make nodejs npm rsync socat stow sudo vim \
  && rm -rf /var/lib/apt/lists/*

FROM archlinux:latest AS base-arch
RUN pacman -Syu --noconfirm --needed \
  bash ca-certificates curl git i3-wm jq make nodejs npm rsync socat stow sudo vim \
  && pacman -Scc --noconfirm

FROM base-${DISTRO} AS common
RUN curl -fsSL https://raw.githubusercontent.com/rylnd/shpec/master/install.sh | sh

RUN useradd --create-home --shell /bin/bash dev \
  && echo 'dev ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/dev \
  && chmod 0440 /etc/sudoers.d/dev

USER dev
WORKDIR /home/dev/dotfiles

FROM common AS integ
COPY --chown=dev:dev . .

# The hooks target runs `git config --local`, so the copy needs its own repository.
RUN git init --quiet \
  && git add --all \
  && git -c user.name=integ -c user.email=integ@localhost commit --quiet --message 'integ test snapshot'

ENTRYPOINT ["bash", ".dev/integ-test.bash"]

FROM common AS dev
ENTRYPOINT ["bash"]
