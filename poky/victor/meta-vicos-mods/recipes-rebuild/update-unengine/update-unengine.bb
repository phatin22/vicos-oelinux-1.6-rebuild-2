DESCRIPTION = "jank update engine for rebuild"
LICENSE = "Anki-Inc.-Proprietary"
LIC_FILES_CHKSUM = "file://${COREBASE}/../victor/meta-qcom/files/anki-licenses/\
Anki-Inc.-Proprietary;md5=4b03b8ffef1b70b13d869dbce43e8f09"

inherit systemd

SRC_URI += " \
    file://rebuild-update-unengine.sh \
    file://rebuild-update-unengine.service \
    file://rebuild-update-unengine.timer \
"

S = "${UNPACKDIR}"

do_install () {
    install -d ${D}/usr/sbin
    install -d ${D}${systemd_unitdir}/system
    
    install -m 0755 ${UNPACKDIR}/rebuild-update-unengine.sh ${D}/usr/sbin/rebuild-update-unengine
    install -m 0644 ${UNPACKDIR}/rebuild-update-unengine.service ${D}${systemd_unitdir}/system/rebuild-update-unengine.service
    install -m 0644 ${UNPACKDIR}/rebuild-update-unengine.timer ${D}${systemd_unitdir}/system/rebuild-update-unengine.timer
}

FILES:${PN} += " \
    /usr/sbin/rebuild-update-unengine \
    ${systemd_unitdir}/system/rebuild-update-unengine.service \
    ${systemd_unitdir}/system/rebuild-update-unengine.timer \
"

SYSTEMD_SERVICE:${PN} = "rebuild-update-unengine.timer"