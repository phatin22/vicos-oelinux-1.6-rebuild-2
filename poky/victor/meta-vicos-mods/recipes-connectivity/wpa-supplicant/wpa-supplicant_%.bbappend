FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://disable-sae.conf"

do_install:append() {
    cat ${UNPACKDIR}/disable-sae.conf \
        >> ${D}${sysconfdir}/wpa_supplicant.conf
}

do_configure:append() {
    # a fix for WPA3 networks - we can't support SAE

    sed -i -e 's/^CONFIG_IEEE80211W=.*$/CONFIG_IEEE80211W=n/' \
           ${S}/wpa_supplicant/.config

    sed -i -e 's/^CONFIG_SAE.*$/CONFIG_SAE=n/' \
           ${S}/wpa_supplicant/.config
}

