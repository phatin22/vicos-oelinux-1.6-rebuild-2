#!/bin/bash

EXPECTED_HASH_ELLIE="d454e1542f11d6432e24ced777faa285  -"

unset DO_SIGN

clear

echo "Hey, is this build going to the release or indev stack"
echo -n "(Release/Indev): "
read release_or_indev

if [[ ${release_or_indev} == "Indev" ]]; then
    echo "Build is a Indev build"
    export BUILD_STACK=indev
elif [[ ${release_or_indev} == "Release" ]]; then
    echo "Build is a Release build"
    export BUILD_STACK=release
else
    echo "Build type is not Release or Indev"
    exit 1
fi

echo
echo "What is this ota's version code?"
echo
echo "For Indev use a 4 digit format even if the build is only the 5th build"
echo "Example: 5th Indev build is 0005"
echo
echo "For Release just add 1 to the last release number"
echo "If the last release was 21 add 1 and you get 22, so type 22"
echo
echo -n "(Version Code?): "
read version
echo "Version code set to $version"
echo

VERSION_CODE=$version

echo "Now, did you get permission from Ellie to send your builds to the server?"
echo -n "(yes/no): "
read ellie_or_not

if [[ ${ellie_or_not} == "yes" ]]; then
    echo "Alright fine, you can continue"
elif [[ ${ellie_or_not} == "no" ]]; then
    echo "Then don't use this script"
    exit 1
else
    echo "That's not a yes or no"
    exit 1
fi

echo
echo "Alright we need the passwords now, what's the prod boot password?"
echo -n "(aka, the ABOOT/qtipri password): "
read prod_boot_password

if openssl rsa -in ota/qtipri.encrypted.key -passin pass:"$prod_boot_password" -noout 2>/dev/null; then
    echo "Prod boot image key password confirmed to be correct!"
else
    echo
    echo -e "\033[1;31mProd boot image signing password is incorrect. exiting.\033[0m"
    echo -e "\033[1;31mHINT: we are using an older version of the key which has the same password as the ABOOT key\033[0m"
    echo
    exit 1
fi

echo
echo "Prod password is good, now what's the oskr boot password?"
echo -n "(aka, qtioskrpri password): "
read oskr_boot_password

if openssl rsa -in ota/qtioskrpri.encrypted.key -passin pass:"$oskr_boot_password" -noout 2>/dev/null; then
    echo "OSKR boot image key password confirmed to be correct!"
else
    echo
    echo -e "\033[1;31mOSKR boot image signing password is incorrect. exiting.\033[0m"
    echo
    exit 1
fi

echo
echo "The boot image passwords seem fine, what is the ota password now?"
echo -n "(aka, ota_prod.key): "
read ota_password

if openssl rsa -in ota/ota_prod.key -passin pass:"$ota_password" -noout 2>/dev/null; then
    echo "OTA key password confirmed to be correct!"
    export OTA_PASS=$ota_password
else
    echo
    echo -e "\033[1;31mOTA signing password is incorrect. exiting.\033[0m"
    echo
    exit 1
fi

echo
echo "Just so we're clear, this is gonna build a dev, oskr and prod ota and send it to the $release_or_indev stack on modder.my.to"
echo "Are we good with this?"
echo -n "(yes/no): "
read confirm_send

if [[ ${confirm_send} == "yes" ]]; then
    echo "Alright, better hope you have the root key at ~/modder-my-key"
elif [[ ${confirm_send} == "no" ]]; then
    echo "Alright bye!"
else
    echo "That's not a yes or no"
    exit 1
fi

echo "Starting build"

echo "Dev ota first"
time ./build/build.sh -bt dev -v $VERSION_CODE
scp -P 44 -i ~/modder-my-key _build/*.ota raj-jyot@modder.my.to:/media/raj-jyot/modder-my-to/webserver/otas/1.6-rebuild/$BUILD_STACK/dev/

echo "Now for OSKR"
time ./build/build.sh -bt oskr -bp $oskr_boot_password -v $VERSION_CODE
scp -P 44 -i ~/modder-my-key _build/*.ota raj-jyot@modder.my.to:/media/raj-jyot/modder-my-to/webserver/otas/1.6-rebuild/$BUILD_STACK/oskr/

echo "And finally Prod"
time ./build/build.sh -bt proddev -bp $prod_boot_password -v $VERSION_CODE
scp -P 44 -i ~/modder-my-key _build/*.ota raj-jyot@modder.my.to:/media/raj-jyot/modder-my-to/webserver/otas/1.6-rebuild/$BUILD_STACK/prod/

echo
echo "Setting version as latest"
echo 1.6.1.$VERSION_CODE > latest
scp -P 44 -i ~/modder-my-key latest raj-jyot@modder.my.to:/media/raj-jyot/modder-my-to/webserver/otas/1.6-rebuild/$BUILD_STACK/latest
rm latest

echo
echo "Unsetting variables"
unset $VERSION_CODE $prod_boot_password $oskr_boot_password $OTA_PASS $ota_password $BUILD_STACK
echo

echo "Done! Builds should be at https://modder.my.to/otas/1.6-rebuild/$BUILD_STACK/"
