#!/bin/bash

sudo chmod +x type-ubuntu24.04/*

(
 cd ./type-ubuntu24.04 || exit 1
 sudo ./build.sh
)

mv ./type-ubuntu24.04/rootfs.ext4 .