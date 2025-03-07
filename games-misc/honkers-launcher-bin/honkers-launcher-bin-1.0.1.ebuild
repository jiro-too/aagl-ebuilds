# copyright 2022 ShinobuNarusaka, Pascal Jager
# Distributed under the terms of the GNU General Public License v3

EAPI=8

inherit xdg-utils optfeature desktop

DESCRIPTION="Honkers Game launcher with automatic anti-cheat patching, binary package"
HOMEPAGE="https://github.com/an-anime-team/an-anime-game-launcher"
SRC_URI="https://github.com/an-anime-team/honkers-launcher/releases/download/${PV}/honkers-launcher-${PV}.AppImage -> ${P}.AppImage"

LICENSE="GPL-3 0BSD Apache-2.0 BSD-2 BSD ISC MIT Unlicense"
SLOT="0"
KEYWORDS="~amd64"
PATCHES=( "${FILESDIR}/${PN}-launcher.patch"  )

# bottom dependencies added because iwdevtools' qa-vdb detected them
DEPEND="
	net-libs/webkit-gtk:4=
	dev-util/xdelta:3[lzma]
	app-arch/tar
	dev-vcs/git
	app-arch/unzip
	net-misc/curl
	app-arch/cabextract
	x11-libs/libnotify

	dev-libs/glib:2
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libxcb:=
	"

RDEPEND="${DEPEND}"

BDEPEND="dev-util/patchelf"

src_unpack() {
	mkdir "${WORKDIR}"/${P} || die
	cp "${DISTDIR}"/${P}.AppImage "${WORKDIR}"/${P} || die
}

src_prepare(){
	chmod +x ${P}.AppImage
	./${P}.AppImage --appimage-extract || die "Extraction Failed"
	patchelf squashfs-root/public/discord-rpc/discord-rpc --set-rpath '/usr/lib/an-anime-game-launcher-bin/public/discord-rpc/'
	default
	mv "squashfs-root/public/icons/256x256.png" "${PN}.png" || die
	mv "squashfs-root/AppRun" "${PN}" || die
	mv "squashfs-root/honkers-launcher.desktop" "${PN}.desktop" || die
	# patch the .desktop file to work in non-AppImage environment
	sed -i 's/Icon=64x64/Icon=honkers-launcher-bin/' honkers-launcher-bin.desktop
	sed -i 's/Exec=AppRun/Exec=honkers-launcher-bin/' honkers-launcher-bin.desktop
	sed -i 's/;//' honkers-launcher-bin.desktop
	sed -i '/X-AppImage-Version=/d' honkers-launcher-bin.desktop
	echo "Comment=Honkers Game launcher with automatic anti-cheat patching, binary package" >> honkers-launcher-bin.desktop
	sed '/^$/d' honkers-launcher-bin.desktop
}

src_install(){
	insinto "/usr/lib/${PN}"
	doins squashfs-root/resources.neu
	exeinto "/usr/lib/${PN}"
	doexe squashfs-root/honkers-launcher
	doins -r squashfs-root/public
	exeinto "/usr/lib/${PN}/public/discord-rpc"
	doexe squashfs-root/public/discord-rpc/discord-rpc
	exeinto /usr/bin
	doexe "${PN}"
	doicon "${PN}.png"
	domenu "${PN}.desktop"
}

pkg_postinst() {
	xdg_desktop_database_update
	optfeature "Appindicator support" dev-libs/libayatana-appindicator dev-libs/libayatana-appindicator-bin
}
pkg_postrm() {
	xdg_desktop_database_update
}
