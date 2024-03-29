# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/ffmpeg/ffmpeg-0.10.2.ebuild,v 1.10 2012/04/15 18:17:55 armin76 Exp $

EAPI="4"

SCM=""
if [ "${PV#9999}" != "${PV}" ] ; then
	SCM="git-2"
	EGIT_REPO_URI="git://git.videolan.org/ffmpeg.git"
fi

inherit eutils flag-o-matic multilib toolchain-funcs ${SCM}

DESCRIPTION="Complete solution to record, convert and stream audio and video. Includes libavcodec."
HOMEPAGE="http://ffmpeg.org/"
if [ "${PV#9999}" != "${PV}" ] ; then
	SRC_URI=""
elif [ "${PV%_p*}" != "${PV}" ] ; then # Snapshot
	SRC_URI="mirror://gentoo/${P}.tar.bz2"
else # Release
	SRC_URI="http://ffmpeg.org/releases/${P/_/-}.tar.bz2"
fi
FFMPEG_REVISION="${PV#*_p}"

LICENSE="GPL-2 amr? ( GPL-3 ) encode? ( aac? ( GPL-3 ) )"
SLOT="0"
if [ "${PV#9999}" = "${PV}" ] ; then
	# KEYWORDS="alpha amd64 arm hppa ia64 ~ppc ~ppc64 sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux"
	KEYWORDS="~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"
fi
IUSE="
	aac aacplus alsa amr ass bindist +bzip2 cdio celt cpudetection debug
	dirac doc +encode faac frei0r gnutls gsm +hardcoded-tables ieee1394 jack
	jpeg2k libv4l modplug mp3 network openal openssl oss pic pulseaudio
	rtmp schroedinger sdl speex static-libs test theora threads
	truetype v4l vaapi vdpau vorbis vpx X x264 xvid +zlib
	"

# String for CPU features in the useflag[:configure_option] form
# if :configure_option isn't set, it will use 'useflag' as configure option
CPU_FEATURES="3dnow:amd3dnow 3dnowext:amd3dnowext altivec avx mmx mmxext:mmx2 ssse3 vis neon"

for i in ${CPU_FEATURES}; do
	IUSE="${IUSE} ${i%:*}"
done

FFTOOLS="aviocat cws2fws ffeval graph2dot ismindex pktdumper qt-faststart trasher"

for i in ${FFTOOLS}; do
	IUSE="${IUSE} +fftools_$i"
done

RDEPEND="
	alsa? ( media-libs/alsa-lib )
	amr? ( media-libs/opencore-amr )
	ass? ( media-libs/libass )
	bzip2? ( app-arch/bzip2 )
	cdio? ( dev-libs/libcdio )
	celt? ( >=media-libs/celt-0.11.1 )
	dirac? ( media-video/dirac )
	encode? (
		aac? ( media-libs/vo-aacenc )
		aacplus? ( media-libs/libaacplus )
		amr? ( media-libs/vo-amrwbenc )
		faac? ( media-libs/faac )
		mp3? ( >=media-sound/lame-3.98.3 )
		theora? ( >=media-libs/libtheora-1.1.1[encode] media-libs/libogg )
		vorbis? ( media-libs/libvorbis media-libs/libogg )
		x264? ( >=media-libs/x264-0.0.20111017 )
		xvid? ( >=media-libs/xvid-1.1.0 )
	)
	frei0r? ( media-plugins/frei0r-plugins )
	gnutls? ( >=net-libs/gnutls-2.12.16 )
	gsm? ( >=media-sound/gsm-1.0.12-r1 )
	ieee1394? ( media-libs/libdc1394 sys-libs/libraw1394 )
	jack? ( media-sound/jack-audio-connection-kit )
	jpeg2k? ( >=media-libs/openjpeg-1.3-r2 )
	libv4l? ( media-libs/libv4l )
	modplug? ( media-libs/libmodplug )
	openal? ( >=media-libs/openal-1.1 )
	pulseaudio? ( media-sound/pulseaudio )
	rtmp? ( >=media-video/rtmpdump-2.2f )
	sdl? ( >=media-libs/libsdl-1.2.13-r1[audio,video] )
	schroedinger? ( media-libs/schroedinger )
	speex? ( >=media-libs/speex-1.2_beta3 )
	truetype? ( media-libs/freetype:2 )
	vaapi? ( >=x11-libs/libva-0.32 )
	vdpau? ( x11-libs/libvdpau )
	vpx? ( >=media-libs/libvpx-0.9.6 )
	X? ( x11-libs/libX11 x11-libs/libXext x11-libs/libXfixes )
	zlib? ( sys-libs/zlib )
	!media-video/qt-faststart
