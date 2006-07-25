# $Id: Makefile,v 1.20 2006-07-25 23:14:55 ghudson Exp $

SHELL=/bin/sh
PROTOTYPE=/usr/prototype_user
PROTOTMP=/usr/athena/lib/prototype_tmpuser
SYSTEM=/usr/athena/lib/init
ATHMANDIR=/usr/athena/man
ATHRETCDIR=/etc/athena
ATHLOGINDIR=${ATHRETCDIR}/login

all:
	cd os/${OS} && ${MAKE} $@
	cd gnome && ${MAKE} $@

check:
	cd os/${OS} && ${MAKE} $@
	cd gnome && ${MAKE} $@

install:
	mkdir -p ${DESTDIR}${PROTOTYPE}
	mkdir -p ${DESTDIR}${PROTOTMP}
	mkdir -p ${DESTDIR}${SYSTEM}
	mkdir -p ${DESTDIR}${ATHMANDIR}/man1
	mkdir -p ${DESTDIR}${ATHMANDIR}/man7
	mkdir -p ${DESTDIR}${ATHLOGINDIR}
	install -c -m 0755 Xsession ${DESTDIR}${ATHLOGINDIR}
	install -c -m 0644 cshrc ${DESTDIR}${SYSTEM}
	install -c -m 0644 dot.cshrc ${DESTDIR}${PROTOTYPE}/.cshrc
	install -c -m 0644 dot.cshrc ${DESTDIR}${PROTOTMP}/.cshrc
	install -c -m 0644 dot.login ${DESTDIR}${PROTOTYPE}/.login
	install -c -m 0644 dot.login ${DESTDIR}${PROTOTMP}/.login
	install -c -m 0644 dot.logout ${DESTDIR}${PROTOTYPE}/.logout
	install -c -m 0644 dot.mh_profile ${DESTDIR}${PROTOTYPE}/.mh_profile
	install -c -m 0644 dot.bash_login ${DESTDIR}${PROTOTYPE}/.bash_login
	install -c -m 0644 dot.bash_login ${DESTDIR}${PROTOTMP}/.bash_login
	install -c -m 0644 dot.bashrc ${DESTDIR}${PROTOTYPE}/.bashrc
	install -c -m 0644 dot.bashrc ${DESTDIR}${PROTOTMP}/.bashrc
	install -c -m 0644 env_remove ${DESTDIR}${SYSTEM}
	install -c -m 0644 env_setup ${DESTDIR}${SYSTEM}
	install -c -m 0755 gnome-stuff-1-to-2 ${DESTDIR}${SYSTEM}
	install -c -m 0755 gnome-panel-1-to-2 ${DESTDIR}${SYSTEM}
	install -c -m 0444 lockers.7 ${DESTDIR}${ATHMANDIR}/man7
	install -c -m 0644 login ${DESTDIR}${SYSTEM}
	install -c -m 0755 mksessiondir.sh ${DESTDIR}${SYSTEM}/mksessiondir
	install -c -m 0755 quotawarn.sh ${DESTDIR}${SYSTEM}/quotawarn
	install -c -m 0644 bashrc ${DESTDIR}${SYSTEM}
	install -c -m 0644 bash_login ${DESTDIR}${SYSTEM}
	install -c -m 0444 renew.1 ${DESTDIR}${ATHMANDIR}/man1
	install -c -m 0555 revert-to-sawfish.sh \
	  ${DESTDIR}${SYSTEM}/revert-to-sawfish
	install -c -m 0644 temp.README ${DESTDIR}${PROTOTMP}/README
	install -c -m 0644 temp.mh_profile ${DESTDIR}${PROTOTMP}/.mh_profile
	install -c -m 0644 welcome ${DESTDIR}${PROTOTYPE}
	install -c -m 0644 welcome ${DESTDIR}${PROTOTMP}
	install -c -m 0755 xkill-mozilla.sh ${DESTDIR}${SYSTEM}/xkill-mozilla
	install -c -m 0755 xsession ${DESTDIR}${SYSTEM}
	cd os/${OS} && ${MAKE} $@
	cd gnome && ${MAKE} $@

clean:
	cd os/${OS} && ${MAKE} $@
	cd gnome && ${MAKE} $@

distclean:
	cd os/${OS} && ${MAKE} $@
	cd gnome && ${MAKE} $@

