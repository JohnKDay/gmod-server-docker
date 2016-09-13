#!/bin/bash
adduser --disabled-password --uid 1101 --gecos '' r
adduser r sudo
echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
su -c /start-server.sh
