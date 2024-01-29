FROM debian:bullseye-slim as build

RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt-get install --yes --no-install-recommends git python3 build-essential cmake ca-certificates && \
    apt-get install --yes --no-install-recommends gcc-arm-linux-gnueabihf libc6-dev-armhf-cross libc6:armhf libstdc++6:armhf && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

RUN git clone https://github.com/ptitSeb/box86.git; mkdir /box86/build && \
    git clone https://github.com/ptitSeb/box64.git; mkdir /box64/build

WORKDIR /box86/build
RUN cmake .. -DRPI4ARM64=1 -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc) && \
    make install DESTDIR=/tmp/install

WORKDIR /box64/build
RUN cmake .. -DRPI4ARM64=1 -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    make -j$(nproc) && \
    make install DESTDIR=/tmp/install

FROM debian:bullseye-slim
# Set environment variables
ENV USER root
ENV HOME /root

LABEL org.opencontainers.image.authors="Sebastian Schmidt"
LABEL org.opencontainers.image.source="https://github.com/jammsen/docker-palworld-dedicated-server"

COPY --from=build /tmp/install /

RUN apt-get update
RUN apt-get install -y --no-install-recommends --no-install-suggests procps xdg-user-dirs curl
RUN apt-get clean
RUN apt-get autoremove -y
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN dpkg --add-architecture armhf
RUN apt-get update
RUN apt-get install --yes --no-install-recommends libc6:armhf libstdc++6:armhf
RUN apt-get -y autoremove
RUN apt-get clean autoclean
RUN rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists

# Latest releases available at https://github.com/aptible/supercronic/releases
#ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64 \
#    SUPERCRONIC=supercronic-linux-amd64 \
#    SUPERCRONIC_SHA1SUM=cd48d45c4b10f3f0bfdd3a57d054cd05ac96812b

#RUN curl -fsSLO "$SUPERCRONIC_URL" \
#    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
#    && chmod +x "$SUPERCRONIC" \
#    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
#    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

ADD --chown=steam:steam --chmod=755 servermanager.sh /servermanager.sh
ADD --chown=steam:steam --chmod=755 backupmanager.sh /backupmanager.sh

# Set working directory
WORKDIR $HOME

# Insert Steam prompt answers
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo steam steam/question select "I AGREE" | debconf-set-selections \
 && echo steam steam/license note '' | debconf-set-selections

