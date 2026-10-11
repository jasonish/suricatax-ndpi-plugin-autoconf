AC_PREREQ([2.69])
AC_INIT([suricata-ndpi-plugin], [0.1.0-dev],
        [https://redmine.openinfosecfoundation.org/],
        [suricata-ndpi-plugin])
AC_CONFIG_SRCDIR([src/ndpi.c])
AC_CONFIG_MACRO_DIR([m4])

# This header is only included by src/ndpi.c. Suricata's own installed
# autoconf.h also defines PACKAGE_*, so the plugin source undefines ours
# before including any Suricata header. See src/ndpi.c.
AC_CONFIG_HEADERS([src/ndpi-plugin-config.h])

# no-define: keep PACKAGE/VERSION out of the config header, they would
# clash with Suricata's autoconf.h.
AM_INIT_AUTOMAKE([1.11 foreign subdir-objects no-define -Wall])
AM_SILENT_RULES([yes])

# If no --prefix is given, default to the prefix Suricata was installed
# into (found by locating libsuricata-config in PATH).
AC_PREFIX_PROGRAM([libsuricata-config])

AC_PROG_CC
AC_PROG_CPP
AM_PROG_AR
LT_INIT([shared disable-static])
PKG_PROG_PKG_CONFIG

AC_DEFINE_UNQUOTED([NDPI_PLUGIN_VERSION], ["$PACKAGE_VERSION"],
                   [Version of the nDPI plugin])

# ---------------------------------------------------------------------------
# Suricata
#
# Headers are found, in order of preference, from:
#   1. --with-suricata=PREFIX: a Suricata installation prefix with
#      headers installed ("make install install-headers"), for example
#      /opt/suricata/9.0.0-dev. Headers are taken from
#      PREFIX/include/suricata. Also the default install prefix.
#   2. --with-suricata-source=DIR: a configured and built Suricata
#      source tree (useful for development).
#   3. SURICATA_CFLAGS from the environment.
#   4. libsuricata-config --cflags (--with-suricata-config=PATH, or
#      found in PATH). Requires "make install-headers install-library"
#      to have been run for Suricata.
# ---------------------------------------------------------------------------

AC_ARG_VAR([SURICATA_CFLAGS], [C preprocessor flags for Suricata headers])

AC_ARG_WITH([suricata],
    [AS_HELP_STRING([--with-suricata=PREFIX],
        [Suricata installation prefix with installed headers])],
    [with_suricata="$withval"], [with_suricata=no])

AC_ARG_WITH([suricata-source],
    [AS_HELP_STRING([--with-suricata-source=DIR],
        [use headers from a configured and built Suricata source tree])],
    [with_suricata_source="$withval"], [with_suricata_source=no])

AC_ARG_WITH([suricata-config],
    [AS_HELP_STRING([--with-suricata-config=PATH],
        [path to libsuricata-config @<:@default: search PATH@:>@])],
    [LIBSURICATA_CONFIG="$withval"], [LIBSURICATA_CONFIG=""])

suricata_headers_from=""
AS_IF([test "x$with_suricata" = "xyes"], [
    AC_MSG_ERROR([--with-suricata requires a path])
], [test "x$with_suricata" != "xno"], [
    AS_IF([test ! -e "$with_suricata/include/suricata/suricata-plugin.h"],
        [AC_MSG_ERROR([Suricata headers not found in $with_suricata/include/suricata; run "make install-headers" for Suricata])])
    SURICATA_CFLAGS="-DHAVE_CONFIG_H -I$with_suricata/include/suricata"
    suricata_headers_from="prefix $with_suricata"
    # Install into the Suricata prefix unless --prefix was given.
    AS_IF([test "x$prefix" = "xNONE"], [prefix="$with_suricata"])
], [test "x$with_suricata_source" != "xno" && test "x$with_suricata_source" != "xyes"], [
    AS_IF([test ! -e "$with_suricata_source/src/autoconf.h"],
        [AC_MSG_ERROR([$with_suricata_source does not look like a configured Suricata source tree (src/autoconf.h missing)])])
    SURICATA_CFLAGS="-DHAVE_CONFIG_H -I$with_suricata_source/src -I$with_suricata_source/rust/gen -I$with_suricata_source/rust/dist"
    suricata_headers_from="source tree $with_suricata_source"
], [test "x$with_suricata_source" = "xyes"], [
    AC_MSG_ERROR([--with-suricata-source requires a path])
], [test "x$SURICATA_CFLAGS" != "x"], [
    suricata_headers_from="SURICATA_CFLAGS"
], [
    AS_IF([test "x$LIBSURICATA_CONFIG" = "x"],
        [AC_PATH_PROG([LIBSURICATA_CONFIG], [libsuricata-config], [no])])
    AS_IF([test "x$LIBSURICATA_CONFIG" = "xno" || test ! -x "$LIBSURICATA_CONFIG"],
        [AC_MSG_ERROR([libsuricata-config not found. Install Suricata with
"make install install-headers install-library", put libsuricata-config
in PATH, or use --with-suricata-config, --with-suricata-source or
SURICATA_CFLAGS])])
    SURICATA_CFLAGS="`$LIBSURICATA_CONFIG --cflags`"
    suricata_headers_from="$LIBSURICATA_CONFIG"
])
AC_SUBST([SURICATA_CFLAGS])

# Suricata's logging requires every compilation unit to define
# __SCFILENAME__.
saved_CPPFLAGS="$CPPFLAGS"
CPPFLAGS="$CPPFLAGS $SURICATA_CFLAGS -D__SCFILENAME__=\"conftest\""

AC_CHECK_HEADER([suricata-plugin.h], [],
    [AC_MSG_ERROR([Suricata headers not found (SURICATA_CFLAGS=$SURICATA_CFLAGS)])],
    [#include "suricata-common.h"])

AC_MSG_CHECKING([for Suricata version])
cat > conftest.c <<EOF
#include "autoconf.h"
SURICATA_VERSION=PACKAGE_VERSION
EOF
suricata_version=`$CPP $CPPFLAGS conftest.c 2>/dev/null | sed -n 's/^SURICATA_VERSION="\(.*\)"$/\1/p'`
rm -f conftest.c
AC_MSG_RESULT([$suricata_version])

# This branch supports Suricata main (9.0 development). Suricata 8.0 is
# supported on the main-8.0.x branch.
suricata_version_major=`echo "$suricata_version" | sed -n 's/^\([[0-9]]*\)\..*/\1/p'`
AS_IF([test "x$suricata_version_major" = "x"],
    [AC_MSG_ERROR([unable to determine the Suricata version])])
AS_IF([test "$suricata_version_major" -lt 9],
    [AC_MSG_ERROR([Suricata main (9.0 development) is required, found $suricata_version; use the main-8.0.x branch for Suricata 8.0])])

CPPFLAGS="$saved_CPPFLAGS"

# ---------------------------------------------------------------------------
# nDPI
#
#   --with-ndpi=DIR    DIR is either a built nDPI source tree (the static
#                      src/lib/libndpi.a is linked, as Suricata does), or
#                      an nDPI installation prefix.
#   otherwise          pkg-config libndpi (NDPI_CFLAGS/NDPI_LIBS may be
#                      used to override).
#
#   --enable-static-ndpi  link the static libndpi.a found via pkg-config
#                         or the installation prefix into the plugin, so
#                         it does not depend on libndpi.so at runtime.
# ---------------------------------------------------------------------------

AC_ARG_WITH([ndpi],
    [AS_HELP_STRING([--with-ndpi=DIR],
        [nDPI source tree or installation prefix @<:@default: use pkg-config@:>@])],
    [with_ndpi="$withval"], [with_ndpi=""])

AC_ARG_ENABLE([static-ndpi],
    [AS_HELP_STRING([--enable-static-ndpi],
        [link nDPI statically into the plugin])],
    [enable_static_ndpi="$enableval"], [enable_static_ndpi=no])

ndpi_from=""
AS_IF([test "x$with_ndpi" = "xno"], [
    AC_MSG_ERROR([nDPI is required])
], [test "x$with_ndpi" != "x" && test "x$with_ndpi" != "xyes"], [
    AS_IF([test -e "$with_ndpi/src/include/ndpi_api.h"], [
        AS_IF([test ! -e "$with_ndpi/src/lib/libndpi.a"],
            [AC_MSG_ERROR([$with_ndpi/src/lib/libndpi.a not found, build nDPI first])])
        NDPI_CFLAGS="-I$with_ndpi/src/include"
        NDPI_LIBS="$with_ndpi/src/lib/libndpi.a -lm"
        ndpi_from="source tree $with_ndpi (static)"
    ], [test -e "$with_ndpi/include/ndpi/ndpi_api.h"], [
        ndpi_libdir=""
        for d in lib64 lib; do
            AS_IF([test -e "$with_ndpi/$d/libndpi.a" || test -e "$with_ndpi/$d/libndpi.so"],
                [ndpi_libdir="$with_ndpi/$d"; break])
        done
        AS_IF([test "x$ndpi_libdir" = "x"],
            [AC_MSG_ERROR([libndpi not found in $with_ndpi/lib or $with_ndpi/lib64])])
        NDPI_CFLAGS="-I$with_ndpi/include/ndpi"
        AS_IF([test "x$enable_static_ndpi" = "xyes"],
            [NDPI_LIBS="$ndpi_libdir/libndpi.a -lm"; ndpi_from="$with_ndpi (static)"],
            [NDPI_LIBS="-L$ndpi_libdir -lndpi -lm"; ndpi_from="$with_ndpi"])
    ], [
        AC_MSG_ERROR([$with_ndpi is neither an nDPI source tree nor an nDPI installation prefix])
    ])
], [
    PKG_CHECK_MODULES([NDPI], [libndpi >= 4.14 libndpi < 5])
    ndpi_from="pkg-config"
    AS_IF([test "x$enable_static_ndpi" = "xyes"], [
        ndpi_libdir=`$PKG_CONFIG --variable=libdir libndpi`
        AS_IF([test ! -e "$ndpi_libdir/libndpi.a"],
            [AC_MSG_ERROR([--enable-static-ndpi: $ndpi_libdir/libndpi.a not found])])
        NDPI_LIBS="$ndpi_libdir/libndpi.a `$PKG_CONFIG --static --libs-only-other --libs-only-l libndpi | sed 's/-lndpi//'`"
        ndpi_from="pkg-config (static)"
    ])
])
AC_SUBST([NDPI_CFLAGS])
AC_SUBST([NDPI_LIBS])

saved_CPPFLAGS="$CPPFLAGS"
saved_LIBS="$LIBS"
CPPFLAGS="$CPPFLAGS $NDPI_CFLAGS"

AC_CHECK_HEADER([ndpi_api.h], [],
    [AC_MSG_ERROR([ndpi_api.h not found (NDPI_CFLAGS=$NDPI_CFLAGS)])])

# nDPI 5.0 changed the APIs used by the plugin, so only 4.x is supported.
# Checked from the headers, as --with-ndpi does not use pkg-config.
AC_MSG_CHECKING([for nDPI 4.14 or newer 4.x])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#include "ndpi_api.h"]], [[
#if NDPI_MAJOR != 4 || NDPI_MINOR < 14
#error unsupported nDPI version
#endif
]])], [AC_MSG_RESULT([yes])], [
    AC_MSG_RESULT([no])
    AC_MSG_ERROR([unsupported nDPI version; nDPI 4.14 or a newer 4.x release is required])
])

