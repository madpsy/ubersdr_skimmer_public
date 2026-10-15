# ubersdr_skimmer

A wideband CW skimmer addon for [UberSDR](https://ubersdr.org) receivers. It
takes one wide IQ stream per band straight from the receiver, finds every CW
signal in them and reads them all at once, then spots them as CW Skimmer
Server does: on a DX-cluster telnet port, and optionally to the Reverse
Beacon Network as RBN Aggregator does (on by default) and to PSK Reporter
(off by default). A live web page shows it at work.

> **No WSJT-X needed.** FT8, FT4, FT2, WSPR and FST4W need nothing
> installed: WSJT-X's FT8 and FT4 decoders, WSJT-X improved's FT2,
> `wsprd` and jt9's FST4W decoder are built in (see
> [WSPR, built in](#wspr-built-in) and
> [FT8, FT4 and FT2, built in](#ft8-ft4-and-ft2-built-in)). Only the
> options that run WSJT-X's `jt9` program instead (`--ft8-jt9`,
> `--ft4-jt9`, `--ft2-jt9`, `--fst4w-jt9`) need it installed, and for FT2
> it must be [WSJT-X improved](https://sourceforge.net/projects/wsjt-x-improved/)'s
> (the normal WSJT-X has no FT2). The container has WSJT-X improved
> 3.1.0's `jt9` for them.

It reads more than CW, and `CW: "false"` turns CW off and leaves the rest
running:

- **RTTY**: every 45.45 baud, 170 Hz RTTY signal in the bands is decoded,
  its text shown live on the web page's RTTY tab, and the calls it sends are
  spotted as RTTY Skimmer Server does: on the next telnet port (7301), to RBN
  as RTTY and, when on, to PSK Reporter. `RTTY: "false"` turns it off.
- **JTTY**: WSJT-X 3.2's JTTY is decoded on its dials (7.090, 14.090, 21.090
  and 28.090 MHz) wherever a band's stream covers one, a port of WSJT-X's
  own receiver. Each signal's messages show live on the web page's JTTY tab,
  with the calls heard and who they worked; the calls go to PSK Reporter when
  that is on and to telnet port 7302 (not to RBN). `JTTY: "false"` turns it off.
- **FT8, FT4 and FT2** (off by default): decoded on the bands asked
  for by WSJT-X's FT8 and FT4 decoders and WSJT-X improved's FT2, built in
  (FT8 and FT4 the same decodes as WSJT-X's `jt9`, to the bit, in 35-40%
  of its CPU at the default depth on x86-64 and half on a Pi 5; FT2 on that
  FT4 decoder with improved's FT2 logic, in a quarter of improved's CPU
  at the default depth on x86-64, a third on a Pi 5);
  each band's latest cycle on the web page's FT8,
  FT4 and FT2 tabs; senders to PSK Reporter and, for CQs and roger reports
  in FT8 and FT4, to RBN as RBN Aggregator sends them.
- **JS8** (off by default): decoded on the bands asked for (JS8Call's dials,
  7.078 MHz on 40 m), Normal, Fast, Turbo and Slow at once, its frames put
  together into messages as JS8Call does. The web page's JS8 tab shows each
  band's activity and messages; the calls heard go to PSK Reporter with their
  grids.
- **WSPR and FST4W** (off by default): every WSPR and FST4W mode, WSPR by a
  built-in WSJT-X `wsprd` (the same decodes, about a tenth of the CPU on
  x86-64 and a sixth on a Pi 5) and FST4W by jt9's FST4W decoder, built in
  too (the same spots, about a seventh of jt9's CPU), shown on the web page's
  WSPR tab; uploaded to wsprnet.org, and to PSK Reporter.

The web page also has a **Radio** tab: a WebSDR of the receiver, on a 192 kHz
session of its own made only while a page has the tab open. Everyone with it
open sees its spectrum and waterfall; one listener at a time tunes it and
hears it (CW, USB, LSB, AM, synchronous AM, FM). Dragging the band moves it
under the dial without a break in the audio; the squelch, the meter and the
fixed gain go by the passband's noise, so they read alike on any receiver.
`RADIO: "false"` turns it off, `RADIO_PASSWORD` keeps tuning to those who know
it. The Resources tab's Sources section says what the receiver reports of
itself, and each stream's session. Its Clock section shows the host's clock against
NTP (checked every 64 s); more than half a second off, every tab says so at
the top.

This repository holds only what an install needs: the installer, the
`docker-compose.yml` and the helper scripts. The program comes as the Docker
image [`madpsy/ubersdr_skimmer`](https://hub.docker.com/r/madpsy/ubersdr_skimmer)
(amd64 and arm64).

**Status: testing.**

---

## Install

From UberSDR's Add-on Manager (`skimmer`), or on the receiver's host:

```
curl -fsSL https://raw.githubusercontent.com/madpsy/ubersdr_skimmer_public/main/install.sh | bash
```

That puts `docker-compose.yml` and the helper scripts in `~/ubersdr/skimmer`,
pulls the image and starts the container `skimmer` on UberSDR's Docker
network (`ubersdr_sdr-network`). `--force-update` (or `FORCE_UPDATE=1` when
piped) replaces an existing `docker-compose.yml`.

The Add-on Manager also adds the proxy, so the page is at
`http://<receiver>/addon/skimmer/`. By hand, in UberSDR's admin page add a
proxy with name `skimmer`, host `skimmer`, port `6101`, strip prefix on.

## Feeding UberSDR's CW spots

UberSDR takes CW spots from one CW skimmer's telnet port, set in its
`cwskimmer.yaml`. Point that at this addon and the receiver's CW spots, map,
analytics, PSKReporter uploads and the dxcluster addon's feed all come from
it:

```yaml
enabled: true
host: "skimmer"
port: 7300
```

## Configuration

Environment variables in `~/ubersdr/skimmer/docker-compose.yml`; run
`./restart.sh` after changing them. Left unset, each takes the default.
The web page's Config tab shows the configuration the skimmer is running
with, each setting beside its variable and option (passwords only as set or
not): the receiver or radios, every stream's centre, edges and width, what
each skims and decodes, the decoders' depths and threads, and the reporters.

| Variable | Default | |
|---|---|---|
| `UBERSDR_URL` | `http://ubersdr:8080` | the receiver |
| `UBERSDR_PASSWORD` | | the receiver's password, if it has one |
| `BANDS` | `all` | `all` is what CW Skimmer Server skims (160–6 m, 60 m, the beacon frequencies), less what the receiver cannot tune; or a list such as `40,30,20`. `2200` and `630` (2200 m, 630 m) are never in `all` and never skimmed, CW or RTTY: named (`all,2200,630`), each gets a stream for its WSPR and FST4W and the RF tab |
| `IQ_MODE` | `iq192` | `iq48`, `iq96`, `iq192` or `iq384`: the width of each stream |
| `MIN_MARGIN` | `15` | reduced-depth IQ, dB under the noise floor; `0` asks for lossless |
| `CALLSIGN` | the receiver's | spots go out as `CALLSIGN-#` (default: `cw_skimmer_callsign`, else the receiver's callsign) |
| `NAME`, `QTH`, `LOCATOR` | the receiver's | the station, for the telnet sign-on and RBN |
| `VALIDATION` | `normal` | `relaxed`, `normal` or `strict` |
| `RBN` | `true` | report spots to the Reverse Beacon Network (as RBN Aggregator does); `false` turns it off. RBN needs the station's locator: without one (the receiver publishes no GPS locator and `LOCATOR` is unset) the reporter does not start, the log says so, and the skimmer runs on without it |
| `RBN_DRY_RUN` | `false` | sign on to RBN and judge spots, but upload none |
| `RBN_CALL` | `CALLSIGN` | the call RBN knows the skimmer by, its spots as `RBN_CALL-#` |
| `RBN_BAD_CALLS` | `false` | `true`: send RBN no spot of a call in `./cache/BadCalls.txt` (as RBN Aggregator's "Not in BadCalls.txt"; the form under [The bad calls file](#the-bad-calls-file)), read again when edited; or a file's path in the container. The RBN tab's "Bad calls (manual)" shows the calls it held |
| `WEB_PORT` | `6101` | the web page |
| `TELNET_PORT` | `7300` | DX-cluster telnet, in CW Skimmer Server's format, RTTY's spots on the next port (7301) in RTTY Skimmer Server's, JTTY's on 7302; `0` turns them all off |
| `AGG_TELNET_PORT` | | with `RBN`, the reporter's local-user telnet port (as Aggregator's 7550) |
| `PSKREPORTER` | `false` | `true` reports spots to [PSK Reporter](https://pskreporter.info), as UberSDR reports its CW skimmer's: as `CALLSIGN` at `LOCATOR`, each call at most once a band in 2 minutes. JTTY's calls go too, as JTTY. If UberSDR already uploads its CW spots to PSKReporter (with `cwskimmer.yaml` pointing here), leave this off, or each spot goes twice |
| `PSKREPORTER_CALL` | `CALLSIGN` | the call reported as to PSK Reporter |
| `PSKREPORTER_ANTENNA` | | the antenna, as PSK Reporter shows it |
| `WSJTX_OUT` | | `HOST:PORT`, e.g. `192.168.1.20:2237`: the FT8, FT4, FT2, WSPR and FST4W decodes sent there as WSJT-X sends its own over UDP, for GridTracker, JTAlert and the like (see [Decodes to WSJT-X programs](#decodes-to-wsjt-x-programs)). Give the address of the PC the program runs on. Unset: off |
| `WSJTX_OUT_ID` | `UberSDR Skimmer` | the instance's Id, as those programs show it |
| `QRZ_USER`, `QRZ_PASSWORD` | | a [QRZ.com](https://www.qrz.com) login with an XML Data subscription: each call spotted is looked up (10,000 kept, the least recently spotted forgotten first), placing it on the web page's Map tab and giving its grid square to PSK Reporter. Checked at startup: if QRZ refuses it, the log and the Map tab say so and the skimmer runs on without. Not needed as an addon: the calls are asked of UberSDR's own lookups (its `lookup_services`, with `skimmer` among its `trusted_containers`), these used only if UberSDR serves none. Commented out in the compose file: uncomment and set them |
| `QRZ_VALIDATE` | `false` | `true`, with QRZ lookups (UberSDR's, or `QRZ_USER` and `QRZ_PASSWORD`): spot only calls QRZ knows. A call QRZ does not know is not spotted (and asked again after a day); a spot waits up to 10 s for QRZ's answer. When QRZ cannot answer (down, an error, too slow) the spot goes out as without it, and the call is asked again at its next spot. Beacons are not checked |
| `FREQ_CALIBRATION` | `1` | every frequency is multiplied by it, as by CW Skimmer Server's `FreqCalibration`: a factor (`1.000000468`) or ppm (`+0.5ppm`). [SM7IUN](https://sm7iun.se/rbn/analytics/) measures each RBN skimmer's error daily; the web page's RBN tab shows this skimmer's and the factor to set. A change shows fully in SM7IUN's list from the second day after it. With radios in `EXTRA_ARGS`, this is the default; a `--freq-calibration` after a radio there is that radio's ([Frequency calibration for each radio](#frequency-calibration-for-each-radio)) |
| `NOISE_FILTER` | `true` | keep tracks off SSB, data, noise and swept carriers in the CW segments (shown tinted on the web page); `false` tracks them as any signal |
| `GAP_FILL` | `true` | silence where the UberSDR's packets went missing (found by their timestamps), so WSPR and FT keep time; `false` passes the stream as it comes |
| `RTTY_FILTER` | `true` | find RTTY (two-tone FSK at the usual shifts) anywhere in the band but the digital modes' windows and keep tracks off it and its sidebands, which CW decoders otherwise read callsigns out of (shown tinted on the web page, with its shift). `false` tracks it as any signal, and decodes no RTTY |
| `RTTY` | `true` | decode the RTTY found (45.45 baud, 170 Hz; the web page's RTTY tab) and spot its calls by CW's rules: on telnet port 7301, to RBN as RTTY and, with `PSKREPORTER`, to PSK Reporter as RTTY. `false` decodes and spots none; the filter still keeps CW tracks off it |
| `MAX_RTTY` | `100` | RTTY signals each band decodes at once, shared by its streams (10 m has several); past it a new one goes undecoded (still kept clear of CW tracks), the log says so and the web page's RTTY bar shows it full |
| `JTTY` | `true` | decode WSJT-X 3.2's JTTY on its dials (7.090, 14.090, 21.090 and 28.090 MHz) wherever a stream covers one, shown live on the web page's JTTY tab; streams take a dial in where that costs no more of them. Its calls go to telnet port 7302 and PSK Reporter (with `PSKREPORTER`), never to RBN. `false` decodes none; a list of bands, e.g. `40,20,15`, decodes it on those dials only |
| `FT8`, `FT4`, `FT2` | | bands to decode each mode on, e.g. `20,40` or `all`, or `true` for every band of `BANDS` with the mode's dial (default none), with WSJT-X's FT8 and FT4 decoders and WSJT-X improved's FT2, built in: senders to PSK Reporter (with `PSKREPORTER`) and FT8's and FT4's CQs to RBN; each mode's tab on the web page. Each band must be among `BANDS` |
| `FT8_DEPTH`, `FT4_DEPTH`, `FT2_DEPTH` | `normal` (the compose file: `deep`) | the decoding depth: `fast`, `normal` or `deep` |
| `FT8_THREADS`, `FT4_THREADS`, `FT2_THREADS` | every dial at once (the compose file: `4`) | the mode's decodes at once, every dial's together: a cycle waits its turn, dropped if not decoded within two cycles; the built-in decoders only |
| `FT8_JT9` | `false` | `true`: FT8 by the `jt9` program (`JT9`) instead of the built-in decoder |
| `FT4_JT9` | `false` | `true`: FT4 by the `jt9` program (`JT9`) instead of the built-in decoder |
| `FT2_JT9` | `false` | `true`: FT2 by the `jt9` program (`JT9`, WSJT-X improved's) instead of the built-in decoder |
| `JT9` | `/usr/bin/jt9` | the jt9 program for `FT8_JT9`, `FT4_JT9`, `FT2_JT9` and `FST4W_JT9` (the image has none: mount one in, e.g. WSJT-X improved's for FT2) |
| `JS8` | | bands to decode JS8 on, e.g. `20,40` or `all`, or `true` for every band of `BANDS` with a JS8 dial (default none): Normal, Fast, Turbo and Slow, the calls heard to PSK Reporter (with `PSKREPORTER`) with their grids, never RBN; the web page's JS8 tab. Each band must be among `BANDS`. Needs nothing in the container |
| `WSPR` | | bands to decode WSPR and FST4W on, e.g. `20,40,80eu` or `all` (every dial but 22 and 8 m's: those by name, with a stream's centre in `BANDS`, e.g. `13.5551`), or `true` for every band of `BANDS` with a WSPR dial (default none; `80` is both 80 m dials when the stream holds 80eu, `60` likewise), with WSJT-X's `wsprd` and jt9's FST4W decoder, built in; the web page's WSPR tab. |
| `WSPR_MODES` | `W2,F2,F5`, and `W2,F2,F5,F15,F30` on 2200 m and 630 m | `W2` (WSPR), `W15` (WSPR-15), `F2`, `F5`, `F15`, `F30` (FST4W-120 to -1800) or `all`; a band's own after a space, e.g. `W2,F2,F5 2200:F15,F30 630:all`: a band named takes its own, the list without a band every other (2200 m and 630 m too). Each band keeps only the slice of audio the decoders read, about 11 MB a band with all |
| `WSPR_DEPTH` | `deep` | `fast`, `normal` or `deep` (wsprd `-qB`, `-C 500 -o 4`, `-C 500 -o 4 -d`) |
| `WSPR_NOISE_CAL` | | each band's noise is measured every 2 minutes in dBFS/Hz; dB added to make it dBm/Hz, measured for your receiver: one for every band (`-130`) or a band's own (`-130 20:-128.5`) |
| `WSPR_THREADS` | `4` | WSPR decoders run at once (half the cores if fewer: 2 on a Pi 5); a band and mode one at a time |
| `FST4W_THREADS` | `4` | FST4W decoders run at once, a pool apart from WSPR's (half the cores if fewer); a band and mode one at a time (a band's FST4W modes one at a time), FST4W-1800 one at a time (about 0.5 GB) |
| `WSPRD` | | a wsprd program to decode WSPR with instead of the built-in one (the same decodes), mounted in (the image has none) |
| `WSPRD_ARGS` | | wsprd's flags in place of `WSPR_DEPTH`'s, e.g. `-C 500 -o 3 -d`; not `-a`, `-c`, `-0`, `-f`, `-m` or a file |
| `FST4W_JT9` | `false` | `true`: FST4W by the `jt9` program (`JT9`) instead of the built-in decoder |
| `FST4W_SPREAD` | `fast` | the built-in FST4W decoder's spread: `fast` (within 0.0001 Hz of jt9's), `exact` (jt9's) or `off` |
| `WSPRNET` | `false` | `true` uploads WSPR and FST4W spots to [wsprnet.org](https://wsprnet.org) as `CALLSIGN` at `LOCATOR`; spots wait in `/dev/shm` until wsprnet takes them. If UberSDR already uploads this receiver's WSPR, leave this off. The WSPRnet tab also shows [wspr.live](https://wspr.live)'s ranking of every reporter (yesterday, the last 24 hours, today), fetched a minute after start and hourly |
| `WSPRNET_CALL` | `CALLSIGN` | the call uploaded as to wsprnet |
| `STATIC_FILTER` | `full` | static crashes (lightning far off, lifting the whole band for a few ms several times a second): `full` starts no track, and keeps none running, on a signal over the threshold only because a crash lifted the band; `starts` starts none so but lets crashes keep running tracks; `off` tracks them as any signal. The web page shows how often they come (the noise floor drawn bolder, and the stream's "static" figure) |
| `RADIO` | `true` | the web page's Radio tab: a 192 kHz session of its own on the receiver, opened while a page has the tab open and closed 10 s after the last leaves. `false` turns it off |
| `RADIO_PASSWORD` | | the Radio tab tuned only by a page that gives this; anyone may still watch its spectrum. Unset: anyone may tune it |
| `FETCH` | `true` | download the latest reference files (cty.dat, MASTER.SCP, the cluster's calls, RBN's bcn.csv and patt3ch.lst) at start and as they are due. `false`: never; the copies built into the program are used |
| `EXTRA_ARGS` | | any other option (all of them under [Every option](#every-option)) |

Each band is its own session on the receiver. UberSDR's usual configuration
lets addons on its Docker network past the session limits; if yours does not,
set `UBERSDR_PASSWORD` to its bypass password.

The fetched reference lists (cty.dat, MASTER.SCP and RBN's), FFTW's wisdom and
the RBN reporter's state are kept in `~/ubersdr/skimmer/cache`. Every
reference list is also built into the program (the latest there was when it
was built), so it has them before, or without, any download; the web page's
Reference files and Config tabs say which copy is in use for each: fetched
online, built in or a local file.

### The bad calls file

`BadCalls.txt` (with `RBN_BAD_CALLS: "true"`, `~/ubersdr/skimmer/cache/BadCalls.txt`)
is a plain text file, one callsign a line:

```
# busted calls the skimmer keeps hearing
T2X
E5ABC
DL1ABC/P
```

- A line is a whole call, matched exactly: no wildcards, prefixes or patterns.
  `DL1ABC` holds `DL1ABC` only; `DL1ABC/P` needs its own line.
- Upper or lower case alike; spaces around the call are ignored.
- Blank lines and lines starting with `#` are skipped.
- Only the spotted call is checked, and a beacon in the list is held too.
- Saved changes are read within 10 s; no restart is needed. A missing file
  holds nothing, and the RBN tab says it cannot read it.

## Ports

| Port | |
|---|---|
| 6101 | the web page; UberSDR proxies it at `/addon/skimmer/` |
| 7300 | DX-cluster telnet, `skimmer:7300` on the Docker network. Not published on the host; uncomment `ports:` in the compose file to publish it (the dxcluster addon may already use 7300 there) |
| 7301 | RTTY's spots, as RTTY Skimmer Server's telnet, `skimmer:7301`. Not published either |
| 7302 | JTTY's spots, in the same lines, `skimmer:7302`. Not published either |

## Decodes to WSJT-X programs

`--wsjtx-out HOST:PORT` (`WSJTX_OUT` in the compose file) sends every FT8,
FT4, FT2, WSPR and FST4W decode to a program that takes WSJT-X's UDP messages,
such as GridTracker or JTAlert, byte for byte as WSJT-X sends its own to its
"UDP Server". WSJT-X's port is 2237. A multicast group (e.g.
`239.255.0.1:2237`) works too; its TTL is 1, as WSJT-X's, unless you set
`--wsjtx-out-ttl`.

- The skimmer is one instance, Id `UberSDR Skimmer` (`--wsjtx-out-id`), for
  every band. Each dial's decodes come between two Status messages, one
  "decoding" and one not, as WSJT-X sends them around a decode. That Status
  carries the dial, the mode and the band (as the configuration name).
- FT8, FT4 and FT2 decodes go as Decode messages, with the decode line's
  marker as the mode (`~` FT8, `+` FT4) and the message text as WSJT-X gives
  it. FST4W decodes go as Decode messages too (marker `` ` ``), and WSPR
  decodes as WSPRDecode messages.
- JTTY, JS8, CW and RTTY are not sent, because WSJT-X sends none of them.
- A Heartbeat goes every 15 s, and a Close when the skimmer stops.
- The program's replies are read only for the protocol's schema number.
  Commands such as Reply and Halt Tx do nothing here.
- A host that does not resolve at startup is tried again every 15 s, and the
  log says so once. Startup logs where the decodes go. Nothing is logged
  when the program on the other end is closed or not running: the decodes
  just go unheard until it is back.

## The feed: every spot and the skimmer's health, for your own program

`/api/feed` is a stream your own program can read: every spot the skimmer
validates, in every mode (CW, RTTY, JTTY, FT8, FT4, FT2, WSPR, FST4W, JS8),
in one JSON form, with what QRZ has of the call when it has been looked up;
and every 10 seconds the skimmer's health, with a status to alert on. It is
like having the decoders running in your program: spots are sent as they
are made, never held back as repeats (nothing is held for 5 minutes as it is
for RBN and telnet).

It is a [Server-Sent Events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
stream on the web port, so any language can read it: an HTTP GET that stays
open, one message after another.

**Where.** Through UberSDR, at the addon's address:

```
curl -N http://<receiver>/addon/skimmer/api/feed
```

From another container on UberSDR's Docker network, `http://skimmer:6101/api/feed`.
The page's Telnet tab shows the address as your browser reaches it, under
Help, with the programs reading the feed now (where from, what they asked
for, what they have been sent), and Connect there makes the page an example
consumer, showing each message as your program would get it.

**Choosing.** `?types=spot,health` the message types; `?modes=CW,FT8` spots
of these families or modes (a family takes all its modes); `?bands=20,40`
spots on these bands:

```
curl -N 'http://<receiver>/addon/skimmer/api/feed?types=spot&modes=CW,FT8&bands=20,40'
```

### Messages

Each message is an event named by its type, its data one line of JSON whose
`type` says the same, first; a blank line ends it, and a line starting with a
colon is a keepalive (every 15 seconds) to ignore. More types may come: **a
program is to ignore types, and fields, it does not know.** Each message's
`v` is the version of its type's form, raised only if a field changes
meaning or goes.

```
id: 1791639174496
event: spot
data: {"type":"spot","seq":1791639174496,"v":1,"t":1791639189,"spotter":"M9PSY","family":"CW","mode":"CW","band":"20","freq_hz":14018995.5,"call":"HG0R","snr":37,"spot_type":"CQ","wpm":27,"entity":"Hungary","continent":"EU","qrz":{"call":"HG0R","name":"...","country":"Hungary","grid":"JN97ma","lat":47.5,"lon":19.04,"lotw":true,...}}
```

**`spot`**, one a validated spot:

| Field | |
|---|---|
| `seq` | its id, ascending (also the event's id) |
| `t` | when heard, UTC Unix seconds; FT, WSPR and JS8: the start of the cycle or period it was sent in |
| `spotter` | this skimmer's call |
| `family` | `CW`, `RTTY`, `JTTY`, `FT`, `WSPR` or `JS8` |
| `mode` | within the family: `FT8`, `FT4`, `FT2`, `WSPR-2`, `FST4W-300`, `JS8-Turbo`...; for CW, RTTY and JTTY the family |
| `band` | metres, without the m: `"20"`, `"630"` |
| `freq_hz` | the signal's frequency, Hz (CW, RTTY and JTTY to 0.1 Hz) |
| `call`, `snr` | the sender, and its SNR in dB (FT, WSPR and JS8 in 2500 Hz, as their decoders give it) |
| `spot_type` | `CQ`, `DE`, `BEACON`, `NCDXF` or `HEARD` |
| `wpm` / `baud` | CW's speed / RTTY's and JTTY's |
| `locator` | the sender's own, when it sent one |
| `dbm`, `spread_hz` | WSPR's power; WSPR's and FST4W's spread |
| `message`, `dt` | FT's and WSPR's decoded text, as the decoder printed it (FT's the call's strongest decode in the cycle), and its time offset, s |
| `drift` | WSPR's drift, Hz a minute (not FST4W's) |
| `dial_hz` | FT's, WSPR's and JS8's dial, Hz: `freq_hz` less it is the audio offset |
| `entity`, `continent` | the sender's country and continent, by cty.dat |
| `country_code` | its country's ISO 3166-1 alpha-2 code, when it has one |
| `cq_zone`, `itu_zone`, `utc_offset` | cty.dat's zones and local time's offset from UTC (hours, east positive) |
| `lat`, `lon`, `loc_source` | where it is: its own locator (`locator`), else QRZ's position where it applies (`qrz`), else its country's middle (`cty`) |
| `km`, `bearing` | how far and which way from the receiver (UberSDR's GPS position, else the skimmer's locator) |
| `qrz` | QRZ's record of the call, when the skimmer has it: `call` (QRZ's, the home call), `name`, `city`, `county`, `state`, `country`, `grid`, `lat`, `lon`, `geoloc`, `tz_iana` (the time zone there, UberSDR's), `license`, `qsl`, `lotw`, `eqsl`, `mqsl`, `dxcc`, `cq_zone`, `itu_zone`, `born`, `url`, `image`, `at` (when QRZ answered), and `home_only`, true when the call signs from elsewhere (`EA5/G4ABC`, `/MM`) so the place is its home station's |

Fields are left out where they do not apply. `qrz` comes from the skimmer's
QRZ lookups (UberSDR's, or `--qrz-user`), never asked for by the feed: CW,
RTTY and JTTY calls are looked up as they are spotted, so a call's first spot
may come before QRZ answers; FT, WSPR and JS8 calls, too many to look up,
have it only when already looked up.

**`health`**, every 10 seconds, and the latest to a new reader at once:

| Field | |
|---|---|
| `status` | `ok`, `warn` or `error`: the one to alert on |
| `problems` | what makes it so, each a `level`, `part` (`receivers`, `receiver 20`, `decoder FT8 20`, `rbn`, `pskreporter`, `wsprnet`, `cpu`) and `text` |
| `cpu` | `percent` of the machine the skimmer and its decoders take, `cores`, and cores busy: `skimmer`, `decoders` |
| `memory` | bytes: `rss`, `own`, `decoders` |
| `receivers` | `up` of `total`: the IQ streams sending samples |
| `spots` | by family: `total` sent on the feed, and in the `last_min` |
| `reporters` | `rbn`, `pskreporter`, `wsprnet`, those running: sent, failed (and in the last minute), queued, `last_error` |
| `version`, `uptime_s` | |

An error: no receiver sending samples, or RBN taking nothing for 10 minutes
with spots waiting. A warning: a receiver or FT decoder down, a failure
sending to RBN, PSK Reporter or wsprnet in the last minute (wsprnet's until
an upload succeeds), or the machine's CPU 90% busy. No message for 30
seconds: take the skimmer as down.

**`gap`**: `{"type":"gap","since":ID,"oldest":ID}`, spots missed and no
longer kept (see Resuming).

### Resuming

A program that reconnects with the last id it read, as the header
`Last-Event-ID: ID` (a browser's EventSource sends it itself) or `?since=ID`,
gets the spots it missed while they are still kept (the last 8 MB: minutes
on a busy FT8 day, hours of CW), then those to come. If some are no longer
kept, or the skimmer has restarted, a `gap` comes first. A program 16 MB
behind is disconnected, to reconnect and resume.

### An example consumer

An example to start your own from, Python 3 with nothing to install: it
prints each spot (with the operator's name when QRZ's record is there), and
the health when it is not `ok`, resuming where it left off after a dropped
connection. Your program can do what it likes with the messages: log them,
store them, map them, alert on the health.

```python
import json, time, urllib.request

URL = "http://<receiver>/addon/skimmer/api/feed"
last_id = None  # where to resume from after a reconnect

while True:
    headers = {"Last-Event-ID": last_id} if last_id else {}
    try:
        with urllib.request.urlopen(urllib.request.Request(URL, headers=headers), timeout=60) as r:
            event, data = None, []
            for raw in r:
                line = raw.decode("utf-8").rstrip("\r\n")
                if line.startswith("id: "):
                    last_id = line[4:]
                elif line.startswith("event: "):
                    event = line[7:]
                elif line.startswith("data: "):
                    data.append(line[6:])
                elif line == "" and data:  # a blank line ends a message
                    msg = json.loads("\n".join(data))
                    if event == "spot":
                        name = msg.get("qrz", {}).get("name", "")
                        print(msg["call"], msg["mode"], msg["band"], msg["freq_hz"], msg["snr"], name)
                    elif event == "health" and msg["status"] != "ok":
                        print("health:", msg["status"], msg["problems"])
                    # any other type: ignored
                    event, data = None, []
    except OSError as e:
        print("reconnecting:", e)
        time.sleep(3)
```

In JavaScript (a browser, or Node 22 and later), an EventSource does the
reading, the reconnecting and the resuming itself:

```js
const es = new EventSource("http://<receiver>/addon/skimmer/api/feed?types=spot,health");
es.addEventListener("spot", (e) => {
  const s = JSON.parse(e.data);
  console.log(s.call, s.mode, s.band, s.freq_hz, s.snr, s.qrz?.name ?? "");
});
es.addEventListener("health", (e) => {
  const h = JSON.parse(e.data);
  if (h.status !== "ok") console.warn(h.status, h.problems);
});
```

### /api/health: for a health check

A plain GET for Docker's `HEALTHCHECK` or a monitor, answered at once:
`{"live":true,"problems":[],"status":"ok","health":{...}}`, `health` being
the latest `health` message (null for the first 10 seconds) and `status` its
status.

It is **503** only when the skimmer itself is stuck, which a restart would
mend: its state not gathered for 30 seconds (the web page's ticker), or a
stream inside its decoders for 60 seconds (a block of IQ takes
milliseconds); `problems` says which. A receiver away, or RBN, PSK Reporter
or wsprnet failing, is never one: the streams reconnect by themselves (an
UberSDR stream that sends no IQ for 15 seconds is dropped and made again),
and restarting would not bring a receiver back. `?ready` is 503 also while
the health's status is `error` (no receiver sending samples), for a monitor
that should say so; it is not for a container's health check.

The image's `HEALTHCHECK` asks for `/api/health` every 30 seconds. Docker
only marks a container unhealthy; it does not restart it.

## Helper scripts

In `~/ubersdr/skimmer`:

| Script | |
|---|---|
| `start.sh` | start the container |
| `stop.sh` | stop it |
| `restart.sh` | stop and start it, applying changes to `docker-compose.yml` |
| `update.sh` | run the installer again: the latest image and scripts (`docker-compose.yml` is kept) |

Logs: `docker logs -f skimmer`.

---

## Running the program yourself: every source of IQ

Without Docker, the skimmer is one file that needs nothing installed beside
it, its reference files (cty.dat, MASTER.SCP and the like) included: built
in, and replaced by the latest downloaded unless `--no-fetch`. Download it from
[Releases](https://github.com/madpsy/ubersdr_skimmer_public/releases/latest):
`ubersdr-skimmer-linux-x86_64`, `ubersdr-skimmer-linux-aarch64` (Raspberry Pi
and other 64-bit ARM) or `ubersdr-skimmer-windows-x86_64.exe`. It takes its IQ
from exactly one kind of source: `--url`, `--hpsdr`, `--ka9q`, `--driver` or
`--input`. Live, spots go to telnet port 7300 and the web page is at
`http://localhost:9101/`; `--help` lists every option.

| Source | Option | Runs on | Radios | Streams | Example |
|---|---|---|---|---|---|
| UberSDR receiver | `--url URL` | Linux, Windows | any UberSDR receiver you can reach | one session per band, iq48–iq384 | `--url http://sdr.example.com:8080 --bands all` |
| HPSDR radio | `--hpsdr IP` | Linux, Windows | Hermes Lite 2, Hermes, Angelia, Orion, ANAN, Red Pitaya, UberSDR's HPSDR bridge | one of the radio's receivers per band, iq48–iq384; on Windows, shared with CWSL tools with `--cwsl` | `--hpsdr 192.168.1.50 --mode iq192 --bands 80,40,30,20` |
| ka9q-radio | `--ka9q STATUS` | Linux (radiod's host, or the same LAN) | whatever radiod's front end is: RX888, Airspy, Airspy HF+, SDRplay, HackRF, RTL-SDR, FUNcube... | one radiod channel per band, iq48–iq384, made beside its others | `--ka9q hf-status.local --bands all` |
| Skimmer Server driver | `--driver DLL` | Windows | any radio CW Skimmer Server drives (QS1R, HermesIntf radios, ...) | one of the radio's receivers per band, iq48–iq192; shared with CWSL tools | `--driver C:\Radios\Qs1rIntf.dll --bands 40,30,20` |
| Recording | `--input FILE` | Linux, Windows | raw IQ as `--record` writes it | one stream | `--input 40m.cf32 --rate 96000 --freq 7020000` |

Away from a receiver there is nowhere to take the station from. Give `--call`,
and for RBN (`--rbn`) also `--name`, `--qth` and `--locator`. `--pskreporter`
reports to PSK Reporter as well (off by default; it needs `--call` and
`--locator`), and `--pskreporter-antenna` names the antenna.

### From an UberSDR receiver (`--url`)

What the addon does, from any receiver you can reach:

```
ubersdr-skimmer-linux-x86_64 --url http://sdr.example.com:8080 --bands all --call M9PSY
ubersdr-skimmer-linux-x86_64 --url http://sdr.example.com:8080 --bands 40,30,20 --mode iq192 --password PW
```

`--mode` is `iq48`, `iq96` (default), `iq192` or `iq384`. Each band is a
session on the receiver; `--password` takes a password or the bypass password.
A band's streams start 2 kHz below it, with the rest of their width above,
where RTTY and the digital modes are, rather than centred (the same for
`--ka9q`; `--centre-streams` centres them).
With `--web`, the Radio tab is a 192 kHz session of its own, opened while a
page has it open (`--no-radio` for none, `--radio-password PW` to keep tuning
to those who know it), tuned within the range the receiver advertises.

### From an HPSDR radio on the network (`--hpsdr`, Linux and Windows)

An openHPSDR radio, spoken to directly at its IP address (or name, or MAC):
Hermes Lite 2, Hermes, Angelia, Orion, ANAN, Red Pitaya, or UberSDR's own
HPSDR bridge. The skimmer drives it as CW Skimmer Server's HermesIntf does, in
protocol 1 or 2, whichever the radio answers. Skimmer Server, its drivers and
Docker are not needed.

`--hpsdr-discover` lists the radios on this host's networks and exits:

```
$ ubersdr-skimmer-linux-x86_64 --hpsdr-discover
IP               MAC                Device      Board  Protocols  Gateware  Receivers     Up to  Attenuator      State
192.168.9.67     00:1c:c0:a2:3f:15  HermesLT        6  1          v72.8            10  38.4 MHz  none            idle
```

A MAC in place of the address is looked up the same way at start
(`--hpsdr 00:1c:c0:a2:3f:15`), so a radio given an address by DHCP is found
wherever it is.

```
ubersdr-skimmer-linux-x86_64 --hpsdr 192.168.1.50 --mode iq192 --bands 160,80,40,30,20,17,15,12 --call M9PSY
ubersdr-skimmer-windows-x86_64.exe --hpsdr 192.168.1.50 --mode iq96 --bands 40,30,20 --call M9PSY
```

- Each band of `--bands` takes one of the radio's receivers, as many as it
  says it has (a Hermes Lite 2 has 4, or 10 with the 10-receiver CIC
  gateware). If the bands need more, it says so.
- `--mode` is `iq48`, `iq96` (default), `iq192` or `iq384`. A radio that
  streams another rate is refused, and the message names the mode to use: a
  Hermes Lite 2 on the 10-receiver CIC gateware streams 192 kHz only, so it
  needs `--mode iq192`.
- `--hpsdr-protocol 1` or `2` insists on a protocol. `--hpsdr-att DB` fixes
  the step attenuator; by default it moves with ADC overloads, as HermesIntf
  moves it (on a Hermes, ANAN or Angelia, Orion, Orion2 or Saturn).
- Each band's streams are centred on what they skim, because a radio's
  decimating filters droop near the edges of its passband. `--low-streams`
  after an `--hpsdr` places them as an UberSDR's are instead: 2 kHz below
  the band, with the rest of their width above it for RTTY and the digital
  modes. The bottom of each band, the busiest CW, then sits near the edge.
- A radio busy with another program is left to it. If the radio goes quiet,
  it is started again.
- On Windows, `--cwsl` after an `--hpsdr` also shares that radio's receivers
  with CWSL tools (CWSL_DIGI, CWSL_File, Extio_CWSL, a Skimmer Server running
  CWSL_Tee...), as CWSL_Tee beside HermesIntf would: see
  [Sharing the IQ with CWSL tools](#sharing-the-iq-with-cwsl-tools). The
  radio serves one program, so this is how the others get its IQ too.
  `iq48`, `iq96` or `iq192` only.

```
ubersdr-skimmer-windows-x86_64.exe --hpsdr 192.168.1.50 --mode iq192 --bands all --cwsl --call M9PSY
```

- A receiver to spare (one more than the bands take) becomes the web page's
  **Radio tab**: a WebSDR of the radio, its spectrum and waterfall for
  everyone with the tab open, tuned and heard by one listener at a time (CW,
  USB, LSB, AM, synchronous AM, FM; Opus audio). `--radio-password PW`
  keeps tuning to those who know it; `--no-radio` leaves the receiver
  unused. Each `--hpsdr` radio with a receiver to spare has its own tab
  ("Radio 1", "Radio 2"), independent of the others; either option before
  any `--hpsdr` is every radio's, after one that radio's.

Several radios: give `--hpsdr` once per radio, each with bands of its own. The
`--bands`, `--freq`, `--mode` and `--freq-calibration` options after an
`--hpsdr` are that radio's (see
[Frequency calibration for each radio](#frequency-calibration-for-each-radio)).
One radio given twice (by address and name, or address and MAC) is refused,
as is a band given to two radios: their receivers would only split it.

```
ubersdr-skimmer-linux-x86_64 --call M9PSY \
  --hpsdr 192.168.1.50 --mode iq192 --bands 160,80,40,30 \
  --hpsdr 192.168.1.51 --mode iq192 --bands 20,17,15,12
```

### From ka9q-radio (`--ka9q`, Linux)

A [ka9q-radio](https://github.com/ka9q/ka9q-radio) `radiod` already running,
on a standalone install: an RX888 or any other front end radiod drives. The
skimmer makes its own IQ channels on it, one per band, beside the channels
it has. Nothing in radiod's config changes and radiod is not restarted, so it
runs alongside anything else using that radiod without
disturbing it.

```
ubersdr-skimmer-linux-x86_64 --ka9q hf-status.local --bands all --call M9PSY
ubersdr-skimmer-linux-aarch64 --ka9q hf-status.local --bands 80,40,30,20 --mode iq192 --call M9PSY
ubersdr-skimmer-linux-x86_64 --ka9q hf-status.local --bands 40,20 --ka9q-gain 10 --call M9PSY
```

- `STATUS` is radiod's status group, as `status =` in its config's `[global]`
  section names it (often `hf-status.local`), or the group's
  address. avahi is not needed: the name is turned into the address as
  radiod itself does it.
- radiod is asked what its front end covers, and bands beyond it are left
  out: an RX888 sampling at 64.8 MHz reaches 30 MHz, so `--bands all` there
  skims 160–10 m.
- `--mode` is `iq48`, `iq96` (default), `iq192` or `iq384`.
- The level: radiod's AGC by default, as its `iq` preset runs it.
  `--ka9q-agc off` or `--ka9q-gain DB` fixes the gain instead;
  `--ka9q-agc-hang S`, `--ka9q-agc-recovery DB`, `--ka9q-headroom DB` and
  `--ka9q-agc-threshold DB` tune the AGC.
- Samples come as 32-bit floats; `--ka9q-encoding s16` halves the traffic.
- The IQ goes to a multicast group of the skimmer's own, so none of radiod's
  other listeners receive it (`--ka9q-data NAME` names the group).
- radiod is taken to be on the same host, whatever its `ttl` (a
  `ttl = 0` keeps radiod's traffic on the loopback interface). For a
  radiod on another host, with its `ttl` above 0, give the interface it is
  reached on: `--ka9q-iface eth0`.
- `--bands`, `--freq-calibration` and the `--ka9q-` options after a `--ka9q`
  are that radiod's.
- The channels are closed when the skimmer stops. If it dies instead, radiod
  removes them itself within 10 s. If the IQ stops, the channels are made
  again.
- With `--web`, the Radio tab is a 192 kHz channel of its own on radiod,
  made while a page has the tab open (in a fraction of a second) and tuned
  within radiod's front end. `--radio-password` and `--no-radio` after a
  `--ka9q` are its own.

### From a radio's CW Skimmer Server driver (`--driver`, Windows)

Any radio CW Skimmer Server drives, through the same driver, with
CWSL_Tee's job done as well:

```
ubersdr-skimmer-windows-x86_64.exe --driver C:\Radios\Qs1rIntf.dll --mode iq192 --bands 160,80,40,30,20,17,15,12 --call M9PSY
```

- `--driver` is the radio's Skimmer Server driver: the DLL you would put in
  Skimmer Server's directory (`HermesIntf.dll`, `Qs1rIntf.dll`, ...). It is
  the one a `CWSL_Tee.cfg` names on its first line. Skimmer Server and
  CWSL_Tee.dll are not needed.
- Each band of `--bands` takes one of the radio's receivers. The skimmer
  asks for no more than the radio has; if the bands need more, it says so.
- Each band's streams are centred on what they skim; `--low-streams` after a
  `--driver` places them 2 kHz below the band instead, as with `--hpsdr`.
- `--mode` is `iq48`, `iq96` (default) or `iq192`.

### From a recording (`--input`)

Raw interleaved IQ, as `--record` writes it (`cf32`) or 16-bit (`--format
cs16`), with its rate and centre frequency:

```
ubersdr-skimmer-linux-x86_64 --input 40m.cf32 --rate 96000 --freq 7020000 --call M9PSY
```

### HermesIntf and several radios through drivers

**HermesIntf** ([k3it/HermesIntf](https://github.com/k3it/HermesIntf/releases))
drives OpenHPSDR radios: Hermes, Hermes Lite 2, ANAN, Red Pitaya and others.
It takes the first radio that answers. To pin it to one radio, rename the DLL
with the radio's IP address or the last two bytes of its MAC address:
`HermesIntf_192.168.1.50.dll` or `HermesIntf_693c.dll`. For these radios,
`--hpsdr IP` does the same without the DLL, on Linux too, and on Windows
`--hpsdr IP --cwsl` shares the receivers' IQ with CWSL tools as `--driver`
does.

**Several radios.** Give `--driver` once per radio. The `--bands`, `--freq`,
`--mode`, `--freq-calibration` and `--cwsl-` options given after a
`--driver` are that radio's:

```
ubersdr-skimmer-windows-x86_64.exe --call M9PSY ^
  --driver C:\Radios\HermesIntf_192.168.1.50.dll --mode iq192 --bands 160,80,40,30,20,17,15,12 ^
  --driver C:\Radios\HermesIntf_192.168.1.51.dll --bands 10
```

### Frequency calibration for each radio

`--freq-calibration F` (`FREQ_CALIBRATION` in Docker) multiplies every
frequency by F, as CW Skimmer Server's `FreqCalibration` does: a factor
(`1.000000468`) or ppm (`+0.5ppm`). Each radio has its own reference
oscillator, so its own error: a `--freq-calibration` after an `--hpsdr`,
`--ka9q` or `--driver` is that radio's alone, and one before any radio is
the default for those given none.

```
ubersdr-skimmer-linux-x86_64 --call M9PSY --freq-calibration +0.4ppm \
  --hpsdr 192.168.1.50 --mode iq192 --bands 160,80,40,30 \
  --hpsdr 192.168.1.51 --mode iq192 --bands 20,17,15,12 --freq-calibration -1.2ppm
```

The first radio takes the default, +0.4 ppm; the second, -1.2 ppm. The
log and the Config tab (a row for each radio) say which applies. SM7IUN
measures one error for the whole call, all radios together; with several
radios the RBN tab gives each radio's new calibration (its own times
SM7IUN's factor). To tell one radio's error from another's, compare its
spots with RBN's or a beacon's frequency.

### Sharing the IQ with CWSL tools

As [CWSL_Tee](https://github.com/HrochL/CWSL) does, every receiver's IQ is put
in shared memory: always with `--driver`, and with `--hpsdr` when `--cwsl` is
given after it (Windows only). CWSL_File, CWSL_Wave, CWSL_DIGI, Extio_CWSL
(for HDSDR and Winrad), CWSL_Net, CWSL_USBWave and a Skimmer Server running
CWSL_Tee can read it, alongside the skimmer, as they would from Skimmer
Server.

| | |
|---|---|
| Names | the first radio's receivers are `CWSL0Band`, `CWSL1Band`, ...; the second radio's `CWSL0Band2`, ... (the names `CWSL_Tee2.dll`, `CWSL_File2.exe` and `Extio_CWSL2.dll` use); the third's `CWSL0Band3`, ... |
| `--cwsl` | after an `--hpsdr`: share that radio's IQ (off by default; `iq48`, `iq96` or `iq192`). `--cwsl-blocks` or `--cwsl-suffix` after an `--hpsdr` turn it on too |
| `--cwsl-suffix S` | after a `--driver` or `--hpsdr`: that radio's names become `CWSL0BandS`, ... |
| `--cwsl-blocks N` | blocks of 1/93.75 s each memory holds (default 64, as `CWSL_Tee.cfg`'s second line); `0` shares nothing |
| Receivers | as many as the radio has, up to 32 (the most CWSL's tools look for), not CWSL_Tee's 8 |

To record a band with CWSL_File while the skimmer runs, for example:
`CWSL_File 2` records the third receiver (`CWSL2Band`), and `CWSL_File 7030`
records the receiver whose band holds 7030 kHz. For the second radio, use
`CWSL_File2.exe`.

The shared memory exists while the skimmer runs, and is gone when it stops.
If a Skimmer Server with CWSL_Tee already has a radio under the same names,
the skimmer stops and says so; pick another `--cwsl-suffix`.

Skimmer Server's drivers are 32-bit, so the skimmer starts a small 32-bit
helper, `sdr-host`, for each radio. It writes the helper to
`%LOCALAPPDATA%\ubersdr-skimmer\` and runs the driver in it. If Windows
Firewall asks about a network driver such as HermesIntf, the program it
names is `sdr-host-x86-....exe`.

---

### WSPR, built in

WSPR-2 and WSPR-15 are decoded inside the skimmer by WSJT-X's own `wsprd`,
in C++: nothing to install, no program started, nothing written to disk but
its table of hashed calls. Its decodes are WSJT-X's to the bit, checked
against `wsprd` built from WSJT-X's source on hundreds of real and synthetic
periods, its every step as well as its output. And it takes far less CPU,
the same arithmetic done in a cheaper order and many lanes at once (AVX2 on
x86-64, NEON on arm64):

| CPU for 9 WSPR periods | WSJT-X's wsprd | built in |
|---|---:|---:|
| x86-64 (Ryzen 7 5700U) | 22.8 s | 2.2 s |
| Raspberry Pi 5 | 28.6 s | 4.9 s |

About a quarter of a second a 2-minute period and band on a PC, half a second
on a Pi 5. Each WSPR spot also gets the signal's spread, measured as WSJT-X
measures FST4W's (how wide it arrived: what the path did to it), for the
WSPR tab and Analytics, at about 0.7 ms a decode, the decodes unchanged.
`--wsprd PATH` (`WSPRD`) runs a wsprd program instead, and
`--wsprd-args` (`WSPRD_ARGS`) gives wsprd's own flags.

FST4W (FST4W-120 to -1800) likewise: jt9's FST4W decoder in C++, the same
spots as WSJT-X's `jt9 --fst4w` to the character (checked on 86 generated
and real periods; every field of its output to the bit on x86-64, with the
exact spread), with no program started:

| CPU for 9 FST4W periods | WSJT-X's jt9 | built in |
|---|---:|---:|
| x86-64 (Ryzen 7 5700U) | 32.8 s | 4.4 s |
| Raspberry Pi 5 | 56.4 s | 8.5 s |

An FST4W-1800 period takes about 0.5 GB while it decodes (jt9 1.1 GB). Each
band keeps one hash table for all its FST4W modes, kept across restarts, so
a call sent in full on one resolves its hashed (`<CALL> GRID6`) messages on
all of them; such a message carries no power, so its spot takes the call's
last heard on the band, and goes to wsprnet only with one. The spread is
measured a cheaper way by default, within 0.0001 Hz of jt9's
(`--fst4w-spread exact` for jt9's own, `off` for none). `--fst4w-jt9`
(`FST4W_JT9`) runs the `jt9` program instead.

### FT8, FT4 and FT2, built in

FT8 and FT4 are decoded inside the skimmer by jt9's own FT8 and FT4
decoders (WSJT-X 3.2.0-rc1, commit `567ad29ce`) in C++, and FT2 as WSJT-X
improved 3.2.0 decodes it (its FT2 code, on that FT4 decoder): no program started,
one decoder a band on a thread of its own, given each cycle as WSJT-X gives
jt9 it. Every decode, its order, SNR, DT, frequency and annotation are
jt9's, checked against jt9 built from WSJT-X's source on hundreds of
recorded and generated periods, to the bit on x86-64 Linux and Windows (on
a Pi, FFTW's ARM code rounds differently, and a few FT8 decodes near a
threshold can go the other way; no FT4 or FT2 decode differed). FT2's
reference is improved's FT2 code built on that FT4 decoder. CPU of the
decoding alone, best of three, every decode the same (FT8: 17 periods, FT4:
20, FT2: 25, busy and quiet, recorded and generated; FT2's busy periods are
generated, as no FT2 was heard while recording):

| CPU, WSJT-X's jt9 / built in | `fast` | `normal` (default) | `deep` |
|---|---:|---:|---:|
| FT8, x86-64 (Ryzen 7 5700U) | 7.9 / 3.9 s | 24.5 / 9.7 s | 62.8 / 21.8 s |
| FT8, Raspberry Pi 5 | 13.6 / 8.5 s | 46.5 / 21.8 s | 125.2 / 50.4 s |
| FT4, x86-64 (Ryzen 9 3900X) | 0.50 / 0.14 s | 2.08 / 0.72 s | 3.70 / 0.86 s |
| FT4, Raspberry Pi 5 | 0.90 / 0.34 s | 3.97 / 1.90 s | 7.26 / 2.22 s |
| FT2, x86-64 (Ryzen 9 3900X), WSJT-X improved 3.2.0's jt9 | 1.34 / 0.32 s | 2.29 / 0.54 s | 4.22 / 0.70 s |
| FT2, Raspberry Pi 5, WSJT-X improved 3.2.0's jt9 | 2.52 / 0.85 s | 4.29 / 1.48 s | 8.68 / 1.84 s |

Against the `jt9` the container has (WSJT-X improved 3.1.0's, which prints
the same on every cycle), FT4 takes 2.6-2.7x less CPU at `normal` and
4.7-4.9x less at `deep`, and 3.5 MiB a band against jt9's 13-24 MiB.
`--ft8-jt9` (`FT8_JT9`), `--ft4-jt9` (`FT4_JT9`) and `--ft2-jt9`
(`FT2_JT9`) run the `jt9` program instead. FT2's decodes are improved's
FT2 on WSJT-X's FT4 decoder above: improved 3.2.0 changed its FT4
decoder too (an extra a-priori pass, a slightly different front end), so
its `jt9` finds a few decodes more or less and prints some 1 Hz, 0.1 s or
1 dB apart.

### wsprd on its own

This decoder is also a program of its own, a drop-in for WSJT-X's `wsprd`
(the same options, output and files, byte for byte, plus `-n`), for Linux
and Windows: [ubersdr_wsprd](https://github.com/madpsy/ubersdr_wsprd), with
its source. The skimmer does not need it.

### FT8, FT4, FT2 and WSPR

FT8, FT4, FT2, WSPR and FST4W need nothing installed: WSJT-X's FT8 and
FT4 decoders, WSJT-X improved's FT2, `wsprd` and jt9's FST4W decoder are
built in, the same decodes in memory. `--ft8-jt9`, `--ft4-jt9`,
`--ft2-jt9`, `--wsprd PATH` and `--fst4w-jt9` run the programs instead:
WSJT-X's `jt9` (`apt install wsjtx` has it, in `/usr/bin`; on Windows,
WSJT-X's installer puts it in `C:\WSJT\wsjtx\bin`, where it is looked
for), for `--ft2-jt9`
[WSJT-X improved](https://sourceforge.net/projects/wsjt-x-improved/)'s
(WSJT-X's own has no FT2; tested with 3.1.0 improved AL_PLUS on Linux and
Windows). Each band asked for must be among `--bands`; the skimmer will
not start otherwise, nor without the program an option asks for.

```
./ubersdr-skimmer --url http://receiver:8080 --bands 20,40 --ft8 20,40
./ubersdr-skimmer --url http://receiver:8080 --bands all --ft8 all --ft4 20,40 --ft2 20 --ft8-depth deep --pskreporter
./ubersdr-skimmer --url http://receiver:8080 --bands 20,40 --wspr 20,40
./ubersdr-skimmer --url http://receiver:8080 --bands all --wspr --wspr-modes all --wsprnet
./ubersdr-skimmer --url http://receiver:8080 --bands 20,475 --wspr 20,630 --wsprd /opt/wsjtx/bin/wsprd
```

FT8, FT4 and FT2 go to PSK Reporter with `--pskreporter` and, FT8's and
FT4's CQs and roger reports, to RBN with `--rbn`. WSPR and FST4W go to
wsprnet.org with `--wsprnet` and to PSK Reporter with `--pskreporter`, never
to RBN, and only for calls cty.dat knows (the rest are shown, and listed in
Analytics' WSPR section, but not sent). 2200 and 630 m WSPR need their band named in `--bands` (`2200`,
`630`), 22 and 8 m a stream given by its centre (`13.5551`, `40.6812`, in
MHz), and are not among `--wspr all`'s. Every option is below.

### JS8

```
./ubersdr-skimmer --url http://receiver:8080 --bands 20,40 --js8 20,40
./ubersdr-skimmer --url http://receiver:8080 --bands all --js8 --pskreporter
```

Each band asked for must be among `--bands` (with no list, every band of
`--bands` with a JS8 dial: 1.842, 3.578, 7.078, 10.130, 14.078, 18.104,
21.078, 24.922, 28.078 and 50.318 MHz), its streams covering the dial and the
3.2 kHz above it. Normal, Fast, Turbo and Slow are decoded at once (not
Ultra), the frames put together into messages as JS8Call puts them together,
and the calls JS8Call would report go to PSK Reporter with `--pskreporter`,
with the grids they gave; never to RBN or telnet. The web page's JS8 tab has
a panel a band: its band activity, a row an audio offset with the text heard
there as it comes (kept 10 minutes after its last frame), beside its
messages, one a line, newest first, the sender marked, with its country and
distance. The decoder takes 3 to 8 s to make at the start and about 54 MB,
shared by every band.

## Every option

<!-- options -->
Every option, as `--help` gives them (generated from the program's own text by `scripts/readme-options.py`).
Windows only: `--driver`, `--cwsl-blocks`, `--cwsl-suffix`, `--cwsl`.

```
usage:
  ubersdr-skimmer --url URL --freq HZ [--call CALL] [options] live, from an UberSDR receiver
  ubersdr-skimmer --driver DLL --bands LIST [--driver DLL --bands LIST ...] [options]
                                                     live, from radios
  ubersdr-skimmer --hpsdr IP --bands LIST [--hpsdr IP --bands LIST ...] [options]
                                                     live, from HPSDR radios
  ubersdr-skimmer --ka9q STATUS --bands LIST [options]
                                                     live, from ka9q-radio's radiod
  ubersdr-skimmer --input FILE --rate HZ --freq HZ [options]  offline, from raw IQ

input:
  --url URL          receiver, e.g. http://44.31.241.13:8080
  --password PW      receiver password, if it has one
  --mode MODE        iq48, iq96 (default), iq192, iq384
  --margin DB        reduced-depth stream, 10-60 dB under the noise (default
                     15); 0 asks for the lossless stream
  --insecure         do not verify the receiver's TLS certificate
  --no-gap-fill      put no silence where the receiver's packets went missing.
                     By default lost packets, found by their timestamps, are
                     made up with as much silence, so the decoders keep time
                     (WSPR's periods, FT8's cycles)
  --freq HZ          centre frequency, Hz
  --bands LIST       live: several bands at once, e.g. 40,30,20, or all:
                     160-6 m as CW Skimmer Server skims them (with 60 m,
                     the beacon frequencies and 10 m and 6 m beacon
                     segments), less what the receiver cannot tune (its
                     /api/description range). A band wider than one stream
                     gets two. A number is a centre in kHz: 20,14100 adds a
                     stream at 14.100. Where two streams overlap, each
                     skims the half nearer its centre. 2200 and 630 (2200 m,
                     630 m) are never in all and never skimmed, CW or RTTY:
                     named, a stream each covers the whole band, for its
                     WSPR and FST4W (--wspr) and the RF tab
  --centre-streams   centre each band's streams on what they skim. By default
                     an UberSDR's and radiod's start 2 kHz below the band,
                     the rest of their width above it, for RTTY and the
                     digital modes there (an HPSDR radio's or a driver's are
                     centred unless --low-streams follows it: their filters
                     droop at the edges)
  --low-streams      after an --hpsdr or --driver: its streams placed as an
                     UberSDR's are, 2 kHz below each band and the rest above,
                     the bottom of the band near the edge of its passband
  --driver DLL       a radio, through its CW Skimmer Server driver
                     (Qs1rIntf.dll, HermesIntf.dll, ...: the DLL CWSL_Tee.cfg
                     names), as Skimmer Server drives it: one receiver per
                     band of --bands (or the one of --freq), as many as the
                     radio has. --bands, --freq, --mode and the --cwsl
                     options after a --driver are that radio's; --mode is
                     iq48, iq96 or iq192. Repeat it for another radio (no
                     band on two radios), each in a directory of its own with
                     its driver's settings, as one Skimmer Server per radio.
                     As CWSL_Tee, every receiver's IQ is shared for
                     CWSL_File, CWSL_Wave, Extio_CWSL, a Skimmer Server with
                     CWSL_Tee, ...: in CWSL0Band, CWSL1Band, ... for the
                     first radio, CWSL0Band2, ... for the second (as
                     CWSL_Tee2.dll)
  --cwsl-blocks N    each receiver's CWSL memory, in blocks of 1/93.75 s
                     (default 64, as CWSL_Tee.cfg's second line); 0 shares
                     nothing. Before any radio, every radio's
  --cwsl-suffix S    the CWSL names' suffix, CWSL0BandS (default: none for
                     the first radio, its number for the others)
  --hpsdr-discover   list the HPSDR radios that answer a discovery broadcast
                     on this host's networks (IP, MAC, device, protocols,
                     gateware, receivers, state), and exit
  --hpsdr IP         an HPSDR radio on the network (Hermes Lite 2, Hermes,
                     Angelia, Orion, ANAN, Red Pitaya, UberSDR's HPSDR
                     bridge...), by its address, name or MAC (looked up by
                     broadcast, as --hpsdr-discover), driven as CW Skimmer
                     Server's HermesIntf drives it: protocol 1 or 2,
                     whichever it answers (2 if both), one receiver per band
                     of --bands (or the one of --freq), as many as it says it
                     has (too few, 10 m is cut, least useful part first; 6 m
                     is left out). --bands, --freq, --mode (iq48, iq96,
                     iq192, iq384) and the --hpsdr options after an --hpsdr
                     are that radio's; repeat it for another radio, with
                     bands of its own (no band on two radios). Not with
                     --url, --input or --driver. A receiver to spare (one
                     more than its bands take), with --web: a Radio tab of
                     its own on the page, a WebSDR of it for one page at a
                     time (--radio-password, --no-radio)
  --hpsdr-protocol N the radio's protocol, 1 or 2 (default: as it answers)
  --hpsdr-att DB     its step attenuator, 0-31 dB (default: HermesIntf's
                     AGC on a Hermes, ANAN-10E, Angelia, Orion, Orion2 or
                     Saturn, 1 dB more for each ADC overload, 1 dB less
                     after 10 s without one)
  --cwsl             after an --hpsdr: its IQ shared in CWSL's memories too,
                     as CWSL_Tee beside HermesIntf shares it (and as a
                     --driver's always is), for CWSL_DIGI, CWSL_File,
                     Extio_CWSL, a Skimmer Server with CWSL_Tee, ...; iq48,
                     iq96 or iq192. --cwsl-blocks or --cwsl-suffix after an
                     --hpsdr say it too
  --ka9q STATUS      a ka9q-radio radiod: its status group, as its config's
                     [global] status = says (often hf-status.local),
                     or that group's address. One IQ channel is made on it
                     per band of --bands (or the one of --freq), beside the
                     channels it has, and closed as the skimmer stops (or
                     10 s after it dies); bands beyond its front end are
                     left out. On this host by default, whatever radiod's
                     ttl. --bands, --freq, --mode (iq48, iq96, iq192,
                     iq384) and the --ka9q options after a --ka9q are that
                     radiod's; repeat it for another. Not with --url,
                     --input, --driver or --hpsdr
  --ka9q-iface IF    the interface radiod is reached on, a name (Linux) or
                     its address, for a radiod on another host (its ttl
                     above 0)
  --ka9q-data NAME   the channels' data group (default: one of this run's
                     own, skimmer-XXXXXXXX-pcm.local)
  --ka9q-encoding E  f32 (default) or s16
  --ka9q-agc on|off  radiod's AGC on each channel (default on, as its iq
                     preset runs it)
  --ka9q-gain DB     a fixed gain instead, -100 to 100 dB; the AGC off
  --ka9q-agc-hang S  the AGC's hang time, s (default: the preset's, 1.1)
  --ka9q-agc-recovery DB
                     how fast it brings the gain back, dB/s (default: the
                     preset's, 20)
  --ka9q-headroom DB how far under full scale it keeps the peaks, dB
                     (default: radiod's)
  --ka9q-agc-threshold DB
                     its threshold, dB (default: radiod's)
  --input FILE       raw interleaved IQ ('-' for stdin)
  --format F         cf32 (default) or cs16, for --input
  --rate HZ          sample rate, for --input
  --record FILE      also write the live IQ to FILE as cf32
  --duration S       stop after S seconds of IQ

spots:
  --call CALL        your callsign; spots are sent as CALL-#. Live, the
                     receiver's own skimmer call (cw_skimmer_callsign in its
                     /api/description, else its callsign) by default
  --validation V     relaxed, normal (default) or strict
  --no-de            CQ spots only; no DE spots
  --no-heard         no spots of calls heard outside CQ or DE (callers, the
                     other side of a QSO), which go out with the type blank
  --squelch DB       minimum SNR to spot (default 0)
  --respot MIN       spot the same station again only after MIN minutes,
                     unless it moves 1 kHz or more (default 10, as CW
                     Skimmer Server)
  --spot-hold MIN    never send a call again in the same mode within 1 kHz
                     for MIN minutes, whatever spotted it (two streams on one
                     signal), unless as a CQ after a DE or blank spot, or a
                     DE after a blank one; 0 for no hold (default 5)
  --freq-calibration F
                     multiply every spot's frequency by F, as Skimmer Server's
                     FreqCalibration (default 1). F is a factor (1.000000468)
                     or ppm (+0.5ppm, the same). To take SM7IUN's suggestion
                     (sm7iun.se, the web page's RBN tab), multiply this
                     by its correction factor; it shows from the second day on.
                     After an --hpsdr, --ka9q or --driver: that radio's alone,
                     the one before any radio the others'
  --all-bands        skim the whole window, CW sub-band or not (2200 m and
                     630 m still never)
  --max-tracks N     stations each stream can read at once, 128-2048
                     (default 256 per 96 kHz of stream: 128 at iq48, 1024 at
                     iq384); a signal found with every track taken is not
                     read, and the log says so
  --no-cw            skim no CW: no CW signal is tracked or read, so no CW
                     spot is made (telnet, RBN, PSK Reporter, the web page).
                     The streams still run for everything else: RTTY, JTTY,
                     FT, WSPR and JS8, the spectrum, the RF tab and
                     listening. Saves the CPU CW reading takes
  --skim-digital     skim the digital modes' windows too (FT8, FT4, FT2, WSPR
                     and JS8: each dial frequency and 3 kHz above it), which
                     are left out by default: a CW decoder reads only busts
                     there
  --no-noise-filter  track signals in speech, data and noise too. By
                     default, spans of a CW segment found to be speech, data
                     or noise (SSB, a data mode, a swept carrier) start no
                     tracks on signals there that are not CW, and end those
                     that are not keyed, have no steady carrier and read no
                     callsign; the web page shows the spans
  --no-rtty-filter   track signals on RTTY too. By default two-tone FSK (the
                     170, 200, 425, 450 and 850 Hz shifts) is found anywhere
                     in the window but the digital modes' windows, and held
                     for 20 s at least: no track
                     starts on it or its sidebands, and those there end; the
                     web page shows it with its shift
  --no-rtty          decode no RTTY. By default every 45.45 baud, 170 Hz
                     signal the RTTY filter finds is decoded, from a few
                     seconds before it was found, and its text shown live on
                     the web page's RTTY tab; its calls are spotted as CW's
                     are (validation, squelch, respotting), within the
                     amateur bands less the digital windows: at the mark, as
                     RTTY Skimmer Server on the telnet port after CW's, to
                     RBN as its RTTY secondary and to PSK Reporter as RTTY.
                     Off with --no-rtty-filter too
  --max-rtty N       RTTY signals each band decodes at once, 1-1000 (default
                     100), shared by its streams; past it, new ones go
                     undecoded (logged, and the web page's RTTY bar full)
  --no-jtty          decode no JTTY. By default WSJT-X 3.2's JTTY is decoded
                     on its dials (7.090, 14.090, 21.090, 28.090 MHz) wherever
                     a stream covers one (streams take a dial in where that
                     costs no more of them) and shown live on the web page's
                     JTTY tab; CQ/DE callers spotted on the telnet port two
                     after --telnet's and to PSK Reporter, never RBN
  --jtty BANDS       JTTY on these bands' dials only (40,20,15,10 or all;
                     default all)
  --ft8 [BANDS]      decode FT8 on these bands' FT8 dials (20,40 or all;
                     default none) with WSJT-X's FT8 decoder built in (or
                     the jt9 program, --ft8-jt9); each must be
                     among --bands, or no start. With no list, every band of
                     --bands with an FT8 dial (one its streams still miss
                     left out, said). Each band's streams cover its dial and
                     0-3.2 kHz above it, whatever that costs. Every sender
                     heard goes to PSK Reporter
                     (--pskreporter), CQs and roger reports to RBN (--rbn) as
                     RBN Aggregator sends WSJT-X's, and each band's latest
                     cycle to the web page's FT8 tab
  --ft8-depth D      the decoding depth: fast, normal (default) or deep
  --ft8-threads N    FT8 decodes at once, every dial's together (1-64;
                     default half the cores, at least 2, at most 4); a cycle
                     waits its turn, dropped if not decoded in two cycles.
                     Built in only
  --ft8-jt9          FT8 by the jt9 program (--jt9), one running a dial, not
                     the built-in decoder (the default: jt9's decodes, on a
                     thread a dial, no program or shared memory)
  --ft4 [BANDS]      decode FT4 (7.5 s cycles) on these bands' FT4 dials, as
                     --ft8 does FT8, with WSJT-X's FT4 decoder built in (or
                     the jt9 program, --ft4-jt9), to PSK Reporter, RBN and an
                     FT4 tab
  --ft4-depth D      as --ft8-depth, for FT4
  --ft4-threads N    as --ft8-threads, for FT4
  --ft4-jt9          FT4 by the jt9 program (--jt9), as --ft8-jt9 for FT8
  --ft2 [BANDS]      decode FT2 (3.75 s cycles) on these bands' FT2 dials, as
                     --ft8 does FT8, with WSJT-X improved's FT2 decoder built
                     in (or the jt9 program, --ft2-jt9), to PSK Reporter and
                     an FT2 tab; never to RBN, as RBN Aggregator takes no FT2
  --ft2-depth D      as --ft8-depth, for FT2
  --ft2-threads N    as --ft8-threads, for FT2
  --ft2-jt9          FT2 by the jt9 program (--jt9), as --ft8-jt9 for FT8;
                     it must be WSJT-X improved's (WSJT-X's own has no FT2)
  --js8 [BANDS]      decode JS8 (Normal, Fast, Turbo and Slow at once) on
                     these bands' JS8 dials (1.842, 3.578, 7.078, 10.130,
                     14.078 MHz and up; 20,40 or all; default none; with no
                     list, every band of --bands with a JS8 dial), each
                     band's streams covering its dial and 0-3.2 kHz above it.
                     Frames are put together into messages, and the calls
                     heard go to PSK Reporter (--pskreporter) with their
                     grids; the web page's JS8 tab shows each band's
                     activity and messages. Never to RBN or telnet
  --wspr [BANDS]     decode WSPR and FST4W on these bands' WSPR dials (20,40,
                     80eu, all: every dial but 22 and 8 m's, by name only;
                     default none; with no list, every band of
                     --bands with a WSPR dial). 80 is 80 m's dials both,
                     60 60 m's, the second (80eu, 60eu) when the band's
                     streams hold it, else left out, said. Each whole
                     transmission period cut by the clock and decoded by
                     WSJT-X's decoders built in: wsprd's (or --wsprd), and
                     jt9's FST4W (or --fst4w-jt9); each band's streams
                     cover its dial and
                     0-2.4 kHz above it (22 and 8 m: give a stream's centre
                     in --bands, e.g. 13.5551 or 40.6812, in MHz). Spots to
                     the web page's WSPR tab, PSK
                     Reporter (with a locator), and wsprnet.org with
                     --wsprnet
  --wspr-modes M     the modes decoded: W2 (WSPR), W15 (WSPR-15), F2, F5, F15,
                     F30 (FST4W-120 to -1800), or all; default W2,F2,F5 (the
                     15 and 30 minute modes asked for), but on 2200 and 630
                     W2,F2,F5,F15,F30. A band's own after a space or ';',
                     "W2,F2,F5 2200:F15,F30 630:all": a band named takes its
                     own, the list without a band every other (2200 and 630
                     too: their own default stands only without one); 80eu
                     and 60eu take 80's and 60's unless named. Each band
                     keeps only the band the decoders read (1500 Hz +- 375
                     above the dial), its longest mode's period: all modes,
                     about 11 MB a band
  --wspr-depth D     wsprd's and jt9's depth: fast, normal or deep (default):
                     wsprd -qB, -C 500 -o 4, -C 500 -o 4 -d
  --wspr-noise-cal DB
                     each WSPR band's noise is measured every 2 minutes (RMS
                     over the quiet seconds before and after the
                     transmissions, and FFT over the quietest three tenths
                     of the period's bins), as a density, dBFS/Hz: at the
                     receiver's input where it says its level (UberSDR,
                     ka9q; an HPSDR radio's attenuator taken out), else of
                     its IQ. DB, measured for your receiver, is added to make
                     it dBm/Hz: one for every band, or a band's own as
                     --wspr-modes gives them, "-130 20:-128.5"
  --wspr-threads N   WSPR decoders run at once (1-64; default half the
                     cores, at least 2, at most 4); a band and mode one at a
                     time
  --fst4w-threads N  FST4W decoders run at once, a pool apart from WSPR's
                     (1-64; default half the cores, at least 2, at most 4);
                     a band and mode one at a time, FST4W-1800 one at a
                     time (about 0.5 GB built in, 1.1 GB with jt9), a band's
                     FST4W modes one at a time built in
  --wsprd PATH       WSPR by a wsprd program, each period written as a WAV
                     file for it (/usr/bin/wsprd; on Windows
                     C:\WSJT\wsjtx\bin\wsprd.exe, where WSJT-X installs it),
                     not the built-in wsprd (the default: the same decodes,
                     in memory, no program or files)
  --fst4w-jt9        FST4W by the jt9 program (--jt9), each period written as
                     a WAV file for it, not the built-in FST4W decoder (the
                     default: jt9's decodes, in memory, no program or files;
                     a band's FST4W modes share one hash table, so a call
                     heard in one resolves its hashed messages in all)
  --fst4w-spread S   the built-in FST4W decoder's spread (the signal's
                     width, w50): fast (default: within 0.0001 Hz of jt9's,
                     several times cheaper), exact (jt9's to the bit) or off
                     (none measured)
  --wsprd-args ARGS  wsprd's flags in place of --wspr-depth's, built in or
                     not, "-C 500 -o 3 -d" (see wsprd's own usage); not -a,
                     -c, -0 or a file, nor -f or -m (each band's dial and
                     mode's)
  --wsprnet          upload WSPR and FST4W spots to wsprnet.org in MEPT
                     uploads (one a cycle, one spot a call a band, our
                     own call and calls cty.dat does not know left out), as
                     --wsprnet-call at the station's
                     locator; spots wait in /dev/shm (on Windows the
                     temporary directory) until wsprnet says it took them.
                     The WSPRnet tab also shows wspr.live's ranking of
                     every reporter (yesterday, the last 24 hours, today),
                     fetched from db1.wspr.live a minute after start and hourly
  --wsprnet-call CALL
                     the call uploaded as to wsprnet (default --call)
  --wsprnet-server URL
                     where uploads go (default http://wsprnet.org/meptspots.php)
  --jt9 PATH         the jt9 program FT8, FT4, FT2 and FST4W are decoded by
                     with --ft8-jt9, --ft4-jt9, --ft2-jt9, --fst4w-jt9
                     (default /usr/bin/jt9; on Windows
                     C:\WSJT\wsjtx\bin\jt9.exe)
  --no-preroll       a new track reads from when it was found, as before:
                     by default it reads the start of the mark that found it
                     too, which a caller's first element otherwise is lost to
                     (EZ2FOS for IZ2FOS)
  --static-filter MODE  what static crashes (lightning far off, lifting the
                     whole band for a few ms, several times a second) may do:
                     full (default): no track starts, and none is kept
                     running, on a signal over the threshold only because a
                     crash lifted the band; starts: none starts so, but
                     running tracks are kept by them; off: tracked as any
                     signal. The web page shows how often they come
  --cty FILE         cty.dat (default: live, the one fetched from AD1C's
                     country files at start and weekly, else the one found
                     beside the program, else the one built in)
  --scp FILE         MASTER.SCP (default: live, the one fetched from Super
                     Check Partial at start and daily, else the one found
                     beside the program, else the one built in)
  --no-fetch         live, do not fetch cty.dat, MASTER.SCP,
                     cluster-cw-calls.txt, bcn.csv or patt3ch.lst (nor the
                     RBN reporter); use the ones beside the program, else the
                     ones built in (the latest there were at the build)
  --version          print the version and exit
  --clear-cache      first empty ~/.cache/ubersdr-skimmer (the fetched lists
                     and FFTW wisdom; the RBN fingerprint is kept), so all
                     is fetched and learned afresh

output:
  --compare          live: hold each spot on stdout until RBN has had time to
                     hear the station (up to 3 minutes), then print it with
                     what RBN made of it: "RBN:match" (heard on exactly our
                     frequency, at about our speed), "freq" (heard nearby,
                     not on our frequency), "wpm" (another speed),
                     "elsewhere" (heard, but not within 3 kHz), or "none";
                     their commonest frequency, median speed and how many
                     skimmers; and "other:CALL" when RBN heard another call
                     on our frequency. Telnet spots are not held or changed
  --rbn HOST:PORT    the RBN node for --compare (default
                     telnet.reversebeacon.net:7000)
  --name NAME        the operator, as the telnet sign-on and RBN show it
                     (default: the receiver's callsign)
  --qth TEXT         the location (default: the receiver's)
  --locator GRID     6-character locator (default: the receiver's)
  --rbn              report spots to the Reverse Beacon Network, as RBN
                     Aggregator v6.7 does (see docs/rbn-protocol); live only
  --rbn-dry-run      sign on to RBN and judge spots, but upload none
  --rbn-call CALL    the call RBN knows this skimmer by, its spots as
                     CALL-# (default --call)
  --no-patt3ch       with --rbn, also send calls that fit no shape in RBN's
                     patt3ch.lst (with QRZ lookups, a call QRZ knows is sent
                     regardless)
  --rbn-bad-calls [FILE]
                     with --rbn, send no spot of a call in FILE (default
                     BadCalls.txt), one call a line, as RBN Aggregator's
                     "Not in BadCalls.txt"; read again when it changes
  --wsjtx PORT[:CAL] with --rbn, also spot FT8/FT4 CQs from WSJT-X on this UDP
                     port (calibration factor CAL, default 1); repeatable
  --agg-telnet PORT  with --rbn, the reporter's local-user telnet port (as
                     Aggregator's 7550: the spots sent to RBN, sh/dx)
  --wsjtx-out HOST:PORT
                     send the FT8, FT4, FT2, WSPR and FST4W decodes on as
                     WSJT-X sends its own to its UDP server, for GridTracker,
                     JTAlert and the like (WSJT-X's port is 2237; a
                     multicast group too; IPv6 as [ADDRESS]:PORT):
                     Heartbeat, Status around each dial's decodes, Decode,
                     WSPRDecode. JTTY's, JS8's, CW's and RTTY's are not
                     sent: WSJT-X sends none. Off by default
  --wsjtx-out-id ID  the instance's Id there (default "UberSDR Skimmer")
  --wsjtx-out-ttl N  a multicast group's TTL (default 1, as WSJT-X)
  --pskreporter      report spots to PSK Reporter (pskreporter.info) as
                     UberSDR reports its CW Skimmer's: every spot, as CW, at
                     most once a call and band in 2 minutes, in a packet every
                     18-38 s; as --psk-call, at the station's locator. Off
                     by default; live only
  --psk-call CALL    the call reported as to PSK Reporter (default --call)
  --pskreporter-antenna TEXT
                     the antenna, as PSK Reporter shows it (default none)
  --pskreporter-server HOST:PORT
                     where the packets go (default report.pskreporter.info:4739;
                     port 14739 there analyses them instead, at
                     pskreporter.info/cgi-bin/psk-analysis.pl)
  --qrz-user USER --qrz-password PASS
                     look up each call spotted at QRZ.com (an XML Data
                     subscription): its position for the page's map, and
                     the grid square for PSK Reporter's spots. Off unless
                     both are given and the login at startup succeeds.
                     With --url the calls are asked of the UberSDR instead
                     (its /api/lookup, QRZ.com with the UberSDR's own login),
                     these needed only if it serves no lookups to this
                     skimmer: its lookup_services off, or this container
                     not in its lookup_services.trusted_containers
  --no-qrz           no lookups at all, not even the UberSDR's
  --qrz-validate     with QRZ lookups, spot only calls QRZ.com knows: a call
                     QRZ says it does not know is not spotted (asked again
                     after 24 h), and a spot waits up to 10 s for QRZ's
                     answer. Whenever QRZ cannot answer (down, an error, no
                     answer in time) the spot goes out as without it, and
                     the call is asked again at its next spot. Beacons are
                     not checked. Off by default
  --telnet PORT      DX-cluster telnet server (default 7300 when live, off for
                     --input); 0 turns it off. RTTY's spots on PORT+1, as
                     RTTY Skimmer Server; JTTY's on PORT+2
  --json             spots as JSON lines on stdout instead of cluster lines
  --web PORT         a web page on this port (default 9101 when live, off for
                     --input; 0 turns it off) for watching it work: spots and
                     why each was spotted, every band's spectrum and noise
                     floor, the decoder's tracks and the calls the spotter
                     is weighing, the RBN reporter, the reference files and
                     the log, live. Read-only and open to anyone who can
                     reach the port
  --web-root DIR     serve the page from DIR (a built web/dist) instead of
                     the copy built in
  --radio-password PW
                     a Radio tab (a WebSDR for one page at a time: an
                     --hpsdr radio's spare receiver; a 192 kHz channel of
                     its own on a --ka9q radiod, or session on the --url
                     receiver, made while a page has the tab open) tuned
                     only by a page that gives this; anyone may still watch
                     its spectrum. Before any --hpsdr or --ka9q, every
                     radio's (and the receiver's); after one, that radio's.
                     Default: anyone may tune it
  --no-radio         no Radio tab: before any --hpsdr or --ka9q, for none of
                     them (nor the receiver); after one, for that radio
  --tracks           print every station's decoded text as it changes,
                     instead of spots (with --json, as JSON)

decoder:
  --debounce D       dits a key change must last; the default (-1) follows
                     each signal's level
  --narrow HZ        width of the filter on each station's carrier that its
                     second reading hears (default 0: follows its speed)
  --single           read each station from the transform's bin alone, not
                     also through the narrow filter: half the CPU, fewer
                     weak stations
  --no-beam          settle each mark and gap as it ends, rather than weighing
                     them against the sender's own timing and the words
                     likely to be sent: a quarter less CPU, fewer stations
                     copied
  --calls FILE       calls heard on the air and how often, "CALL<tab>N" a
                     line, that the decoder expects beside those in
                     MASTER.SCP (default: live, the one fetched from
                     ubersdr.org at start and weekly, else
                     cluster-cw-calls.txt beside MASTER.SCP, else the one
                     built in)
  --dc-guard         blank the window centre (only for hardware with a DC spike)
```
<!-- /options -->
