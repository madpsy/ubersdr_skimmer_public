# ubersdr_skimmer

A wideband CW skimmer addon for [UberSDR](https://ubersdr.org) receivers. It
takes one wide IQ stream per band straight from the receiver, finds every CW
signal in them and reads them all at once, then spots them as CW Skimmer
Server does: on a DX-cluster telnet port, and optionally to the Reverse
Beacon Network as RBN Aggregator does (on by default) and to PSK Reporter
(off by default). A live web page shows it at work.

> **WSJT-X improved, not WSJT-X.** FT8, FT4, FT2, WSPR and FST4W are decoded
> with WSJT-X's own programs (`jt9`, `wsprd`). Running the binaries yourself,
> install [WSJT-X improved](https://sourceforge.net/projects/wsjt-x-improved/),
> not the normal WSJT-X: only improved's `jt9` decodes FT2. The container
> already has the right version (WSJT-X improved 3.1.0's `jt9` and `wsprd`):
> nothing to install for the addon.

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
- **FT8, FT4 and FT2** (off by default; Linux): decoded on the bands asked
  for by WSJT-X's own `jt9`, each band's latest cycle on the web page's FT8,
  FT4 and FT2 tabs; senders to PSK Reporter and, for CQs and roger reports
  in FT8 and FT4, to RBN as RBN Aggregator sends them.
- **JS8** (off by default): decoded on the bands asked for (JS8Call's dials,
  7.078 MHz on 40 m), Normal, Fast, Turbo and Slow at once, its frames put
  together into messages as JS8Call does. The web page's JS8 tab shows each
  band's activity and messages; the calls heard go to PSK Reporter with their
  grids.
- **WSPR and FST4W** (off by default): every WSPR and FST4W mode
  decoded with WSJT-X's `wsprd` and `jt9`, shown on the web page's WSPR tab;
  uploaded to wsprnet.org, and to PSK Reporter.

The web page also has a **Radio** tab: a WebSDR of the receiver, on a 192 kHz
session of its own made only while a page has the tab open. Everyone with it
open sees its spectrum and waterfall; one listener at a time tunes it and
hears it (CW, USB, LSB, AM, synchronous AM, FM). Dragging the band moves it
under the dial without a break in the audio; the squelch, the meter and the
fixed gain go by the passband's noise, so they read alike on any receiver.
`RADIO: "false"` turns it off, `RADIO_PASSWORD` keeps tuning to those who know
it. The Resources tab's Sources section says what the receiver reports of
itself, and each stream's session.

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

| Variable | Default | |
|---|---|---|
| `UBERSDR_URL` | `http://ubersdr:8080` | the receiver |
| `UBERSDR_PASSWORD` | | the receiver's password, if it has one |
| `BANDS` | `all` | `all` is what CW Skimmer Server skims (160–6 m, 60 m, the beacon frequencies), less what the receiver cannot tune; or a list such as `40,30,20`. `2200` and `630` (2200 m, 630 m) are never in `all` and never skimmed, CW or RTTY: named (`all,2200,630`), each gets a stream for its WSPR and FST4W and the RF tab |
| `IQ_MODE` | `iq96` | `iq48`, `iq96`, `iq192` or `iq384`: the width of each stream |
| `MIN_MARGIN` | `15` | reduced-depth IQ, dB under the noise floor; `0` asks for lossless |
| `CALLSIGN` | the receiver's | spots go out as `CALLSIGN-#` (default: `cw_skimmer_callsign`, else the receiver's callsign) |
| `NAME`, `QTH`, `LOCATOR` | the receiver's | the station, for the telnet sign-on and RBN |
| `VALIDATION` | `normal` | `relaxed`, `normal` or `strict` |
| `RBN` | `true` | report spots to the Reverse Beacon Network (as RBN Aggregator does); `false` turns it off. RBN needs the station's locator: without one (the receiver publishes no GPS locator and `LOCATOR` is unset) the reporter does not start, the log says so, and the skimmer runs on without it |
| `RBN_DRY_RUN` | `false` | sign on to RBN and judge spots, but upload none |
| `RBN_CALL` | `CALLSIGN` | the call RBN knows the skimmer by, its spots as `RBN_CALL-#` |
| `WEB_PORT` | `6101` | the web page |
| `TELNET_PORT` | `7300` | DX-cluster telnet, in CW Skimmer Server's format, RTTY's spots on the next port (7301) in RTTY Skimmer Server's, JTTY's on 7302; `0` turns them all off |
| `AGG_TELNET_PORT` | | with `RBN`, the reporter's local-user telnet port (as Aggregator's 7550) |
| `PSKREPORTER` | `false` | `true` reports spots to [PSK Reporter](https://pskreporter.info), as UberSDR reports its CW skimmer's: as `CALLSIGN` at `LOCATOR`, each call at most once a band in 2 minutes. JTTY's calls go too, as JTTY. If UberSDR already uploads its CW spots to PSKReporter (with `cwskimmer.yaml` pointing here), leave this off, or each spot goes twice |
| `PSKREPORTER_CALL` | `CALLSIGN` | the call reported as to PSK Reporter |
| `PSKREPORTER_ANTENNA` | | the antenna, as PSK Reporter shows it |
| `QRZ_USER`, `QRZ_PASSWORD` | | a [QRZ.com](https://www.qrz.com) login with an XML Data subscription: each call spotted is looked up (10,000 kept, the least recently spotted forgotten first), placing it on the web page's Map tab and giving its grid square to PSK Reporter. Checked at startup: if QRZ refuses it, the log and the Map tab say so and the skimmer runs on without. Not needed as an addon: the calls are asked of UberSDR's own lookups (its `lookup_services`, with `skimmer` among its `trusted_containers`), these used only if UberSDR serves none. Commented out in the compose file: uncomment and set them |
| `QRZ_VALIDATE` | `false` | `true`, with QRZ lookups (UberSDR's, or `QRZ_USER` and `QRZ_PASSWORD`): spot only calls QRZ knows. A call QRZ does not know is not spotted (and asked again after a day); a spot waits up to 10 s for QRZ's answer. When QRZ cannot answer (down, an error, too slow) the spot goes out as without it, and the call is asked again at its next spot. Beacons are not checked |
| `FREQ_CALIBRATION` | `1` | every frequency is multiplied by it, as by CW Skimmer Server's `FreqCalibration`: a factor (`1.000000468`) or ppm (`+0.5ppm`). [SM7IUN](https://sm7iun.se/rbn/analytics/) measures each RBN skimmer's error daily; the web page's RBN tab shows this skimmer's and the factor to set. A change shows fully in SM7IUN's list from the second day after it |
| `NOISE_FILTER` | `true` | keep tracks off SSB, data, noise and swept carriers in the CW segments (shown tinted on the web page); `false` tracks them as any signal |
| `RTTY_FILTER` | `true` | find RTTY (two-tone FSK at the usual shifts) anywhere in the band but the digital modes' windows and keep tracks off it and its sidebands, which CW decoders otherwise read callsigns out of (shown tinted on the web page, with its shift). `false` tracks it as any signal, and decodes no RTTY |
| `RTTY` | `true` | decode the RTTY found (45.45 baud, 170 Hz; the web page's RTTY tab) and spot its calls by CW's rules: on telnet port 7301, to RBN as RTTY and, with `PSKREPORTER`, to PSK Reporter as RTTY. `false` decodes and spots none; the filter still keeps CW tracks off it |
| `MAX_RTTY` | `100` | RTTY signals each band decodes at once, shared by its streams (10 m has several); past it a new one goes undecoded (still kept clear of CW tracks), the log says so and the web page's RTTY bar shows it full |
| `JTTY` | `true` | decode WSJT-X 3.2's JTTY on its dials (7.090, 14.090, 21.090 and 28.090 MHz) wherever a stream covers one, shown live on the web page's JTTY tab; streams take a dial in where that costs no more of them. Its calls go to telnet port 7302 and PSK Reporter (with `PSKREPORTER`), never to RBN. `false` decodes none; a list of bands, e.g. `40,20,15`, decodes it on those dials only |
| `FT8`, `FT4`, `FT2` | | bands to decode each mode on, e.g. `20,40` or `all`, or `true` for every band of `BANDS` with the mode's dial (default none), with WSJT-X's `jt9`: senders to PSK Reporter (with `PSKREPORTER`) and FT8's and FT4's CQs to RBN; each mode's tab on the web page. Each band must be among `BANDS`. The image has WSJT-X improved 3.1.0's `jt9` |
| `FT8_DEPTH`, `FT4_DEPTH`, `FT2_DEPTH` | `normal` | jt9's depth: `fast`, `normal` or `deep` |
| `JT9` | `/usr/bin/jt9` | the jt9 program (the image's own, or one mounted in) |
| `JS8` | | bands to decode JS8 on, e.g. `20,40` or `all`, or `true` for every band of `BANDS` with a JS8 dial (default none): Normal, Fast, Turbo and Slow, the calls heard to PSK Reporter (with `PSKREPORTER`) with their grids, never RBN; the web page's JS8 tab. Each band must be among `BANDS`. Needs nothing in the container |
| `WSPR` | | bands to decode WSPR and FST4W on, e.g. `20,40,80eu` or `all`, or `true` for every band of `BANDS` with a WSPR dial (default none; `80` is both 80 m dials when the stream holds 80eu, `60` likewise), with WSJT-X's `wsprd` (and `jt9` for FST4W); the web page's WSPR tab. The image has WSJT-X improved 3.1.0's `wsprd` and `jt9` |
| `WSPR_MODES` | `W2,F2,F5`, and `W2,F2,F5,F15,F30` on 2200 m and 630 m | `W2` (WSPR), `W15` (WSPR-15), `F2`, `F5`, `F15`, `F30` (FST4W-120 to -1800) or `all`; a band's own after a space, e.g. `W2,F2,F5 2200:F15,F30 630:all`: a band named takes its own, the list without a band every other (2200 m and 630 m too). Each band keeps only the slice of audio the decoders read, about 11 MB a band with all |
| `WSPR_DEPTH` | `deep` | `fast`, `normal` or `deep` |
| `WSPR_NOISE_CAL` | | each band's noise is measured every 2 minutes in dBFS/Hz; dB added to make it dBm/Hz, measured for your receiver: one for every band (`-130`) or a band's own (`-130 20:-128.5`) |
| `WSPR_THREADS` | `4` | WSPR and FST4W decoders run at once (half the cores if fewer: 2 on a Pi 5); a band and mode one at a time, FST4W-1800 one at a time (jt9 takes about 1.1 GB for it) |
| `WSPRD` | `/usr/bin/wsprd` | the wsprd program (the image's own, or one mounted in) |
| `WSPRNET` | `false` | `true` uploads WSPR and FST4W spots to [wsprnet.org](https://wsprnet.org) as `CALLSIGN` at `LOCATOR`; spots wait in `/dev/shm` until wsprnet takes them. If UberSDR already uploads this receiver's WSPR, leave this off. The WSPRnet tab also shows [wspr.live](https://wspr.live)'s ranking of every reporter (yesterday, the last 24 hours, today), fetched a minute after start and hourly |
| `WSPRNET_CALL` | `CALLSIGN` | the call uploaded as to wsprnet |
| `STATIC_FILTER` | `full` | static crashes (lightning far off, lifting the whole band for a few ms several times a second): `full` starts no track, and keeps none running, on a signal over the threshold only because a crash lifted the band; `starts` starts none so but lets crashes keep running tracks; `off` tracks them as any signal. The web page shows how often they come (the noise floor drawn bolder, and the stream's "static" figure) |
| `RADIO` | `true` | the web page's Radio tab: a 192 kHz session of its own on the receiver, opened while a page has the tab open and closed 10 s after the last leaves. `false` turns it off |
| `RADIO_PASSWORD` | | the Radio tab tuned only by a page that gives this; anyone may still watch its spectrum. Unset: anyone may tune it |
| `EXTRA_ARGS` | | any other option (all of them under [Every option](#every-option)) |

Each band is its own session on the receiver. UberSDR's usual configuration
lets addons on its Docker network past the session limits; if yours does not,
set `UBERSDR_PASSWORD` to its bypass password.

The fetched reference lists (cty.dat, MASTER.SCP and RBN's), FFTW's wisdom and
the RBN reporter's state are kept in `~/ubersdr/skimmer/cache`.

## Ports

| Port | |
|---|---|
| 6101 | the web page; UberSDR proxies it at `/addon/skimmer/` |
| 7300 | DX-cluster telnet, `skimmer:7300` on the Docker network. Not published on the host; uncomment `ports:` in the compose file to publish it (the dxcluster addon may already use 7300 there) |
| 7301 | RTTY's spots, as RTTY Skimmer Server's telnet, `skimmer:7301`. Not published either |
| 7302 | JTTY's spots, in the same lines, `skimmer:7302`. Not published either |

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
| `dbm`, `spread_hz` | WSPR's power; FST4W's spread |
| `entity`, `continent` | the sender's country and continent, by cty.dat |
| `qrz` | QRZ's record of the call, when the skimmer has it: `call` (QRZ's, the home call), `name`, `city`, `county`, `state`, `country`, `grid`, `lat`, `lon`, `geoloc`, `license`, `qsl`, `lotw`, `eqsl`, `mqsl`, `dxcc`, `cq_zone`, `itu_zone`, `born`, `url`, `image`, `at` (when QRZ answered), and `home_only`, true when the call signs from elsewhere (`EA5/G4ABC`, `/MM`) so the place is its home station's |

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
it. Download it from
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
`--bands`, `--freq` and `--mode` options after an `--hpsdr` are that radio's.
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
`--mode` and `--cwsl-` options given after a `--driver` are that radio's:

```
ubersdr-skimmer-windows-x86_64.exe --call M9PSY ^
  --driver C:\Radios\HermesIntf_192.168.1.50.dll --mode iq192 --bands 160,80,40,30,20,17,15,12 ^
  --driver C:\Radios\HermesIntf_192.168.1.51.dll --bands 10
```

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

### FT8, FT4, FT2 and WSPR

These need WSJT-X's programs: `jt9` for FT8, FT4, FT2 and FST4W, `wsprd` for
WSPR (`apt install wsjtx` has both, in `/usr/bin`; on Windows, WSJT-X's
installer puts them in `C:\WSJT\wsjtx\bin`, where they are looked for). FT2
needs [WSJT-X improved](https://sourceforge.net/projects/wsjt-x-improved/)
(WSJT-X's own has no FT2); tested with 3.1.0 improved AL_PLUS on Linux and
Windows. Each band asked for must
be among `--bands`; the skimmer will not start otherwise, nor without the
program a mode needs.

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
to RBN. 2200, 630, 22 and 8 m WSPR need a stream given by its centre in
`--bands`, in kHz (`475` for 630 m). Every option is below.

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
                     by its correction factor; it shows from the second day on
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
                     default none) with WSJT-X's jt9 (--jt9); each must be
                     among --bands, or no start. With no list, every band of
                     --bands with an FT8 dial (one its streams still miss
                     left out, said). Each band's streams cover its dial and
                     0-3.2 kHz above it, whatever that costs. Every sender
                     heard goes to PSK Reporter
                     (--pskreporter), CQs and roger reports to RBN (--rbn) as
                     RBN Aggregator sends WSJT-X's, and each band's latest
                     cycle to the web page's FT8 tab
  --ft8-depth D      jt9's decoding depth: fast, normal (default) or deep
  --ft4 [BANDS]      decode FT4 (7.5 s cycles) on these bands' FT4 dials, as
                     --ft8 does FT8, to PSK Reporter, RBN and an FT4 tab
  --ft4-depth D      as --ft8-depth, for FT4
  --ft2 [BANDS]      decode FT2 (3.75 s cycles) on these bands' FT2 dials, as
                     --ft8 does FT8, to PSK Reporter and an FT2 tab; never
                     to RBN, as RBN Aggregator takes no FT2. Needs WSJT-X
                     improved's jt9 (WSJT-X's own has no FT2)
  --ft2-depth D      as --ft8-depth, for FT2
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
                     80eu, all; default none; with no list, every band of
                     --bands with a WSPR dial). 80 is 80 m's dials both,
                     60 60 m's, the second (80eu, 60eu) when the band's
                     streams hold it, else left out, said. Each whole
                     transmission period cut by the clock and given to WSJT-X's
                     wsprd or jt9 (--wsprd, --jt9); each band's streams cover
                     its dial and 0-2.4 kHz above it (22 and 8 m: give a
                     stream's centre in --bands). Spots to the web
                     page's WSPR tab, PSK Reporter (with a locator), and
                     wsprnet.org with --wsprnet
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
  --wspr-depth D     wsprd's and jt9's depth: fast, normal or deep (default)
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
  --wspr-threads N   WSPR and FST4W decoders run at once (1-64; default 4,
                     or half the cores if fewer); a band and mode one at a time,
                     FST4W-1800 one at a time (jt9 takes about 1.1 GB for it)
  --wsprd PATH       the wsprd program (default /usr/bin/wsprd; on Windows
                     C:\WSJT\wsjtx\bin\wsprd.exe, where WSJT-X installs it)
  --wsprnet          upload WSPR and FST4W spots to wsprnet.org in MEPT
                     uploads (one a cycle, one spot a call a band, our
                     own call left out), as --wsprnet-call at the station's
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
                     beside the program)
  --scp FILE         MASTER.SCP (default: live, the one fetched from Super
                     Check Partial at start and daily, else the one found
                     beside the program)
  --no-fetch         live, do not fetch cty.dat, MASTER.SCP or
                     cluster-cw-calls.txt; use the ones beside the program
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
  --wsjtx PORT[:CAL] with --rbn, also spot FT8/FT4 CQs from WSJT-X on this UDP
                     port (calibration factor CAL, default 1); repeatable
  --agg-telnet PORT  with --rbn, the reporter's local-user telnet port (as
                     Aggregator's 7550: the spots sent to RBN, sh/dx)
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
                     cluster-cw-calls.txt beside MASTER.SCP)
  --dc-guard         blank the window centre (only for hardware with a DC spike)
```
<!-- /options -->
