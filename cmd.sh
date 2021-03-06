#!/usr/bin/env bash

. ./docker/build-assets/scripts/utils.sh
. ./docker/build-assets/scripts/env_vars.sh

if [ ! -d "core" ]; then
    echo "X please clone core in core/folder"
    exit 1
fi

if ! [ -x "$(command -v docker)" ]; then
    echo "X Please install docker"
    exit 1
fi

COMMITSHA=$(cd core; git show -s --format=%h)

if [ "$VERSION" == "" ]; then
    VERSION=$(cat core/package.json | jq -r ".version")
    read -r -p "Do you want to build version $VERSION? (y/n): " YN

    if [ "$YN" != "y" ]; then
        exit 0;
    fi
fi

if [ "$NETWORK" == "" ]; then
    read -r -p "Is this a mainnet build? (y/n): " YN

    if [ "$YN" == "y" ]; then
        NETWORK="mainnet"
    else
        NETWORK="testnet"
    fi
fi


cd docker

echo "Creating build environment…"
sleep 2
exec_cmd "docker build . -t bbn_build_env"
exit_if_prevfail
echo "$GC Environment built"
sleep 2

cd ..
echo "Creating package…"
sleep 2
exec_cmd "docker run --rm -e \"COMMITSHA=${COMMITSHA}\" -v $(pwd):/home/bbn/tar -v $(pwd)/core:/home/bbn/core bbn_build_env"
exit_if_prevfail

FINAL_NAME="bbn_${VERSION}_${NETWORK}_${COMMITSHA}.tar.gz"
mv out.tar.gz $FINAL_NAME
sha1sum "$FINAL_NAME" > "${FINAL_NAME}.sha1"

echo "$GC Image created. ${FINAL_NAME}"
