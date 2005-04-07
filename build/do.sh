#!/bin/sh
# $Id: do.sh,v 1.86 2005-04-07 17:19:07 ghudson Exp $

source=/mit/source
srvd=/.srvd
contained=false
mungepath=true
n=""
maybe=""

usage() {
  echo "Usage: do [-np] [-s srcdir] [-d destdir]" 1>&2
  echo "	[dist|prepare|clean|all|check|install]" 1>&2
  exit 1
}

while getopts pd:ns: opt; do
  case "$opt" in
  p)
    mungepath=false
    ;;
  d)
    srvd=$OPTARG
    ;;
  n)
    n=-n
    maybe=echo
    ;;
  s)
    source=$OPTARG
    ;;
  \?)
    usage
    ;;
  esac
done
shift `expr "$OPTIND" - 1`
operation=${1-all}

case "$operation" in
dist|prepare|clean|all|check|install)
  ;;
*)
  echo Unknown operation \"$operation\" 1>&2
  usage
  ;;
esac

# Set up the build environment.
umask 022
export ATHENA_SYS ATHENA_SYS_COMPAT ATHENA_HOSTTYPE OS PATH

# Determine proper ATHENA_SYS and ATHENA_SYS_COMPAT value.
case `uname -srm` in
"SunOS 5.10 sun4"*)
  ATHENA_SYS=sun4x_510
  ATHENA_SYS_COMPAT=sun4x_59:sun4x_58:sun4x_57:sun4x_56:sun4x_55:sun4m_54
  ATHENA_SYS_COMPAT=${ATHENA_SYS_COMPAT}:sun4m_53:sun4m_412
  ;;
"SunOS 5.9 sun4"*)
  ATHENA_SYS=sun4x_59
  ATHENA_SYS_COMPAT=sun4x_58:sun4x_57:sun4x_56:sun4x_55:sun4m_54:sun4m_53
  ATHENA_SYS_COMPAT=${ATHENA_SYS_COMPAT}:sun4m_412
  ;;
"SunOS 5.8 sun4"*)
  ATHENA_SYS=sun4x_58
  ATHENA_SYS_COMPAT=sun4x_57:sun4x_56:sun4x_55:sun4m_54:sun4m_53:sun4m_412
  ;;
"SunOS 5.7 sun4"*)
  ATHENA_SYS=sun4x_57
  ATHENA_SYS_COMPAT=sun4x_56:sun4x_55:sun4m_54:sun4m_53:sun4m_412
  ;;
"SunOS 5.6 sun4"*)
  ATHENA_SYS=sun4x_56
  ATHENA_SYS_COMPAT=sun4x_55:sun4m_54:sun4m_53:sun4m_412
  ;;
"SunOS 5.5 sun4"*)
  ATHENA_SYS=sun4x_55
  ATHENA_SYS_COMPAT=sun4m_54:sun4m_53:sun4m_412
  ;;
"SunOS 5.4 sun4"*)
  ATHENA_SYS=sun4m_54
  ATHENA_SYS_COMPAT=sun4m_53:sun4m_412
  ;;
Linux\ 2.2.*\ i?86)
  ATHENA_SYS=i386_linux22
  ATHENA_SYS_COMPAT=i386_linux3:i386_linux2:i386_linux1
  ;;
Linux\ 2.4.*\ i?86)
  case `cat /etc/redhat-release` in
  "Red Hat Linux release 7.3 "*)
    ATHENA_SYS=i386_linux24
    ATHENA_SYS_COMPAT=i386_linux22:i386_linux3:i386_linux2:i386_linux1
    ;;
  "Red Hat Linux release 9 "*)
    ATHENA_SYS=i386_rh9
    ATHENA_SYS_COMPAT=i386_linux24:i386_linux22:i386_linux3:i386_linux2
    ATHENA_SYS_COMPAT=${ATHENA_SYS_COMPAT}:i386_linux1
    ;;
  "Red Hat Enterprise Linux"*"release 3"*)
    ATHENA_SYS=i386_rhel3
    ATHENA_SYS_COMPAT=i386_rh9:i386_linux24:i386_linux22:i386_linux3
    ATHENA_SYS_COMPAT=${ATHENA_SYS_COMPAT}:i386_linux2:i386_linux1
    ;;
  *)
    echo "Unrecognized Red Hat release, aborting." 1>&2
    exit 1
    ;;
  esac
  ;;
Linux\ 2.6.*\ i?86)
  ATHENA_SYS=i386_rhel4
  ATHENA_SYS_COMPAT=i386_rhel3:i386_rh9:i386_linux24:i386_linux22:i386_linux3
  ATHENA_SYS_COMPAT=${ATHENA_SYS_COMPAT}:i386_linux2:i386_linux1
  ;;
*)
  echo "Unrecognized system type, aborting." 1>&2
  exit 1
  ;;
esac

# Determine platform name.
case `uname -sm` in
"SunOS sun4"*)
  ATHENA_HOSTTYPE=sun4
  ;;
"Linux "i?86)
  ATHENA_HOSTTYPE=linux
  ;;
esac

savepath=$PATH

# Determine operating system, appropriate path, and compiler for use
# with plain Makefiles and some third-party packages.
case `uname -s` in
SunOS)
  OS=solaris
  LD_LIBRARY_PATH=/usr/openwin/lib export LD_LIBRARY_PATH
  PATH=/usr/ccs/bin:/usr/bin:/usr/sfw/bin:/usr/openwin/bin
  if [ -d /opt/SUNWspro/bin ]; then
    sprobin=/opt/SUNWspro/bin
  else
    sprobin=/afs/athena.mit.edu/software/sunsoft/SUNWspro/bin
  fi
  export sprobin
  ;;
