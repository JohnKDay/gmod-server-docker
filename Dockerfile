FROM debian:wheezy

MAINTAINER John Day "jkday@inafish.net"

# ------------
# Prepare Gmod
# ------------

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install lib32gcc1 wget git
RUN mkdir /steamcmd
WORKDIR /steamcmd
RUN wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz
RUN tar -xvzf steamcmd_linux.tar.gz
RUN mkdir /gmod-base
RUN /steamcmd/steamcmd.sh +login anonymous +force_install_dir /gmod-base +app_update 4020 validate +quit

# ----------------
# Annoying lib fix
# ----------------

RUN mkdir /gmod-libs
WORKDIR /gmod-libs
RUN wget http://launchpadlibrarian.net/195509222/libc6_2.15-0ubuntu10.10_i386.deb
RUN dpkg -x libc6_2.15-0ubuntu10.10_i386.deb .
RUN cp lib/i386-linux-gnu/* /gmod-base/bin/
WORKDIR /
RUN rm -rf /gmod-libs
RUN cp /steamcmd/linux32/libstdc++.so.6 /gmod-base/bin/

#RUN mkdir /root/.steam
#RUN mkdir /root/.steam/sdk32/
#RUN cp /gmod-base/bin/libsteam.so /root/.steam/sdk32

# ----------------------
# Download and install Ulysses
# ----------------------

WORKDIR /
RUN git clone https://github.com/Nayruden/Ulysses.git /tmp/Ulysses
RUN ["/bin/cp","-rp","/tmp/Ulysses/ulib","/gmod-base/garrysmod/addons"]
RUN ["/bin/cp","-rp","/tmp/Ulysses/ulx","/gmod-base/garrysmod/addons"]
RUN rm -rf /tmp/Ulysses

# ----------------------
# Setup Volume and Union
# ----------------------

RUN mkdir /gmod-volume
VOLUME /gmod-volume
RUN mkdir /gmod-union
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install unionfs-fuse 


# ---------------
# Setup Container
# ---------------

ADD start-server.sh /start-server.sh
ADD entry.sh /entry.sh
EXPOSE 27015/udp
EXPOSE 27015/tcp
EXPOSE 27005/udp
EXPOSE 27006/tcp

ENV PORT="27015"
ENV MAXPLAYERS="16"
ENV G_HOSTNAME="Garry's Mod"
ENV GAMEMODE="sandbox"
ENV MAP="gm_construct"

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install sudo supervisor openssh-server
RUN rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd /var/log/supervisor && \
    rm -f /etc/ssh/ssh_host_*key*

COPY sshd_config /etc/ssh/sshd_config
COPY entrypoint /
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 22


#CMD ["/bin/sh", "/entry.sh"]
#CMD ["/bin/sh", "/start-server.sh"]
CMD ["/usr/bin/supervisord"]
