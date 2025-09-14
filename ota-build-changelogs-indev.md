# Indev ota changelogs
## https://modder.my.to/otas/1.6-rebuild/indev/
## If you want to use 1.6-rebuild do NOT use these images, use the release ones instead

## 1.6.1.0010 (2025/09/13)
First yocto ota, remove 1.6-specific customization temporarily, temp remove auto update implementation, no need to auth to change wifi networks, re-enable alexa, change faultcodehandler time limits, remove blackjack requests.

## 1.6.1.0009 (2025/09/01)
Change 1.6 settings to 1.6-rebuild settings, add face overlays, add Falling and Space Daydream animations, mm-anki-camera always trys to target 30 fps now, brand new auto update system rerwitten from scratch.

## 1.6.1.0008 (2025/08/20)
Wired broke due to it calling for /usr/bin/sleep and not /bin/sleep, this ota is just a fix for that

## 1.6.1.0007 (2025/08/20)
Manully cleaned update-os for this build, nothing else.

## 1.6.1.0006 (2025/08/20 (Actually 2025/08/19 but it's like 11:45pm and I really don't wanna build any otas right now))
Use new rampost boot images made by Toastito in V&F, make /data executable by default, make update-os up the cpu speeds and stop anki processes remove sb_server since we use picovoice now, port over wireutils from wireOS, re-enable HMP, cleaned kernel.

## 1.6.1.0005 (2025/08/19)
Don't copy in prebuilt ramposts and modules, use the one made with the ota, remove unneeded stuff from dvcbs-reloaded to hopefully cut down repo size a little, fix dynamic cpu speed on Vector 2.0 by updating Victor commit to [dd358480a177c6fa6d9a78dcd18a51900b806bb4](https://github.com/Switch-modder/victor-1.6-rebuild/commit/dd358480a177c6fa6d9a78dcd18a51900b806bb4).

## 1.6.1.0004 (2025/08/19)
Actually make the new different ramposts apply, don't clean anki every rebuild since cmake should be able to figure out what it needs to recompile should it have to happen.

## 1.6.1.0003 (2025/08/18)
Add a seperate proddev bitbake option, use different ramposts to confirm that we can have build specific ramposts.

## 1.6.1.0002 (2025/08/18)
Fixed the prod boot images so that they boot again, add new 1.6-rebuild rampost images.

## 1.6.1.0001 (2025/08/18)
Wired fully works, PicoVoice wakeword training works, changed OSKR messages to ankidevunit.

## 1.6.1.0000 (2025/08/16)
Dev only, first ota run, basically plain vicos-oelinux-nosign but with 1.6 anki.
