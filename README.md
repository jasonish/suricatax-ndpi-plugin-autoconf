# Suricata nDPI Plugin

A Suricata plugin that uses [nDPI](https://github.com/ntop/nDPI) to add:

- the `ndpi-protocol` and `ndpi-risk` rule keywords
- an `ndpi` object with nDPI metadata on EVE records that have a flow

This is the `plugins/ndpi` plugin from the Suricata source tree, built
as a standalone autoconf project against the headers of an installed
Suricata.

See [docs/ndpi.rst](docs/ndpi.rst) for keyword documentation.

## Supported Versions

| Branch       | Suricata                          | nDPI                        |
|--------------|-----------------------------------|-----------------------------|
| `main`       | 9.0 development (Suricata `main`) | 4.14 and newer 4.x releases |
| `main-8.0.x` | 8.0.x (Suricata `main-8.0.x`)     | 4.14 and newer 4.x releases |

This branch is for Suricata 8.0. For Suricata 9.0, use the `main` branch.
`configure` checks the Suricata version.

nDPI 5.0 and newer are not supported. They changed the APIs used for
enabling protocols, giving up on detection, and (in 6.0) initializing the
detection module. `configure` rejects them.

The plugin must be built against the headers of the Suricata version
that will load it. Suricata refuses to load a plugin built for a different
major/minor version.

## Requirements

- A C compiler, autoconf, automake, libtool, and pkg-config
- Suricata 8.0.x, built and installed with its headers:

  ```
  ./configure --prefix=/opt/suricata
  make
  make install install-headers
  ```

  Optionally also run `make install-library` to get `libsuricata-config`.

- nDPI 4.14 or newer 4.x, either installed (with `libndpi.pc`) or as a
  built source tree:

  ```
  git clone -b 4.14 https://github.com/ntop/nDPI
  cd nDPI
  ./autogen.sh --with-only-libndpi
  make
  ```

## Building

```
./autogen.sh
./configure --with-suricata=/opt/suricata --with-ndpi=/path/to/nDPI
make
make install
```

By default the plugin is installed as `PREFIX/lib/suricata/ndpi.so`.
`PREFIX` defaults to the `--with-suricata` prefix. Without
`--with-suricata`, it defaults to the prefix of `libsuricata-config`
found in `PATH`.

### Locating Suricata

Use one of these options:

- `--with-suricata=PREFIX`: a Suricata installation prefix with installed
  headers (`PREFIX/include/suricata`).
- `--with-suricata-source=DIR`: a configured and built Suricata source
  tree. This is useful for development.
- `SURICATA_CFLAGS=...`: explicit preprocessor flags.
- `--with-suricata-config=PATH`: the path to `libsuricata-config`.
  Without any option, `configure` looks for `libsuricata-config` in
  `PATH`.

### Locating nDPI

- `--with-ndpi=DIR`: `DIR` is either an nDPI source tree (its static
  `src/lib/libndpi.a` is linked into the plugin), or an nDPI installation
  prefix.
- Otherwise, `pkg-config libndpi` is used. Set `PKG_CONFIG_PATH` if nDPI
  is installed in a non-standard location. `NDPI_CFLAGS` and `NDPI_LIBS`
  override pkg-config.
- `--enable-static-ndpi` links the static `libndpi.a` from an installed
  nDPI, so the plugin does not need `libndpi.so` at runtime.

### Other Options

- `--with-plugindir=DIR`: install directory for `ndpi.so`.
- `--enable-warnings`: build with `-Wall -Wextra -Werror`.

## Usage

Load the plugin in `suricata.yaml`:

```yaml
plugins:
  - /opt/suricata/lib/suricata/ndpi.so
```

Rules using the keywords should require them, so they are skipped when
the plugin is not loaded:

```
alert tcp any any -> any any (msg:"Binary application transfer over HTTP"; \
    requires: keyword ndpi-protocol, keyword ndpi-risk; \
    ndpi-protocol:HTTP; ndpi-risk:NDPI_BINARY_APPLICATION_TRANSFER; sid:1;)
```

## Testing

`tests/smoke-test.sh` loads the plugin into Suricata, runs nDPI's
`tests/cfgs/default/pcap/http-basic-auth.pcap` with `ndpi-protocol` and
`ndpi-risk` rules, and checks for alerts and `ndpi` EVE metadata:

```
tests/smoke-test.sh /opt/suricata/bin/suricata .libs/ndpi.so \
    /path/to/nDPI/tests/cfgs/default/pcap/http-basic-auth.pcap
```

## License

The plugin is licensed under LGPL-3.0-or-later, the same license as
nDPI 4.x; see [LICENSE](LICENSE).
