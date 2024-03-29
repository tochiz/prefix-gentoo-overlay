# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/eselect-php/eselect-php-0.6.4.ebuild,v 1.1 2011/02/28 12:34:04 olemarkus Exp $

EAPI=3

DESCRIPTION="PHP eselect module"
HOMEPAGE="http://www.gentoo.org"
SRC_URI="http://olemarkus.org/~olemarkus/gentoo/eselect-php-${PV}.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE=""

DEPEND=">=app-admin/eselect-1.2.4
		!app-admin/php-toolkit"
RDEPEND="${DEPEND}"

src_install() {
	mv eselect-php-${PV} php.eselect

	# install to prefix usr/bin
	sed -i -e 's/file \/usr\/bin/file "\${EPREFIX}"\/usr\/bin/' php.eselect || die
	sed -i -e 's/php-cgi \/usr\/bin/php-cgi "\${EPREFIX}"\/usr\/bin/' php.eselect || die
	sed -i -e 's/php-pfm \/usr\/bin/php-fpm "\${EPREFIX}"\/usr\/bin/' php.eselect || die

	insinto /usr/share/eselect/modules/
	doins php.eselect
}