Linux)
  OS=linux
  LD_RUN_PATH=/usr/athena/lib export LD_RUN_PATH
  PATH=/usr/bin:/bin:/usr/X11R6/bin
  ;;
esac
CC=gcc
CXX=g++
WARN_CFLAGS="-Wall -Wstrict-prototypes -Wmissing-prototypes"
ERROR_CFLAGS=-Werror
PATH=/usr/athena/bin:$PATH
MAKE=gmake

if [ false = "$mungepath" ]; then
  PATH=$savepath
fi

if [ dist = "$operation" ]; then
  # Copy in the version file, for the few packages which need to know
  # the Athena version.
  cp $source/packs/build/version athena-version

  # Force all source files to the same timestamp, to prevent third-party
  # build systems from thinking some are out of date with respect to others.
  find . ! -type l -exec touch -t `date +%Y%m%d%H%M.%S` {} \;
fi

# Determine the Athena version and set variables for the build system.
. ./athena-version
ATHENA_MAJOR_VERSION=$major
ATHENA_MINOR_VERSION=$minor
if [ -z "$ATHENA_PATCH_VERSION" ]; then
  ATHENA_PATCH_VERSION=$patch
fi
export ATHENA_MAJOR_VERSION ATHENA_MINOR_VERSION ATHENA_PATCH_VERSION

export WARN_CFLAGS ERROR_CFLAGS CC CXX MAKE

# GConf schemas need to be installed from RPM %post scriptlets, not
# make install rules.
GCONF_DISABLE_MAKEFILE_SCHEMA_INSTALL=1
export GCONF_DISABLE_MAKEFILE_SCHEMA_INSTALL

# On Linux, we use the native pkg-config, which needs to be able to
# find our libraries.
PKG_CONFIG_PATH=/usr/athena/lib/pkgconfig
export PKG_CONFIG_PATH

if [ -r Makefile.athena ]; then
  export SRVD SOURCE COMPILER
  SRVD=$srvd
  SOURCE=$source
  COMPILER=$CC
  if [ dist = "$operation" ]; then
    export CONFIG_SITE XCONFIGDIR
    CONFIG_SITE=$source/packs/build/config.site
    XCONFIGDIR=$source/packs/build/xconfig
  fi
  $MAKE $n -f Makefile.athena "$operation"
elif [ -f configure.in -o -f configure.ac -o -f configure ]; then
  if [ -f configure.athena ]; then
    configure=configure.athena
  else
    configure=configure
  fi
  case $operation in
  dist)
    # Copy in support files and run autoconf if this is a directory using the
    # Athena build system.
    if [ -f config.do -o ! -f configure ]; then
      $maybe touch config.do
      $maybe rm -f mkinstalldirs install-sh config.guess
      $maybe rm -f config.sub aclocal.m4
      $maybe cp "$source/packs/build/autoconf/mkinstalldirs" .
      $maybe cp "$source/packs/build/autoconf/install-sh" .
      $maybe cp "$source/packs/build/autoconf/config.guess" .
      $maybe cp "$source/packs/build/autoconf/config.sub" .
      $maybe cp "$source/packs/build/aclocal.m4" .
      $maybe cat "$source/packs/build/libtool/libtool.m4" >> aclocal.m4
      $maybe cp "$source/packs/build/libtool/ltmain.sh" .
      $maybe autoconf || exit 1
    fi
    $maybe cp "$source/packs/build/config.site" config.site.athena
    ;;
  prepare)
    $maybe rm -f config.cache
    CONFIG_SITE=`pwd`/config.site.athena $maybe "./$configure"
  ;;
  clean)
    $MAKE $n clean
    ;;
  all)
    $MAKE $n all
    ;;
  check)
    $MAKE -n check >/dev/null 2>&1 && $MAKE $n check || true
    ;;
  install)
    $MAKE $n install "DESTDIR=$srvd"
    ;;
  esac
elif [ -r Imakefile ]; then
  case $operation in
  dist)
    $maybe mkdir -p config
    $maybe cp $source/packs/build/xconfig/README config
    $maybe cp $source/packs/build/xconfig/mkdirhier.sh config
    $maybe cp $source/packs/build/xconfig/rtcchack.bac config
    $maybe cp $source/packs/build/xconfig/site.def config
    $maybe cp $source/packs/build/xconfig/*.cf config
    $maybe cp $source/packs/build/xconfig/*.rules config
    $maybe cp $source/packs/build/xconfig/*.tmpl config
    ;;
  prepare)
    $maybe imake "-Iconfig" -DUseInstalled "-DTOPDIR=`pwd`" \
      "-DXCONFIGDIR=`pwd`/config"
    $maybe $MAKE Makefiles
    ;;
  clean)
    $MAKE $n clean
    ;;
  all)
    $MAKE $n includes depend all TOP=`pwd` MAKE="$MAKE TOP=`pwd`"
    ;;
  check)
    ;;
  install)
    $MAKE $n install install.man "DESTDIR=$srvd" TOP=`pwd` \
      MAKE="$MAKE TOP=`pwd`"
    ;;
  esac
elif [ -r Makefile ]; then
  case $operation in
  dist|prepare)
    ;;
  clean)
    $MAKE $n clean
    ;;
  all)
    $MAKE $n all CC="$CC"
    ;;
  check)
    $MAKE $n check
    ;;
  install)
    $MAKE $n install "DESTDIR=$srvd"
    ;;
  esac
else
  echo Nothing to do in `pwd` 1>&2
  exit 1
fi
