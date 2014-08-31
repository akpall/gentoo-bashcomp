# NOTE: this Makefile is mainly for developer use, as there isn't really
# anything to build.

distapp = gentoo-bashcomp
distver := $(shell date -u +%Y%m%d)
distpkg := $(distapp)-$(distver)

DESTDIR =
EPREFIX =

# prefer paths from pkg-config, fallback to sane defaults
completionsdir ?= $(or \
	$(shell pkg-config --variable=completionsdir bash-completion 2>/dev/null), \
	${EPREFIX}/usr/share/bash-completion/completions)
helpersdir ?= $(or \
	$(shell pkg-config --variable=helpersdir bash-completion 2>/dev/null), \
	${EPREFIX}/usr/share/bash-completion/helpers)
compatdir ?= $(or \
	$(shell pkg-config --variable=compatdir bash-completion 2>/dev/null), \
	${EPREFIX}/etc/bash_completion.d)

completions := $(wildcard completions/*)
helpers := $(wildcard helpers/*)
compats := $(wildcard compat/*)

POSTINST_SED = sed -i -e "s|@GENTOO_PORTAGE_EPREFIX@|${EPREFIX}|g" -e "s|@helpersdir@|$(helpersdir)|"

all:
	@echo Nothing to compile.

install:
	install -d "$(DESTDIR)$(completionsdir)"
	install -m0644 $(completions) "$(DESTDIR)$(completionsdir)"
	$(POSTINST_SED) $(addprefix "$(DESTDIR)$(completionsdir)"/,$(notdir $(completions)))
	install -d "$(DESTDIR)$(helpersdir)"
	install -m0644 $(helpers) "$(DESTDIR)$(helpersdir)"
	$(POSTINST_SED) $(addprefix "$(DESTDIR)$(helpersdir)"/,$(notdir $(helpers)))
	install -d "$(DESTDIR)$(compatdir)"
	install -m0644 $(compats) "$(DESTDIR)$(compatdir)"
	$(POSTINST_SED) $(addprefix "$(DESTDIR)$(compatdir)"/,$(notdir $(compats)))

tag:
	git pull
	git tag -a $(distpkg) -m "tag $(distpkg)"
	@echo
	@echo "created tag $(distpkg) - remember to push it"
	@echo

dist: tag
	git archive --prefix=$(distpkg)/ --format=tar -o $(distpkg).tar $(distpkg)
	mkdir $(distpkg)/
	git log > $(distpkg)/ChangeLog
	tar vfr $(distpkg).tar $(distpkg)/ChangeLog
	bzip2 $(distpkg).tar
	rm -rf $(distpkg)/
	@echo "success."

dist-upload: dist
	scp $(distpkg).tar.bz2 dev.gentoo.org:/space/distfiles-local/
	ssh dev.gentoo.org chmod ug+rw /space/distfiles-local/$(distpkg).tar.bz2
