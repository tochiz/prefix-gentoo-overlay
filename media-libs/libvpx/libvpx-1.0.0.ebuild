# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libvpx/libvpx-0.9.7-r1.ebuild,v 1.3 2011/12/26 11:07:28 armin76 Exp $

EAPI=4
inherit eutils multilib toolchain-funcs

if [[ ${PV} == *9999* ]]; then
	inherit git-2
	EGIT_REPO_URI="git://review.webmproject.org/${PN}.git"
	KEYWORDS=""
elif [[ ${PV} == *pre* ]]; then
	SRC_URI="mirror://gentoo/${P}.tar.bz2"
	KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~x86 ~x86-fbsd ~amd64-linux ~x86-linux"
else
	MY_P="${PN}-v${PV}"
	SRC_URI="http://webm.googlecode.com/files/${MY_P}.tar.bz2"
	KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~x86 ~x86-fbsd ~amd64-linux ~x86-linux"
	S="${WORKDIR}/${MY_P}"
fi

DESCRIPTION="WebM VP8 Codec SDK"
HOMEPAGE="http://www.webmproject.org"

LICENSE="BSD"
SLOT="0"
IUSE="altivec debug doc mmx postproc sse sse2 sse3 ssse3 static-libs +threads"

RDEPEND=""
DEPEND="amd64? ( dev-lang/yasm )
	x86? ( dev-lang/yasm )
	x86-fbsd? ( dev-lang/yasm )
	doc? (
		app-doc/doxygen
		dev-lang/php
	)
"

REQUIRED_USE="
	sse2? ( mmx )
	"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0.9.5-enable-shared.patch
	if [[ ${CHOST} == *-darwin* ]] ; then
		epatch "${FILESDIR}"/${PN}-1.0.0-macosx-fix-makefile.patch
	fi
}

src_configure() {
	# http://bugs.gentoo.org/show_bug.cgi?id=384585
	addpredict /usr/share/snmp/mibs/.index

	tc-export CC
	local archparams=""
	[ "$ABI" = "x86" ] && archparams=" --target=x86-linux-gcc"
	[ "$ABI" = "amd64" ] && archparams=" --target=x86_64-linux-gcc"
	( use x86 || use amd64 ) && archparams+=" --as=yasm"
	./configure \
		--prefix="${EPREFIX}"/usr \
		--libdir="${EPREFIX}"/usr/$(get_libdir) \
		--enable-pic \
		--enable-vp8 \
		--enable-shared \
		$(use_enable altivec) \
		$(use_enable debug debug-libs) \
		$(use_enable debug) \
		$(use_enable doc install-docs) \
		$(use_enable mmx) \
		$(use_enable postproc) \
		$(use_enable sse) \
		$(use_enable sse2) \
		$(use_enable sse3) \
		$(use_enable ssse3) \
		$(use_enable static-libs static) \
		$(use_enable threads multithread) \
		$archparams \
		|| die
}

src_install() {
	# http://bugs.gentoo.org/show_bug.cgi?id=323805
	emake -j1 DESTDIR="${D}" install

	dodoc AUTHORS CHANGELOG README
}
