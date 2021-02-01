#!/bin/bash

arch=$(/usr/bin/arch)

if [ "$arch" == "arm64" ]; then
    echo "arm64 - Do some arm64 stuff here"
    #/usr/sbin/softwareupdate --install-rosetta --agree-to-license
    
elif [ "$arch" == "i386" ]; then
    echo "Intel - Do some intel stuff here"
else
    echo "Unknown Architecture"
fi