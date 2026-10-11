ACLOCAL_AMFLAGS = -I m4

plugin_LTLIBRARIES = ndpi.la

ndpi_la_SOURCES = src/ndpi.c
# Suricata's logging requires __SCFILENAME__ (the log module name).
ndpi_la_CPPFLAGS = $(SURICATA_CFLAGS) $(NDPI_CFLAGS) '-D__SCFILENAME__="ndpi"'
ndpi_la_CFLAGS = $(WARN_CFLAGS)
ndpi_la_LDFLAGS = -module -avoid-version -shared
ndpi_la_LIBADD = $(NDPI_LIBS)

EXTRA_DIST = autogen.sh README.md LICENSE docs/ndpi.rst tests/smoke-test.sh

# Only the shared object is useful to Suricata.
install-data-hook:
	cd $(DESTDIR)$(plugindir) && $(RM) $(plugin_LTLIBRARIES)

# As the .la file was removed, libtool can't uninstall the plugin.
uninstall-hook:
	$(RM) $(DESTDIR)$(plugindir)/ndpi.so
