#ARG NODEJS_VERSION="16.19.1"

#FROM balenalib/%%BALENA_MACHINE_NAME%%-debian-node:${NODEJS_VERSION}-bookworm-run
FROM node:lts-bookworm

# Install the necessary packages
COPY ./build /usr/src/build
RUN /usr/src/build/install_chromium "generic-amd64"

WORKDIR /usr/src/app

# install node dependencies
COPY ./package.json /usr/src/app/package.json
RUN JOBS=MAX npm install --unsafe-perm --production && npm cache clean --force

COPY ./src /usr/src/app/

RUN chmod +x ./*.sh

ENV UDEV=1

RUN mkdir -p /etc/chromium/policies
RUN mkdir -p /etc/chromium/policies/recommended
COPY ./policy.json /etc/chromium/policies/recommended/my_policy.json

# Add chromium user
RUN useradd chromium -m -s /bin/bash -G root || true && \
    groupadd -r -f chromium && id -u chromium || true \
    && chown -R chromium:chromium /home/chromium || true

COPY ./public-html /home/chromium  

# udev rule to set specific permissions 
RUN echo 'SUBSYSTEM=="vchiq",GROUP="video",MODE="0660"' > /etc/udev/rules.d/10-vchiq-permissions.rules
RUN usermod -a -G audio,video,tty chromium

# Set up the audio block. This won't have any effect if the audio block is not being used.
RUN curl -skL https://raw.githubusercontent.com/balena-labs-projects/audio/master/scripts/alsa-bridge/debian-setup.sh| sh
ENV PULSE_SERVER=tcp:audio:4317

COPY VERSION .

# Start app
CMD ["bash", "/usr/src/app/start.sh"]