AC_MSG_CHECKING([nDPI library links])
LIBS="$NDPI_LIBS $LIBS"
AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include "ndpi_api.h"]],
    [[ndpi_revision();]])],
    [AC_MSG_RESULT([yes])],
    [AC_MSG_RESULT([no])
     AC_MSG_ERROR([cannot link with nDPI (NDPI_LIBS=$NDPI_LIBS)])])

CPPFLAGS="$saved_CPPFLAGS"
LIBS="$saved_LIBS"

# ---------------------------------------------------------------------------
# Installation directory
# ---------------------------------------------------------------------------

AC_ARG_WITH([plugindir],
    [AS_HELP_STRING([--with-plugindir=DIR],
        [plugin install directory @<:@default: PREFIX/lib/suricata@:>@])],
    [plugindir="$withval"], [plugindir='${prefix}/lib/suricata'])
AC_SUBST([plugindir])

AC_ARG_ENABLE([warnings],
    [AS_HELP_STRING([--enable-warnings], [build with -Wall -Wextra -Werror])],
    [enable_warnings="$enableval"], [enable_warnings=no])
WARN_CFLAGS=""
AS_IF([test "x$enable_warnings" = "xyes"],
    [WARN_CFLAGS="-Wall -Wextra -Wno-unused-parameter -Werror"])
AC_SUBST([WARN_CFLAGS])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT

plugindir_expanded=`test "x$prefix" = xNONE && prefix=$ac_default_prefix; eval echo "$plugindir"`

AC_MSG_RESULT([
$PACKAGE_NAME $PACKAGE_VERSION

  Suricata version:   $suricata_version
  Suricata headers:   $suricata_headers_from
  SURICATA_CFLAGS:    $SURICATA_CFLAGS
  nDPI:               $ndpi_from
  NDPI_CFLAGS:        $NDPI_CFLAGS
  NDPI_LIBS:          $NDPI_LIBS
  Plugin directory:   $plugindir_expanded
])
