# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/rtmpdump/rtmpdump-2.4.ebuild,v 1.2 2012/03/20 23:31:29 flameeyes Exp $

EAPI="4"

inherit eutils multilib toolchain-funcs

DESCRIPTION="Open source command-line RTMP client intended to stream audio or video flash content"
HOMEPAGE="http://rtmpdump.mplayerhq.hu/"
SRC_URI="http://dev.gentoo.org/~hwoarang/distfiles/${P}.tar.gz"

# the library is LGPL-2.1, the command is GPL-2
LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~arm ~hppa ~ppc ~ppc64 ~x86 ~x86-fbsd"
IUSE="gnutls polarssl ssl"

DEPEND="ssl? (
		gnutls? ( net-libs/gnutls )
		polarssl? ( !gnutls? ( >=net-libs/polarssl-0.14.0 ) )
		!gnutls? ( !polarssl? ( dev-libs/openssl ) )
	)
	sys-libs/zlib"
RDEPEND="${DEPEND}"

pkg_setup() {
	if ! use ssl && ( use gnutls ||	use polarssl ) ; then
		ewarn "USE='gnutls polarssl' are ignored without USE='ssl'."
		ewarn "Please review the local USE flags for this package."
	fi
}

src_prepare() {
	# fix Makefile ( bug #298535 , bug #318353 and bug #324513 )
	epatch "${FILESDIR}"/${PN}-2.4-macosx-makefile.patch

	sed -i 's/\$(MAKEFLAGS)//g' Makefile \
		|| die "failed to fix Makefile"
	sed -i -e 's:OPT=:&-fPIC :' \
		-e 's:OPT:OPTS:' \
		-e 's:CFLAGS=.*:& $(OPT):' librtmp/Makefile \
		|| die "failed to fix Makefile"
}

src_compile() {
	if use ssl ; then
		if use gnutls ;	then
			crypto="GNUTLS"
		elif use polarssl ; then
			crypto="POLARSSL"
		else
			crypto="OPENSSL"
		fi
	fi
	
	TARGETSYS=posix
	if [[ ${CHOST} == *-darwin* ]] ; then
		TARGETSYS=darwin
	fi

	#fix multilib-script support. Bug #327449
	sed -i "/^libdir/s:lib$:$(get_libdir)$:" librtmp/Makefile
	emake CC=$(tc-getCC) LD=$(tc-getLD) \
		OPT="${CFLAGS}" XLDFLAGS="${LDFLAGS}" prefix="${EPREFIX}${DESTTREE}" CRYPTO="${crypto}" SYS=${TARGETSYS}
}

src_install() {
	mkdir -p "${D}"/${EPREFIX}${DESTTREE}/$(get_libdir)
	emake DESTDIR="${D}" prefix="${EPREFIX}${DESTTREE}" mandir="${EPREFIX}${DESTTREE}/share/man" \
	SYS=${TARGETSYS} CRYPTO="${crypto}" install
	dodoc README ChangeLog rtmpdump.1.html rtmpgw.8.html
}