# Update the repository and install SteamCMD
ARG DEBIAN_FRONTEND=noninteractive
COPY sources.list /etc/apt/sources.list
RUN dpkg --add-architecture i386 \
 && apt-get update -y \
 && apt-get install -y --no-install-recommends ca-certificates locales steamcmd \
 && rm -rf /var/lib/apt/lists/*

# Add unicode support
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen en_US.UTF-8
ENV LANG 'en_US.UTF-8'
ENV LANGUAGE 'en_US:en'

# Create symlink for executable
RUN ln -s /usr/games/steamcmd /usr/bin/steamcmd

# Update SteamCMD and verify latest version
RUN box64 steamcmd +quit

# Fix missing directories and libraries
RUN mkdir -p $HOME/.steam \
 && ln -s $HOME/.local/share/Steam/steamcmd/linux32 $HOME/.steam/sdk32 \
 && ln -s $HOME/.local/share/Steam/steamcmd/linux64 $HOME/.steam/sdk64 \
 && ln -s $HOME/.steam/sdk32/steamclient.so $HOME/.steam/sdk32/steamservice.so \
 && ln -s $HOME/.steam/sdk64/steamclient.so $HOME/.steam/sdk64/steamservice.so


EXPOSE 8211/udp
EXPOSE 25575/tcp

RUN mkdir /palworld \
    && chown steam:steam /palworld

VOLUME [ "/palworld" ]

USER steam


ENV DEBIAN_FRONTEND=noninteractive \
    PUID=0 \
    PGID=0 \
    # Container setttings
    TZ="Europe/Berlin"   \
    ALWAYS_UPDATE_ON_START=true \
    MULTITHREAD_ENABLED=true \
    COMMUNITY_SERVER=true \
    BACKUP_ENABLED=true \
    BACKUP_CRON_EXPRESSION="0 * * * *" \
    STEAMCMD_VALIDATE_FILES=true \
    SERVER_SETTINGS_MODE=auto \
    # Server-setting 
    NETSERVERMAXTICKRATE=120 \
    DIFFICULTY=None \
    DAYTIME_SPEEDRATE=1.000000 \
    NIGHTTIME_SPEEDRATE=1.000000 \
    EXP_RATE=1.000000 \
    PAL_CAPTURE_RATE=1.000000 \
    PAL_SPAWN_NUM_RATE=1.000000 \
    PAL_DAMAGE_RATE_ATTACK=1.000000 \
    PAL_DAMAGE_RATE_DEFENSE=1.000000 \
    PLAYER_DAMAGE_RATE_ATTACK=1.000000 \
    PLAYER_DAMAGE_RATE_DEFENSE=1.000000 \
    PLAYER_STOMACH_DECREASE_RATE=1.000000 \
    PLAYER_STAMINA_DECREACE_RATE=1.000000 \
    PLAYER_AUTO_HP_REGENE_RATE=1.000000 \
    PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP=1.000000 \
    PAL_STOMACH_DECREACE_RATE=1.000000 \
    PAL_STAMINA_DECREACE_RATE=1.000000 \
    PAL_AUTO_HP_REGENE_RATE=1.000000 \
    PAL_AUTO_HP_REGENE_RATE_IN_SLEEP=1.000000 \
    BUILD_OBJECT_DAMAGE_RATE=1.000000 \
    BUILD_OBJECT_DETERIORATION_DAMAGE_RATE=1.000000 \
    COLLECTION_DROP_RATE=1.000000 \
    COLLECTION_OBJECT_HP_RATE=1.000000 \
    COLLECTION_OBJECT_RESPAWN_SPEED_RATE=1.000000 \
    ENEMY_DROP_ITEM_RATE=1.000000 \
    DEATH_PENALTY=All \
    ENABLE_PLAYER_TO_PLAYER_DAMAGE=false \
    ENABLE_FRIENDLY_FIRE=false \
    ENABLE_INVADER_ENEMY=true \
    ACTIVE_UNKO=false \
    ENABLE_AIM_ASSIST_PAD=true \
    ENABLE_AIM_ASSIST_KEYBOARD=false \
    DROP_ITEM_MAX_NUM=3000 \
    DROP_ITEM_MAX_NUM_UNKO=100 \
    BASE_CAMP_MAX_NUM=128 \
    BASE_CAMP_WORKER_MAXNUM=15 \
    DROP_ITEM_ALIVE_MAX_HOURS=1.000000 \
    AUTO_RESET_GUILD_NO_ONLINE_PLAYERS=false \
    AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS=72.000000 \
    GUILD_PLAYER_MAX_NUM=20 \
    PAL_EGG_DEFAULT_HATCHING_TIME=72.000000 \
    WORK_SPEED_RATE=1.000000 \
    IS_MULTIPLAY=false \
    IS_PVP=false \
    CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP=false \
    ENABLE_NON_LOGIN_PENALTY=true \
    ENABLE_FAST_TRAVEL=true \
    IS_START_LOCATION_SELECT_BY_MAP=true \
    EXIST_PLAYER_AFTER_LOGOUT=false \
    ENABLE_DEFENSE_OTHER_GUILD_PLAYER=false \
    COOP_PLAYER_MAX_NUM=4 \
    MAX_PLAYERS=32 \
    SERVER_NAME="jammsen-docker-generated-###RANDOM###" \
    SERVER_DESCRIPTION="Palworld-Dedicated-Server running in Docker by jammsen" \
    ADMIN_PASSWORD=adminPasswordHere \
    SERVER_PASSWORD=serverPasswordHere \
    PUBLIC_PORT=8211 \
    PUBLIC_IP= \
    RCON_ENABLED=false \
    RCON_PORT=25575 \
    REGION= \
    USEAUTH=true \
    BAN_LIST_URL=https://api.palworldgame.com/api/banlist.txt

CMD ["/servermanager.sh"]
