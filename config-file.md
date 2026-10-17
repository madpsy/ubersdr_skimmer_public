# The config file

Everything the skimmer can be told on its command line can be put in one
JSON file instead. The file is a different spelling of the same options, not
a second set of settings: the skimmer turns the file back into the command
line it stands for and reads that, so every option, every default and every
check is exactly the command line's. Whatever `--help` says of an option is
true of its key here.

## Contents

- [Starting with a file](#starting-with-a-file)
- [Where the file lives](#where-the-file-lives)
- [A first file](#a-first-file)
- [The rules of the file](#the-rules-of-the-file)
- [The structure](#the-structure)
- [Every key](#every-key)
- [Examples](#examples)
- [Errors](#errors)
- [Making a file from a command line](#making-a-file-from-a-command-line)
- [Docker](#docker)
- [The Config tab](#the-config-tab)
- [Setting it up from the web page](#setting-it-up-from-the-web-page)
- [Versions of the file](#versions-of-the-file)

## Starting with a file

| You run | It does |
|---|---|
| `ubersdr-skimmer` (no arguments) | reads the file at the [default location](#where-the-file-lives). With no file there it has no source of IQ: it runs the web page alone, on port 9101 (`http://localhost:9101/`), with the [setup wizard](#setting-it-up-from-the-web-page), which writes the file and starts the skimmer from it. Ctrl-C (or SIGTERM) stops it |
| `ubersdr-skimmer --config PATH` | reads that file. A file that is missing or wrong is an error (exit 2), never a quiet fall back to the defaults |
| `ubersdr-skimmer --config PATH --anything` | an error: `--config takes no other options: put them in the file`. A file and options are never mixed, so what runs is always what one of them says |
| `ubersdr-skimmer --url ... (any options)` | the command line, as always. The default file is **not** read |
| `ubersdr-skimmer --help`, `--version`, `--hpsdr-discover`, `--hash-password` | as always: these are commands, not settings, and are never in a file |
| `ubersdr-skimmer --write-config [PATH] (options)` | checks the options and writes them as a file (default: the default location), then exits. See [Making a file from a command line](#making-a-file-from-a-command-line) |

## Where the file lives

Where each system keeps an application's settings: kept across restarts,
updates and reinstalls, and never in the cache (which `--clear-cache`
empties).

| System | Default file |
|---|---|
| Linux | `$XDG_CONFIG_HOME/ubersdr-skimmer/config.json`, else `~/.config/ubersdr-skimmer/config.json` |
| Windows | `%APPDATA%\ubersdr-skimmer\config.json` (`C:\Users\<you>\AppData\Roaming\ubersdr-skimmer\config.json`) |
| Docker image | `/data/config/ubersdr-skimmer/config.json`, a volume (see [Docker](#docker)) |

The downloaded lists, FFTW wisdom and RBN state stay where they are
(`~/.cache/ubersdr-skimmer`, `%LOCALAPPDATA%\ubersdr-skimmer`). With neither
`$HOME` nor `$XDG_CONFIG_HOME` (Linux), or no `%APPDATA%` (a Windows service
account), there is no default file: `--config PATH` still works. The Config
tab shows the default path whichever way the skimmer was started.

The file holds passwords (the receiver's, QRZ.com's, the Radio tab's): the
skimmer warns at start when others can read it (Linux: any group or other
permission bit; `chmod 600` it).

## A first file

The skimmer on an UberSDR receiver, skimming four bands, reporting to RBN:

```json
{
  "version": 1,
  "station": { "call": "MM9PSY", "locator": "IO86ha" },
  "source": {
    "ubersdr": { "url": "http://ubersdr:8080", "mode": "iq192", "bands": ["80", "40", "30", "20"] }
  },
  "reporting": { "rbn": { "enabled": true } }
}
```

That is this command line, word for word:

```
ubersdr-skimmer --call MM9PSY --locator IO86ha --url http://ubersdr:8080 --mode iq192 --bands 80,40,30,20 --rbn
```

Everything not in the file is the option's default, as when it is left off
the command line.

## The rules of the file

1. **JSON, UTF-8.** One object. JSON has no comments: any key starting with
   `_` is ignored wherever it is (`"_comment": "why 40 m is off"`).
2. **`version` is required**, and is `1` (see [Versions](#versions-of-the-file)).
3. **Every other key must be known.** A key the skimmer does not know is an
   error, never ignored: a mistyped key must not silently drop a setting.
4. **A key left out, or `null`, is the default**, as an option left off the
   command line. `null` lets a file list every key (as `--write-config
   --all` writes it) without changing anything.
5. **Types are JSON's own.** A switch is `true`/`false`, a number a number, a
   text a string. A number given as a string (`"7300"`) is an error, not
   converted.
6. **Switches say what is on.** The command line's `--no-...` options are the
   same keys set `false`: `--no-rtty` is `"rtty": { "enabled": false }`,
   `--no-gap-fill` is `"gap_fill": false`.
7. **Band lists** are an array of the names `--bands` takes (`["40", "20"]`,
   with stream centres in kHz as strings, `"14100"`), or one of the words
   the option takes as a string: `"all"`, `"none"`, `"skimmed"` (`--ft8`,
   `--js8`, `--wspr` given with no list: the skimmer's own bands).
8. **Paths** are as the program sees them: relative ones from where it was
   started, as on the command line. On Windows, write `\\` or `/`.
9. **The structure says where a setting applies.** A radio's own settings sit
   in its object; a setting for every radio in `radio_defaults`. On the
   command line the same thing is said by where an option stands (before any
   `--hpsdr`, or after one), which is easy to get wrong; in the file it
   cannot be.
10. **Checks are the command line's.** Ranges, combinations ("give one
    source", "--rbn needs live input", "no band on two radios") are checked
    by the same code, and the error names the file's key (see [Errors](#errors)).

## The structure

```jsonc
{
  "version": 1,
  "station":        { ... },   // who: call, name, QTH, locator
  "source":         { ... },   // exactly one of: "ubersdr", "input", "radios"
  "radio_defaults": { ... },   // with "radios": what every radio takes unless it says otherwise
  "capture":        { ... },   // recording the IQ, stopping after a time
  "streams":        { ... },   // how streams are placed
  "cw":             { ... },   // CW skimming and its decoder
  "spots":          { ... },   // which spots go out, and how often
  "rtty":           { ... },
  "jtty":           { ... },
  "ft":             { "ft8": { ... }, "ft4": { ... }, "ft2": { ... } },
  "js8":            { ... },
  "wspr":           { ... },   // WSPR and FST4W
  "programs":       { ... },   // the WSJT-X programs, when they decode instead
  "reporting":      { "rbn": { ... }, "pskreporter": { ... }, "wsprnet": { ... }, "wsjtx_out": { ... } },
  "qrz":            { ... },
  "telnet":         { ... },
  "web":            { ... },
  "admin":          { ... },   // the web page's admin: its password, who may
  "output":         { ... },   // stdout: JSON, tracks, --compare
  "data":           { ... }    // cty.dat, MASTER.SCP and the other lists
}
```

Sections a run does not need are left out. Only `version` and `source` are
needed for a live run (and `source` only because a live run needs one).

### The source

`source` holds exactly one key: where the IQ comes from.

- `"ubersdr"`: an UberSDR receiver (`--url`).
- `"input"`: a file of raw IQ (`--input`), offline.
- `"radios"`: an array of radios, each one an HPSDR radio, a ka9q-radio
  radiod, or (Windows) a radio through its Skimmer Server driver. Each is an
  object with `"kind"` saying which, and only the keys that kind takes.
  The kinds are not mixed in one run, as on the command line.

## Every key

Each table gives the key, its type, the option it stands for, and what it
does in a few words. `--help` has the whole of each. Types: **bool**,
**int**, **number**, **string**, **bands** (rule 7), **enum** (one of the
words listed), **path** (a string, rule 8).

### `version`

| Key | Type | Option | |
|---|---|---|---|
| `version` | int | none | the file's version: `1` |

### `station`

| Key | Type | Option | |
|---|---|---|---|
| `call` | string | `--call` | your callsign; spots go out as CALL-# (default: the receiver's skimmer call) |
| `name` | string | `--name` | the operator, for the telnet sign-on and RBN |
| `qth` | string | `--qth` | the location |
| `locator` | string | `--locator` | 6-character locator |

### `source.ubersdr`

| Key | Type | Option | |
|---|---|---|---|
| `url` | string | `--url` | the receiver, `http://host:8080` (required) |
| `password` | string | `--password` | its password, if it has one |
| `mode` | enum `iq48` `iq96` `iq192` `iq384` | `--mode` | the IQ streams' width (default iq96) |
| `margin_db` | int | `--margin` | reduced-depth IQ, 10-60 dB under the noise; 0 lossless (default 15) |
| `insecure` | bool | `--insecure` | do not check its TLS certificate |
| `gap_fill` | bool | `--no-gap-fill` when `false` | silence where its packets went missing (default true) |
| `bands` | bands | `--bands` | the bands skimmed, `"all"` or a list |
| `freq_hz` | number | `--freq` | one stream at this centre instead of `bands` |
| `six_metres` | enum `cw` `whole` `off` | `--six-metres` | 6 m in `bands` (default whole) |
| `freq_calibration` | number or string | `--freq-calibration` | every frequency times this: `1.000000468` or `"+0.5ppm"` |
| `auto_calibrate` | bool | `--auto-calibrate` | with RBN, calibrate by SM7IUN's daily skew as each list comes in |
| `radio_tab` | bool | `--no-radio` when `false` | a Radio tab on its own session (default true) |
| `radio_password` | string | `--radio-password` | only a page that gives this tunes the Radio tab |

### `source.input`

| Key | Type | Option | |
|---|---|---|---|
| `file` | path | `--input` | raw interleaved IQ; `"-"` for stdin (required) |
| `format` | enum `cf32` `cs16` | `--format` | (default cf32) |
| `rate_hz` | number | `--rate` | its sample rate (required) |
| `freq_hz` | number | `--freq` | its centre frequency (required) |
| `freq_calibration` | number or string | `--freq-calibration` | every frequency times this, as a receiver's |

### `source.radios[]`

Every radio, of any kind:

| Key | Type | Option | |
|---|---|---|---|
| `kind` | enum `hpsdr` `ka9q` `driver` | `--hpsdr`, `--ka9q`, `--driver` | which kind of radio (required) |
| `bands` | bands | `--bands` after the radio | its bands (no band on two radios) |
| `freq_hz` | number | `--freq` after the radio | one receiver at this centre instead |
| `mode` | enum `iq48` `iq96` `iq192` `iq384` | `--mode` after the radio | its receivers' width (a driver: no iq384) |
| `freq_calibration` | number or string | `--freq-calibration` after the radio | its own calibration |
| `auto_calibrate` | bool | `--auto-calibrate` after the radio | with RBN, this radio's calibration by SM7IUN's daily skew (one radio only) |
| `six_metres` | enum `cw` `whole` `off` | `--six-metres` after the radio | its own 6 m |

`kind: "hpsdr"` adds:

| Key | Type | Option | |
|---|---|---|---|
| `address` | string | `--hpsdr` | its IP, name or MAC (required) |
| `protocol` | int 1 or 2 | `--hpsdr-protocol` | (default: as it answers) |
| `attenuator_db` | int 0-31 | `--hpsdr-att` | its step attenuator (default: HermesIntf's AGC) |
| `low_streams` | bool | `--low-streams` | streams placed as an UberSDR's, 2 kHz below each band |
| `radio_tab` | bool | `--no-radio` when `false` | a Radio tab on its spare receiver (default true) |
| `radio_password` | string | `--radio-password` | its own Radio tab password |
| `cwsl` | bool | `--cwsl` | Windows: share its IQ in CWSL memories |
| `cwsl_blocks` | int 0-1024 | `--cwsl-blocks` | Windows: its own CWSL memory size |
| `cwsl_suffix` | string | `--cwsl-suffix` | Windows: its CWSL names' suffix |

`kind: "ka9q"` adds:

| Key | Type | Option | |
|---|---|---|---|
| `status` | string | `--ka9q` | radiod's status group, `hf-status.local` (required) |
| `iface` | string | `--ka9q-iface` | the interface it is reached on |
| `data` | string | `--ka9q-data` | the channels' data group |
| `encoding` | enum `f32` `s16` | `--ka9q-encoding` | (default f32) |
| `agc.on` | bool | `--ka9q-agc on\|off` | radiod's AGC on each channel (default true) |
| `agc.gain_db` | number -100-100 | `--ka9q-gain` | a fixed gain instead; needs `agc.on` false or left out |
| `agc.hang_s` | number 0-60 | `--ka9q-agc-hang` | |
| `agc.recovery_db_s` | number 0-1000 | `--ka9q-agc-recovery` | |
| `agc.headroom_db` | number 0-100 | `--ka9q-headroom` | |
| `agc.threshold_db` | number 0-100 | `--ka9q-agc-threshold` | |
| `radio_tab` | bool | `--no-radio` when `false` | a Radio tab on a channel of its own |
| `radio_password` | string | `--radio-password` | |

`kind: "driver"` (Windows only) adds:

| Key | Type | Option | |
|---|---|---|---|
| `dll` | path | `--driver` | its Skimmer Server driver, `HermesIntf.dll` (required) |
| `low_streams` | bool | `--low-streams` | |
| `cwsl_blocks` | int 0-1024 | `--cwsl-blocks` after it | |
| `cwsl_suffix` | string | `--cwsl-suffix` | |

### `radio_defaults`

Only with `source.radios`: what every radio takes unless its own object says
otherwise (the command line's "before any radio").

| Key | Type | Option | |
|---|---|---|---|
| `mode` | enum | `--mode` before any radio | |
| `freq_calibration` | number or string | `--freq-calibration` before any radio | |
| `six_metres` | enum `cw` `whole` `off` | `--six-metres` before any radio | |
| `radio_tab` | bool | `--no-radio` before any radio when `false` | |
| `radio_password` | string | `--radio-password` before any radio | |
| `cwsl_blocks` | int 0-1024 | `--cwsl-blocks` before any radio | Windows |

### `capture`

| Key | Type | Option | |
|---|---|---|---|
| `record` | path | `--record` | also write the live IQ to this file, cf32 |
| `duration_s` | number | `--duration` | stop after this many seconds of IQ |

### `streams`

| Key | Type | Option | |
|---|---|---|---|
| `centre` | bool | `--centre-streams` | centre each band's streams on what they skim |
| `dc_guard` | bool | `--dc-guard` | blank the window centre (hardware with a DC spike) |

### `cw`

| Key | Type | Option | |
|---|---|---|---|
| `enabled` | bool | `--no-cw` when `false` | skim CW (default true) |
| `all_bands` | bool | `--all-bands` | skim the whole window, CW sub-band or not |
| `skim_digital` | bool | `--skim-digital` | skim the digital modes' windows too |
| `max_tracks` | int 128-2048 | `--max-tracks` | stations each stream reads at once |
| `noise_filter` | bool | `--no-noise-filter` when `false` | (default true) |
| `static_filter` | enum `full` `starts` `off` | `--static-filter` | (default full) |
| `preroll` | bool | `--no-preroll` when `false` | (default true) |
| `decoder.debounce` | number | `--debounce` | dits a key change must last; -1 follows the signal (default) |
| `decoder.narrow_hz` | number | `--narrow` | the second reading's filter width; 0 follows the speed (default) |
| `decoder.single` | bool | `--single` | read from the transform's bin alone |
| `decoder.beam` | bool | `--no-beam` when `false` | (default true) |

### `spots`

| Key | Type | Option | |
|---|---|---|---|
| `validation` | enum `relaxed` `normal` `strict` | `--validation` | (default normal) |
| `de` | bool | `--no-de` when `false` | DE spots (default true) |
| `heard` | bool | `--no-heard` when `false` | blank-type spots of calls heard (default true) |
| `squelch_db` | int | `--squelch` | minimum SNR to spot (default 0) |
| `respot_min` | number | `--respot` | spot a station again only after this (default 10) |
| `hold_min` | number | `--spot-hold` | never the same call, mode and kHz within this, whatever spotted it; 0 none (default 5) |

### `rtty`

| Key | Type | Option | |
|---|---|---|---|
| `enabled` | bool | `--no-rtty` when `false` | decode and spot RTTY (default true) |
| `filter` | bool | `--no-rtty-filter` when `false` | keep CW tracks off FSK (default true; RTTY needs it) |
| `max_channels` | int 1-1000 | `--max-rtty` | RTTY signals a band decodes at once (default 100) |
| `tens_hz` | bool | `--tens-hz` | spot frequencies to 10 Hz, as RTTY Skimmer Server's TensHz (default false: 100 Hz) |
| `contests` | path | `--rtty-contests` | the contests' CQ words and reports |

### `jtty`

| Key | Type | Option | |
|---|---|---|---|
| `enabled` | bool | `--no-jtty` when `false` | (default true) |
| `bands` | bands | `--jtty` | its dials on these bands only (default all) |

### `ft.ft8`, `ft.ft4`, `ft.ft2`

The same keys in each.

| Key | Type | Option | |
|---|---|---|---|
| `bands` | bands | `--ft8`, `--ft4`, `--ft2` | the bands decoded; `"skimmed"` is the option with no list (default none) |
| `depth` | enum `fast` `normal` `deep` | `--ft8-depth`, `--ft4-depth`, `--ft2-depth` | (default normal) |
| `threads` | int 1-64 | `--ft8-threads`, `--ft4-threads`, `--ft2-threads` | decodes at once (default half the cores, 2-4) |
| `program` | bool | `--ft8-jt9`, `--ft4-jt9`, `--ft2-jt9` | decode with `programs.jt9`, not built in |

### `js8`

| Key | Type | Option | |
|---|---|---|---|
| `bands` | bands | `--js8` | the bands decoded; `"skimmed"` the option with no list (default none) |

### `wspr`

WSPR and FST4W. `bands` takes three shapes:

- a band list, or a word (rule 7: `"all"`, `"none"`, `"skimmed"`): each band
  decodes `default_modes`, unless `band_modes` gives it its own;
- an object, band to its own modes: the bands decoded are its keys, and a
  band given `null` takes `default_modes`.

```jsonc
"bands": ["40", "20"]                                    // the default modes on each
"bands": { "20": ["WSPR"], "80": ["FST4W-300"] }         // each band its own
"bands": { "20": null, "80": ["FST4W-300"] }             // 20 m the default modes
"bands": "all", "band_modes": { "2200": ["FST4W-900"] }  // every band; 2200 m its own
```

| Key | Type | Option | |
|---|---|---|---|
| `bands` | bands, or object band → modes | `--wspr`, and `--wspr-modes`' band lists | the bands decoded (default none) |
| `default_modes` | array of modes, or `"all"` | `--wspr-modes`' list for every band | (default WSPR, FST4W-120, FST4W-300; 2200 m and 630 m add FST4W-900 and -1800) |
| `band_modes` | object band → modes | `--wspr-modes`' band lists | a band's own modes, when `bands` is a list or a word; not a band that `bands` (an object) gives already |
| `depth` | enum `fast` `normal` `deep` | `--wspr-depth` | (default deep) |
| `threads` | int 1-64 | `--wspr-threads` | |
| `noise_cal_db` | number, or object band → number | `--wspr-noise-cal` | dBFS/Hz to dBm/Hz: one for every band, or band by band (`"default"` for the rest) |
| `wsprd_args` | string | `--wsprd-args` | wsprd's flags instead of `depth`'s |
| `fst4w.threads` | int 1-64 | `--fst4w-threads` | |
| `fst4w.spread` | enum `fast` `exact` `off` | `--fst4w-spread` | (default fast) |
| `fst4w.program` | bool | `--fst4w-jt9` | decode FST4W with `programs.jt9` |

Modes are named as the Spots tab and wsprnet name them: `WSPR`, `WSPR-15`,
`FST4W-120`, `FST4W-300`, `FST4W-900`, `FST4W-1800`. The command line's short
names (`W2`, `W15`, `F2`, `F5`, `F15`, `F30`) are taken too. Band names are
`--wspr`'s (`80eu` and `60eu` are the second dials; they take `80`'s and
`60`'s modes unless named).

### `programs`

| Key | Type | Option | |
|---|---|---|---|
| `jt9` | path | `--jt9` | the jt9 program, for the `program: true` decoders (default /usr/bin/jt9) |
| `wsprd` | path | `--wsprd` | decode WSPR with this wsprd program instead of the built-in one |

### `reporting.rbn`

| Key | Type | Option | |
|---|---|---|---|
| `enabled` | bool | `--rbn` | report spots to the Reverse Beacon Network |
| `dry_run` | bool | `--rbn-dry-run` | sign on and judge spots, upload none |
| `call` | string | `--rbn-call` | the call RBN knows this skimmer by |
| `patt3ch` | bool | `--no-patt3ch` when `false` | only calls of RBN's shapes (default true) |
| `bad_calls` | bool or path | `--rbn-bad-calls [FILE]` | `true`: BadCalls.txt; a path: that file. Checked line by line and read again when it changes, as `data`'s files; one not there yet holds no calls until it is |
| `wsjtx` | array of `{ "port": int, "calibration": number }` | `--wsjtx PORT[:CAL]`, repeated | WSJT-X UDP sources of FT8/FT4 CQs |
| `local_telnet_port` | int | `--agg-telnet` | the reporter's local-user telnet, as Aggregator's 7550 |

### `reporting.pskreporter`

| Key | Type | Option | |
|---|---|---|---|
| `enabled` | bool | `--pskreporter` | |
| `call` | string | `--psk-call` | |
| `antenna` | string | `--pskreporter-antenna` | |
| `server` | string | `--pskreporter-server` | `host:port` |

### `reporting.wsprnet`

| Key | Type | Option | |
|---|---|---|---|
| `enabled` | bool | `--wsprnet` | upload WSPR and FST4W spots |
| `call` | string | `--wsprnet-call` | |
| `server` | string | `--wsprnet-server` | |

### `reporting.wsjtx_out`

| Key | Type | Option | |
|---|---|---|---|
| `to` | string | `--wsjtx-out` | `host:port` (or `[ipv6]:port`, a multicast group) |
| `id` | string | `--wsjtx-out-id` | |
| `ttl` | int 1-255 | `--wsjtx-out-ttl` | |

### `qrz`

| Key | Type | Option | |
|---|---|---|---|
| `enabled` | bool | `--no-qrz` when `false` | any lookups at all, the UberSDR's too (default true) |
| `user` | string | `--qrz-user` | QRZ.com XML login |
| `password` | string | `--qrz-password` | |
| `validate` | bool | `--qrz-validate` | spot only calls QRZ.com knows |

### `telnet`

| Key | Type | Option | |
|---|---|---|---|
| `port` | int | `--telnet` | CW's port; RTTY's, JTTY's and every mode's are the next three; 0 none (default 7300 live) |

### `web`

| Key | Type | Option | |
|---|---|---|---|
| `port` | int | `--web` | the web page; 0 none (default 9101 live) |
| `root` | path | `--web-root` | serve a built `web/dist` instead of the one built in |

### `admin`

The web page's admin: the first-time setup's wizard sets the password; with
one, a run from a config file can be edited on the Config tab, and any run
restarted.

| Key | Type | Option | |
|---|---|---|---|
| `password_hash` | string | `--admin-password-hash` | the admin password's hash, as `ubersdr-skimmer --hash-password` prints it (`pbkdf2-sha256$...`); none: no admin |
| `allow` | list of strings | `--admin-allow` | addresses and CIDR ranges (IPv4, IPv6) admin is allowed from, `["192.168.1.0/24", "10.8.0.5"]`; empty or left out: any address, with the password. Behind UberSDR's proxy, the address it names (`X-Real-IP`) |

### `output`

What goes to stdout.

| Key | Type | Option | |
|---|---|---|---|
| `json` | bool | `--json` | spots as JSON lines |
| `tracks` | bool | `--tracks` | every station's text as it changes, instead of spots |
| `compare` | bool | `--compare` | hold each spot until RBN has had time to hear it, then print what RBN made of it (from telnet.reversebeacon.net:7000) |

### `data`

| Key | Type | Option | |
|---|---|---|---|
| `fetch` | bool | `--no-fetch` when `false` | fetch the lists live (default true) |
| `cty` | path | `--cty` | cty.dat |
| `scp` | path | `--scp` | MASTER.SCP |
| `calls` | path | `--calls` | the calls heard on the air, `CALL<tab>N` |
| `bcn` | path | `--bcn` | RBN's beacon list, bcn.csv: yours, used always and never fetched over |
| `patt3ch` | path | `--patt3ch` | RBN's call shapes, patt3ch.lst: yours, used always and never fetched over |

Each file named here (and `rtty.contests`, `reporting.rbn.bad_calls`) is
checked line by line before the start (one that does not read stops it,
and the Config tab's check refuses it, saying which line) and read again
whenever it changes on disk; a change that does not read keeps the copy in
use. The README's "Your own reference files" has the rules.
| `clear_cache` | bool | `--clear-cache` | empty the cache first, **every start** while it is set: for one start, use the command line |

## Examples

### WSPR on 40 m and 20 m, FST4W on 40 m and 80 m

```json
{
  "version": 1,
  "station": { "call": "MM9PSY", "locator": "IO86ha" },
  "source": { "ubersdr": { "url": "http://ubersdr:8080", "bands": ["80", "40", "20"] } },
  "wspr": {
    "bands": {
      "20": ["WSPR"],
      "40": ["WSPR", "FST4W-120", "FST4W-300", "FST4W-900", "FST4W-1800"],
      "80": ["FST4W-120", "FST4W-300", "FST4W-900", "FST4W-1800"]
    }
  },
  "reporting": { "wsprnet": { "enabled": true } }
}
```

is `--wspr 20,40,80 --wspr-modes "20:W2 40:W2,F2,F5,F15,F30 80:F2,F5,F15,F30"`.

### The UberSDR addon, everything on

```json
{
  "version": 1,
  "source": {
    "ubersdr": {
      "url": "http://ubersdr:8080",
      "mode": "iq192",
      "bands": ["2200", "630", "160", "80", "60", "40", "30", "20", "17", "15", "12", "10", "6"]
    }
  },
  "ft": {
    "ft8": { "bands": "all", "depth": "deep", "threads": 2 },
    "ft4": { "bands": "all", "depth": "deep", "threads": 2 },
    "ft2": { "bands": "all", "depth": "deep", "threads": 2 }
  },
  "js8": { "bands": "all" },
  "wspr": { "bands": ["2200", "630", "160", "80", "60", "40", "30", "20", "17", "15", "12", "10", "6"],
            "default_modes": "all", "threads": 2, "fst4w": { "threads": 2 } },
  "reporting": {
    "rbn": { "enabled": true },
    "pskreporter": { "enabled": true },
    "wsprnet": { "enabled": true }
  },
  "telnet": { "port": 7300 },
  "web": { "port": 6101 },
  "qrz": { "user": "MM3NDH", "password": "..." }
}
```

### Two HPSDR radios and their defaults

```json
{
  "version": 1,
  "station": { "call": "MM9PSY" },
  "radio_defaults": { "mode": "iq192", "freq_calibration": "+0.5ppm" },
  "source": {
    "radios": [
      { "kind": "hpsdr", "address": "192.168.9.67", "bands": ["160", "80", "40"] },
      { "kind": "hpsdr", "address": "192.168.9.68", "bands": ["30", "20", "17", "15"],
        "attenuator_db": 10, "freq_calibration": 1.0000012 }
    ]
  }
}
```

is `--mode iq192 --freq-calibration +0.5ppm --hpsdr 192.168.9.67 --bands 160,80,40
--hpsdr 192.168.9.68 --bands 30,20,17,15 --hpsdr-att 10 --freq-calibration 1.0000012`:
the second radio's own calibration, the first the default.

### A radiod with a fixed gain

```json
{
  "version": 1,
  "source": {
    "radios": [
      { "kind": "ka9q", "status": "hf-status.local", "bands": ["40", "20"],
        "agc": { "on": false, "gain_db": 20 } }
    ]
  }
}
```

### A recording, offline

```json
{
  "version": 1,
  "source": { "input": { "file": "recordings/20m.cf32", "rate_hz": 192000, "freq_hz": 14100000 } },
  "output": { "json": true }
}
```

## Errors

Every error names the file, the key, the option it stands for and what is
wrong, and the skimmer exits 2 without starting:

```
config.json: source.radios[1].attenuator_db (--hpsdr-att): 0-31 dB
config.json: cw.max_track: no such key (did you mean max_tracks?)
config.json: telnet.port: a number, not a string
config.json: source: one of ubersdr, input or radios, not two
config.json: source.radios[0].agc.gain_db: a ka9q radio's key, not an hpsdr radio's
config.json: line 12, column 5: expected ',' or '}'
```

Checks of the whole (one source; RBN, PSK Reporter and the FT decoders need
live input; a band on two radios) are the command line's, worded as the
command line words them, with the key that set the option.

## Making a file from a command line

```
ubersdr-skimmer --write-config [PATH] --url http://ubersdr:8080 --bands all --rbn ...
```

checks the options as a run would, writes them as a file and exits (no
PATH: the default location). It writes only what was given; with `--all`
every key, the ones not given `null`. It never overwrites a file unless
`--force` is given too (`--all` and `--force` come after PATH, before the
options; on Linux the file is made readable by its owner alone). A running
skimmer's settings, however it was
started, are also on its Config tab (`/api/config.json`).

## Docker

The image keeps taking its settings from the environment (`docker-compose.yml`'s
`environment:`, made into options by the entrypoint). To use a file instead:

```yaml
    environment:
      CONFIG: "/data/config/ubersdr-skimmer/config.json"
    volumes:
      - ./cache:/data/cache
      - ./config:/data/config
```

With `CONFIG` set, the entrypoint runs `--config "$CONFIG"` and every other
setting variable is ignored (it says so if any are set). The file is then
`./config/ubersdr-skimmer/config.json` beside the compose file, kept across
updates as the cache is.

## The Config tab

- It shows every setting the file (or the command line) can give: each key
  of this reference is a row, with the value the run took, given or the
  default. Rows of a feature that is off are left out (FT8's depth while FT8
  is off); a test keeps the tab and this reference in step.
- Its first rows say where the settings came from (the command line, or the
  file) and where the default file is; above them, Edit, Restart or why not
  (see [Setting it up from the web page](#setting-it-up-from-the-web-page)).
- Each row shows the file's key beside the option and the environment
  variable (`reporting.rbn.call` beside `--rbn-call` and `RBN_CALL`).
- **Download these settings as config.json**, at the foot of the tab, gives
  the running settings as a file, however the skimmer was started, with every
  password left out (null, and a `_passwords` note saying so): the page is
  open to anyone who can reach it. Put the passwords back, and it is a file
  to start with `--config`.

## Setting it up from the web page

**The first time** (no arguments, no file): the page on port 9101 is a
setup wizard.

1. **An admin password**, twice, or **Generate one** (20 random characters)
   and **Copy** it. It protects the settings from then on. Until it is set,
   only a client on a private address (10/8, 172.16/12, 192.168/16, the host
   itself, IPv6 ULA and link-local) may set it; a visitor from anywhere else
   sees how to set the skimmer up instead.
2. **The source:** **Scan the network** finds UberSDR receivers (mDNS), each
   a card with its name, calls, location, sessions free, IQ modes, what it
   tunes and whether it skims CW already; or HPSDR radios (discovery), each
   with its receivers and state, ticked to use (by MAC). A receiver's
   address can be typed in instead (**Read it** shows its card), and
   ka9q-radio or a recording given by hand. On Windows, **A radio's driver
   (DLL)** lists the DLLs in the program's folder, the working folder and
   CW Skimmer Server's (Program Files and its user data), or a folder or file
   given by its whole path. Each is read first, never loaded: a Skimmer
   Server SDR driver is a DLL for x86 or x64 exporting GetSdrInfo, StartRx,
   StopRx and SetRxFrequency, and every DLL it imports must be found where
   Windows will look when it is loaded (beside it, and those beside it in
   turn; the system folder for its architecture, SysWOW64 for a 32-bit one;
   the Windows folder; PATH). Only those can be ticked. Ticked, or on
   **Test**, it is loaded in a process of its own (the 32- or 64-bit host,
   in its folder, ended with the skimmer) and asked what it is: its
   GetSdrInfo, never its StartRx, the process ended straight after. That
   gives the radio's name, receivers and rates, kept for that version of the
   file; a driver this skimmer is running is never loaded twice. The check
   refuses a `dll` that is no driver, needs a DLL not found, or will not
   load (with why, at its key), and fits the bands to the receivers as a
   start does. IQ modes go to iq192, Skimmer Server's widest. A radio not
   connected shows only at the start.
3. **Bands**, 6 m; per radio with several (no band on two).
4. **Decoders:** CW, RTTY, JTTY; FT8, FT4, FT2, JS8, WSPR off, on the skimmed
   bands, every band or chosen ones; WSPR's modes.
5. **Station**, filled in from the receiver chosen if asked.
6. **Reporting:** RBN, PSK Reporter, WSPRnet; QRZ.com.
7. **Services:** the telnet and web ports; the addresses admin is allowed from.
8. **Review:** the file, the command line it stands for, and the check
   (as a start from it would be); **Save and start** writes it, and the
   skimmer starts from it (on the web port it says, which the page follows).

**Next** checks the settings so far, and goes on only without errors of that
step or one before; each is shown at its field. The check is a start's: the
file read and its options checked, then every stream planned with the
hardware as it is. That is the receiver's range, each HPSDR radio's
receivers and highest frequency, and radiod's front end: what the page
scanned, and for what it did not, asked by the skimmer then. A file the
wizard saves starts. What that means at each step:

- A radio whose bands need more receivers than it has (the 10 m beacons and
  the decoders' dials take streams of their own) is said at Bands, with a
  wider IQ mode offered when it is iq48 or iq96.
- A radio or radiod that does not answer is refused at its address; a
  receiver whose description cannot be read is not (a start goes on without
  its range).
- A band a radio or receiver cannot tune is not offered (6 m on a Hermes
  Lite 2, or on a receiver to 30 MHz, or with 6 m off), nor are WSPR's 22 and
  8 m, which need a stream given by its centre (All settings).
- A decoder's **every band** is written as the bands that can be skimmed,
  each added to the bands skimmed where it is not.
- With a recording, FT8, FT4, FT2, JS8 and WSPR (cut by the clock) and the
  reporters are not offered; WSPRnet needs WSPR on.
- A source still to be filled in says what it needs at its field (the
  receiver's address, the recording's file, a radio's bands).

**After that**, the Config tab of a skimmer run from a config file has
**Edit settings**: the admin password, then the same sections, **All
settings** (every key of this reference, each with its `--help`), the file as
**JSON**, and the admin password changed. Each change is checked a moment
later, each refusal shown at its key; **Save and restart** writes the file
and restarts the skimmer from it. **Restart** alone is there too. The file
this run started from checks good as it is: the radios it is streaming from
(which answer no discovery while it does) are taken as they answered at its
start.

A skimmer run from options (any argument on the command line, or Docker's
variables) never shows the wizard and is never edited here: its settings are
where its options are (in Docker, the compose file). Without
`--admin-password-hash` the page refuses every admin action; with it, Restart
is the only one.

- Once a password is set, any address may log in, unless `admin.allow` names
  the ones that may (a save that would leave out the address saving it is
  refused). Five wrong passwords a minute from an address lock it out for a
  minute; each login and failure is logged with its address.
- Behind UberSDR's addon proxy, the client's address is the one the proxy
  names (`X-Real-IP`); a header from a public address is never believed.
- Over plain HTTP the password crosses the network as typed: the login says
  so.
- Passwords stored never reach the page: they show as set, and are kept
  unless typed anew.

## Versions of the file

`"version": 1` is this layout. A release that renames or moves a key raises
the version and still reads older files, saying at start which keys moved
(`config.json: version 1: cw.decoder.beam is now ...; write the file again
with --write-config`). A key is never given a new meaning under its old
name, and no key is removed without a version that reads it. A file of a
version newer than the program knows is an error: the program is older than
the file.
