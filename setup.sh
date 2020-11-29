#!/bin/bash
set -eo pipefail
VERSION="${1:-2.4.00}"

if [ ! -d "jsettlers-$VERSION-full" ]
then
  curl -sL "https://github.com/jdmonin/JSettlers2/releases/download/release-$VERSION/jsettlers-$VERSION-full.tar.gz" | tar xzf -
fi

APP_VER=$VERSION docker-compose up -d --build
