# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/x264/x264-0.0.20111220.ebuild,v 1.2 2012/02/04 11:48:11 ssuominen Exp $

EAPI=4

if [ "${PV#9999}" != "${PV}" ] ; then
	V_ECLASS="git-2"
else
	V_ECLASS="versionator"
fi

inherit multilib toolchain-funcs flag-o-matic ${V_ECLASS}

if [ "${PV#9999}" = "${PV}" ]; then
	MY_P="x264-snapshot-$(get_version_component_range 3)-2245"
fi
DESCRIPTION="A free library for encoding X264/AVC streams"
HOMEPAGE="http://www.videolan.org/developers/x264.html"
if [ "${PV#9999}" != "${PV}" ] ; then
	EGIT_REPO_URI="git://git.videolan.org/x264.git"
	SRC_URI=""
else
	SRC_URI="http://download.videolan.org/pub/videolan/x264/snapshots/${MY_P}.tar.bz2"
fi

LICENSE="GPL-2"
SLOT="0"
if [ "${PV#9999}" != "${PV}" ]; then
	KEYWORDS=""
else
	KEYWORDS="~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x86-solaris"
fi
IUSE="10bit custom-cflags debug +interlaced pic static-libs +threads"

RDEPEND=""
DEPEND="amd64? ( >=dev-lang/yasm-1 )
	x86? ( >=dev-lang/yasm-1 )
	x86-fbsd? ( >=dev-lang/yasm-1 )
	x86-macos? ( >=dev-lang/yasm-1 )
	x64-macos? ( >=dev-lang/yasm-1 )
	x86-solaris? ( >=dev-lang/yasm-1 )
	x64-solaris? ( >=dev-lang/yasm-1 )"

if [ "${PV#9999}" = "${PV}" ]; then
	S="${WORKDIR}/${MY_P}"
fi

DOCS="AUTHORS doc/*.txt"

src_prepare() {
	# epatch "${FILESDIR}"/${PN}-nostrip.patch \
	# 	   "${FILESDIR}"/${PN}-onlylib-20100605.patch

	# Solaris' /bin/sh doesn't grok the syntax in these files
	sed -i -e '1c\#!/usr/bin/env sh' configure version.sh || die
	# for sparc-solaris
	if [[ ${CHOST} == sparc*-solaris* ]] ; then
		sed -i -e 's:-DPIC::g' configure || die
	fi
	# for OSX
	sed -i -e "s|-arch x86_64||g" configure || die
}


src_configure() {
	tc-export CC

	local myconf=""
	use 10bit && myconf+=" --bit-depth=10"
	use debug && myconf+=" --enable-debug"
	use interlaced || myconf+=" --disable-interlaced"
	use static-libs && myconf+=" --enable-static"
	use threads || myconf+=" --disable-thread"

	# let upstream pick the optimization level by default
	use custom-cflags || filter-flags -O?

	if use x86 && use pic; then
		myconf+=" --disable-asm"
	fi

	./configure \
		--prefix="${EPREFIX}"/usr \
		--libdir="${EPREFIX}"/usr/$(get_libdir) \
		--disable-cli \
		--disable-avs \
		--disable-lavf \
		--disable-swscale \
		--disable-ffms \
		--disable-gpac \
		--enable-pic \
		--enable-shared \
		--host="${CHOST}" \
		${myconf} || die

	# this is a nasty workaround for bug #376925 as upstream doesn't like us
	# fiddling with their CFLAGS
	if use custom-cflags; then
		local cflags
		cflags="$(grep "^CFLAGS=" config.mak | sed 's/CFLAGS=//')"
		cflags="${cflags//$(get-flag O)/}"
		cflags="${cflags//-O? /$(get-flag O) }"
		cflags="${cflags//-g /}"
		sed -i "s:^CFLAGS=.*:CFLAGS=${cflags//:/\\:}:" config.mak
	fi
}