"

DEPEND="${RDEPEND}
	>=sys-devel/make-3.81
	dirac? ( dev-util/pkgconfig )
	doc? ( app-text/texi2html )
	gnutls? ( dev-util/pkgconfig )
	ieee1394? ( dev-util/pkgconfig )
	libv4l? ( dev-util/pkgconfig )
	mmx? ( dev-lang/yasm )
	rtmp? ( dev-util/pkgconfig )
	schroedinger? ( dev-util/pkgconfig )
	test? ( net-misc/wget )
	truetype? ( dev-util/pkgconfig )
	v4l? ( sys-kernel/linux-headers )
"
# faac is license-incompatible with ffmpeg
REQUIRED_USE="bindist? ( encode? ( !faac !aacplus ) !openssl )
	libv4l? ( v4l )
	fftools_cws2fws? ( zlib )
	test? ( encode zlib )"

S=${WORKDIR}/${P/_/-}

src_prepare() {
	if [ "${PV%_p*}" != "${PV}" ] ; then # Snapshot
		export revision=git-N-${FFMPEG_REVISION}
	fi
	epatch "${FILESDIR}/freiordl.patch"
}

src_configure() {
	local myconf="${EXTRA_FFMPEG_CONF}"
	# Set to --enable-version3 if (L)GPL-3 is required
	local version3=""

	# enabled by default
	for i in debug doc network vaapi vdpau zlib; do
		use ${i} || myconf="${myconf} --disable-${i}"
	done
	use bzip2 || myconf="${myconf} --disable-bzlib"
	use sdl || myconf="${myconf} --disable-ffplay"

	use cpudetection && myconf="${myconf} --enable-runtime-cpudetect"
	use openssl && myconf="${myconf} --enable-openssl --enable-nonfree"
	for i in gnutls ; do
		use $i && myconf="${myconf} --enable-$i"
	done

	# Encoders
	if use encode
	then
		use mp3 && myconf="${myconf} --enable-libmp3lame"
		use aac && { myconf="${myconf} --enable-libvo-aacenc" ; version3=" --enable-version3" ; }
		use amr && { myconf="${myconf} --enable-libvo-amrwbenc" ; version3=" --enable-version3" ; }
		for i in theora vorbis x264 xvid; do
			use ${i} && myconf="${myconf} --enable-lib${i}"
		done
		use aacplus && myconf="${myconf} --enable-libaacplus --enable-nonfree"
		use faac && myconf="${myconf} --enable-libfaac --enable-nonfree"
	else
		myconf="${myconf} --disable-encoders"
	fi

	# libavdevice options
	use cdio && myconf="${myconf} --enable-libcdio"
	use ieee1394 && myconf="${myconf} --enable-libdc1394"
	use openal && myconf="${myconf} --enable-openal"
	# Indevs
	# v4l1 is gone since linux-headers-2.6.38
	myconf="${myconf} --disable-indev=v4l"
	use v4l || myconf="${myconf} --disable-indev=v4l2"
	for i in alsa oss jack ; do
		use ${i} || myconf="${myconf} --disable-indev=${i}"
	done
	use X && myconf="${myconf} --enable-x11grab"
	use pulseaudio && myconf="${myconf} --enable-libpulse"
	use libv4l && myconf="${myconf} --enable-libv4l2"
	# Outdevs
	for i in alsa oss sdl ; do
		use ${i} || myconf="${myconf} --disable-outdev=${i}"
	done
	# libavfilter options
	use frei0r && myconf="${myconf} --enable-frei0r"
	use truetype && myconf="${myconf} --enable-libfreetype"
	use ass && myconf="${myconf} --enable-libass"

	# Threads; we only support pthread for now but ffmpeg supports more
	use threads && myconf="${myconf} --enable-pthreads"

	# Decoders
	use amr && { myconf="${myconf} --enable-libopencore-amrwb --enable-libopencore-amrnb" ; version3=" --enable-version3" ; }
	for i in celt gsm dirac modplug rtmp schroedinger speex vpx; do
		use ${i} && myconf="${myconf} --enable-lib${i}"
	done
	use jpeg2k && myconf="${myconf} --enable-libopenjpeg"

	# CPU features
	for i in ${CPU_FEATURES}; do
		use ${i%:*} || myconf="${myconf} --disable-${i#*:}"
	done
	if use pic ; then
		myconf="${myconf} --enable-pic"
		# disable asm code if PIC is required
		# as the provided asm decidedly is not PIC for x86.
		use x86 && myconf="${myconf} --disable-asm"
	fi

	# Try to get cpu type based on CFLAGS.
	# Bug #172723
	# We need to do this so that features of that CPU will be better used
	# If they contain an unknown CPU it will not hurt since ffmpeg's configure
	# will just ignore it.
	for i in $(get-flag march) $(get-flag mcpu) $(get-flag mtune) ; do
		[ "${i}" = "native" ] && i="host" # bug #273421
		myconf="${myconf} --cpu=${i}"
		break
	done

	# Mandatory configuration
	myconf="
		--enable-gpl
		${version3}
		--enable-postproc
		--enable-avfilter
		--disable-stripping
		${myconf}"

	# cross compile support
	if tc-is-cross-compiler ; then
		myconf="${myconf} --enable-cross-compile --arch=$(tc-arch-kernel) --cross-prefix=${CHOST}-"
		case ${CHOST} in
			*freebsd*)
				myconf="${myconf} --target-os=freebsd"
				;;
			mingw32*)
				myconf="${myconf} --target-os=mingw32"
				;;
			*linux*)
				myconf="${myconf} --target-os=linux"
				;;
		esac
	fi

	# Misc stuff
	use hardcoded-tables && myconf="${myconf} --enable-hardcoded-tables"

	cd "${S}"
	./configure \
		--prefix="${EPREFIX}/usr" \
		--libdir="${EPREFIX}/usr/$(get_libdir)" \
		--shlibdir="${EPREFIX}/usr/$(get_libdir)" \
		--mandir="${EPREFIX}/usr/share/man" \
		--enable-shared \
		--cc="$(tc-getCC)" \
		--cxx="$(tc-getCXX)" \
		--ar="$(tc-getAR)" \
		--optflags="${CFLAGS}" \
		--extra-cflags="${CFLAGS}" \
		--extra-cxxflags="${CXXFLAGS}" \
		$(use_enable static-libs static) \
		${myconf} || die
}

src_compile() {
	emake

	for i in ${FFTOOLS} ; do
		if use fftools_$i ; then
			emake tools/$i
		fi
	done
}

src_install() {
	emake DESTDIR="${D}" install install-man

	dodoc Changelog README INSTALL
	dodoc -r doc/*

	for i in ${FFTOOLS} ; do
		if use fftools_$i ; then
			dobin tools/$i
		fi
	done
}

src_test() {
	LD_LIBRARY_PATH="${S}/libpostproc:${S}/libswscale:${S}/libswresample:${S}/libavcodec:${S}/libavdevice:${S}/libavfilter:${S}/libavformat:${S}/libavutil" \
		emake fate
}
