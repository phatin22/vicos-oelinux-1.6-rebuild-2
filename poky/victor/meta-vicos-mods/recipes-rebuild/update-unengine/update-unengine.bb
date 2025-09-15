DESCRIPTION = "jank update engine for rebuild"
LICENSE = "Anki-Inc.-Proprietary"                                                                   
LIC_FILES_CHKSUM = "file://${COREBASE}/meta-qti-bsp/files/anki-licenses/\                           
Anki-Inc.-Proprietary;md5=4b03b8ffef1b70b13d869dbce43e8f09"

inherit systemd

SRC_URI += " \
    file://rebuild-update-unengine.sh \
    file://rebuild-update-unengine.service \
    file://rebuild-update-unengine.timer \
"

do_install () {
    mkdir -p ${D}/sbin
    install -m 0644 ${WORKDIR}/rebuild-update-unengine.service -D ${D}${systemd_unitdir}/system/rebuild-update-unengine.service
    install -m 0644 ${WORKDIR}/rebuild-update-unengine.timer -D ${D}${systemd_unitdir}/system/rebuild-update-unengine.timer
    install -p -m 0755 ${WORKDIR}/rebuild-update-unengine.sh ${D}/sbin/rebuild-update-unengine
}

FILES_${PN} += " \
    sbin/rebuild-update-unengine \
    ${systemd_unitdir}/system/rebuild-update-unengine.service \
    ${systemd_unitdir}/system/rebuild-update-unengine.timer \
"

SYSTEMD_SERVICE_${PN} = "rebuild-update-unengine.timer"
