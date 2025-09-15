#!/bin/bash

set -e

REBUILD_COMMIT=0b73d0dfd0a8f18047db6cfd7f96f7be25220650

if [[ ${RUN_FROM_MAIN} != "1" ]]; then
    echo "Don't run this standalone, this is supposed to tail off docker-ota-build or vm-ota-build"
    exit 1
else
    unset $RUN_FROM_MAIN
fi

if [[ ${PRODorOSKR} == "proddev" ]]; then
    export BUILD_TYPE=prod
    export FINAL_BUILD_TYPE=
elif [[ ${PRODorOSKR} == "epdev" ]]; then
    export BUILD_TYPE=prod
    export FINAL_BUILD_TYPE=
elif [[ ${PRODorOSKR} == "prod" ]]; then
    export BUILD_TYPE=prod
    export FINAL_BUILD_TYPE=
elif [[ ${PRODorOSKR} == "ep" ]]; then
    export BUILD_TYPE=prod
    export FINAL_BUILD_TYPE=
elif [[ ${PRODorOSKR} == "oskr" ]]; then
    export BUILD_TYPE=oskr
    export FINAL_BUILD_TYPE=oskr
elif [[ ${PRODorOSKR} == "dev" ]]; then
    export BUILD_TYPE=dev
    export FINAL_BUILD_TYPE=d
fi

if [[ ! -d anki/victor-1.6/project ]]; then
    echo "Cloning Victor"
    git clone --recurse-submodules  https://github.com/Victor-Rebuild/victor-1.6-rebuild -b 1.6-yocto-3 anki/victor-1.6
fi

cd anki/victor-1.6

#if [[ ${ELLIE} = "1" ]]; then
    git pull
    git checkout $REBUILD_COMMIT
    cd EXTERNALS
    git pull
    cd ../
#fi

echo "Building Victor"
./build/build-v.sh
./project/victor/scripts/stage.sh -c Release

cd ../dvcbs-reloaded
sudo mkdir -p mounted/
sudo mv ../../_build/vicos-1.6.1.$INCREMENT$FINAL_BUILD_TYPE.ota mounted/ -v

sudo ./dvcbs-reloaded.sh -m

sudo rm -rf mounted/edits/anki -v
sudo mv ../victor-1.6/_build/staging/Release/anki mounted/edits/anki -v

if [[ ${BUILD_STACK} == "indev" ]]; then
    echo "Build is a Indev build"
    sudo touch mounted/edits/etc/rebuild-indev
elif [[ ${BUILD_STACK} == "release" ]]; then
    echo "Build is a Release build"
    sudo touch mounted/edits/etc/rebuild-release
else
    echo "Not built from build and send script, assuming indev"
    sudo touch mounted/edits/etc/rebuild-indev
fi

sudo ./dvcbs-reloaded.sh -bt 1.6.1 $INCREMENT $BUILD_TYPE

sudo mv mounted/* ../../_build/vicos-1.6.1.$INCREMENT$FINAL_BUILD_TYPE.ota

cd ../../
