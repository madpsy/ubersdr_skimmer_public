# ubersdr_skimmer

A wideband CW skimmer addon for [UberSDR](https://ubersdr.org) receivers. It
takes one wide IQ stream per band straight from the receiver, finds every CW
signal in them and reads them all at once, then spots them as CW Skimmer
Server does: on a DX-cluster telnet port, and optionally to the Reverse
Beacon Network as RBN Aggregator does (on by default) and to PSK Reporter
(off by default). A live web page shows it at work.

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
| `BANDS` | `all` | `all` is what CW Skimmer Server skims (160–6 m, 60 m, the beacon frequencies), less what the receiver cannot tune; or a list such as `40,30,20` |
| `IQ_MODE` | `iq96` | `iq48`, `iq96`, `iq192` or `iq384`: the width of each stream |
| `MIN_MARGIN` | `15` | reduced-depth IQ, dB under the noise floor; `0` asks for lossless |
| `CALLSIGN` | the receiver's | spots go out as `CALLSIGN-#` (default: `cw_skimmer_callsign`, else the receiver's callsign) |
| `NAME`, `QTH`, `LOCATOR` | the receiver's | the station, for the telnet sign-on and RBN |
| `VALIDATION` | `normal` | `relaxed`, `normal` or `strict` |
| `RBN` | `true` | report spots to the Reverse Beacon Network (as RBN Aggregator does); `false` turns it off. RBN needs the station's locator: without one (the receiver publishes no GPS locator and `LOCATOR` is unset) the reporter does not start, the log says so, and the skimmer runs on without it |
| `RBN_DRY_RUN` | `false` | sign on to RBN and judge spots, but upload none |
| `WEB_PORT` | `6101` | the web page |
| `TELNET_PORT` | `7300` | DX-cluster telnet, in CW Skimmer Server's format, and RTTY's spots on the next port (7301) in RTTY Skimmer Server's; `0` turns both off |
| `AGG_TELNET_PORT` | | with `RBN`, the reporter's local-user telnet port (as Aggregator's 7550) |
| `PSKREPORTER` | `false` | `true` reports spots to [PSK Reporter](https://pskreporter.info), as UberSDR reports its CW skimmer's: as `CALLSIGN` at `LOCATOR`, each call at most once a band in 2 minutes. Not in the compose file: add it under `environment:`. If UberSDR already uploads its CW spots to PSKReporter (with `cwskimmer.yaml` pointing here), leave this off, or each spot goes twice |
| `PSKREPORTER_ANTENNA` | | the antenna, as PSK Reporter shows it |
| `QRZ_USER`, `QRZ_PASSWORD` | | a [QRZ.com](https://www.qrz.com) login with an XML Data subscription: each call spotted is looked up (10,000 kept, the least recently spotted forgotten first), placing it on the web page's Map tab and giving its grid square to PSK Reporter. Checked at startup: if QRZ refuses it, the log and the Map tab say so and the skimmer runs on without. Not needed as an addon: the calls are asked of UberSDR's own lookups (its `lookup_services`, with `skimmer` among its `trusted_containers`), these used only if UberSDR serves none. Commented out in the compose file: uncomment and set them |
| `QRZ_VALIDATE` | `false` | `true`, with QRZ lookups (UberSDR's, or `QRZ_USER` and `QRZ_PASSWORD`): spot only calls QRZ knows. A call QRZ does not know is not spotted (and asked again after a day); a spot waits up to 10 s for QRZ's answer. When QRZ cannot answer (down, an error, too slow) the spot goes out as without it, and the call is asked again at its next spot. Beacons are not checked |
| `FREQ_CALIBRATION` | `1` | every frequency is multiplied by it, as by CW Skimmer Server's `FreqCalibration`: a factor (`1.000000468`) or ppm (`+0.5ppm`). [SM7IUN](https://sm7iun.se/rbn/analytics/) measures each RBN skimmer's error daily; the web page's Analytics tab shows this skimmer's and the factor to set. A change shows fully in SM7IUN's list from the second day after it |
| `NOISE_FILTER` | `true` | keep tracks off SSB, data, noise and swept carriers in the CW segments (shown tinted on the web page); `false` tracks them as any signal |
| `RTTY_FILTER` | `true` | find RTTY (two-tone FSK at the usual shifts) anywhere in the band but the digital modes' windows and keep tracks off it and its sidebands, which CW decoders otherwise read callsigns out of (shown tinted on the web page, with its shift). The RTTY found is decoded too (the web page's RTTY tab) and its calls spotted by CW's rules: on telnet port 7301, to RBN as RTTY and, with `PSKREPORTER`, to PSK Reporter as RTTY. `false` tracks it as any signal, and decodes no RTTY |
| `JTTY` | `true` | decode WSJT-X 3.2's JTTY on its dials (7.090, 14.090, 21.090 and 28.090 MHz) wherever a stream covers one, shown live on the web page's JTTY tab; streams take a dial in where that costs no more of them. Nothing is spotted. `false` decodes none |
| `STATIC_FILTER` | `full` | static crashes (lightning far off, lifting the whole band for a few ms several times a second): `full` starts no track, and keeps none running, on a signal over the threshold only because a crash lifted the band; `starts` starts none so but lets crashes keep running tracks; `off` tracks them as any signal. The web page shows how often they come (the noise floor drawn bolder, and the stream's "static" figure) |
| `EXTRA_ARGS` | | any other option; `docker exec skimmer ubersdr-skimmer --help` lists them |

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
| HPSDR radio | `--hpsdr IP` | Linux, Windows | Hermes Lite 2, Hermes, Angelia, Orion, ANAN, Red Pitaya, UberSDR's HPSDR bridge | one of the radio's receivers per band, iq48–iq384 | `--hpsdr 192.168.1.50 --mode iq192 --bands 80,40,30,20` |
| ka9q-radio | `--ka9q STATUS` | Linux (radiod's host, or the same LAN) | whatever radiod's front end is: RX888, Airspy, Airspy HF+, SDRplay, HackRF, RTL-SDR, FUNcube... | one radiod channel per band, iq48–iq384, made beside its others (wsprdaemon's...) | `--ka9q hf-status.local --bands all` |
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

### From an HPSDR radio on the network (`--hpsdr`, Linux and Windows)

An openHPSDR radio, spoken to directly at its IP address: Hermes Lite 2,
Hermes, Angelia, Orion, ANAN, Red Pitaya, or UberSDR's own HPSDR bridge. The
skimmer drives it as CW Skimmer Server's HermesIntf does, in protocol 1 or 2,
whichever the radio answers. Skimmer Server, its drivers and Docker are not
needed.

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

Several radios: give `--hpsdr` once per radio. The `--bands`, `--freq` and
`--mode` options after an `--hpsdr` are that radio's:

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
runs alongside wsprdaemon (or anything else using that radiod) without
disturbing it.

```
ubersdr-skimmer-linux-x86_64 --ka9q hf-status.local --bands all --call M9PSY
ubersdr-skimmer-linux-aarch64 --ka9q hf-status.local --bands 80,40,30,20 --mode iq192 --call M9PSY
ubersdr-skimmer-linux-x86_64 --ka9q hf-status.local --bands 40,20 --ka9q-gain 10 --call M9PSY
```

- `STATUS` is radiod's status group, as `status =` in its config's `[global]`
  section names it (wsprdaemon's is `hf-status.local`), or the group's
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
- radiod is taken to be on the same host, whatever its `ttl` (wsprdaemon sets
  `ttl = 0`, which keeps radiod's traffic on the loopback interface). For a
  radiod on another host, with its `ttl` above 0, give the interface it is
  reached on: `--ka9q-iface eth0`.
- The channels are closed when the skimmer stops. If it dies instead, radiod
  removes them itself within 10 s. If the IQ stops, the channels are made
  again.

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
`--hpsdr IP` does the same without the DLL, on Linux too. Use the DLL only
where the receivers' IQ must also be shared with CWSL tools, which only
`--driver` does.

**Several radios.** Give `--driver` once per radio. The `--bands`, `--freq`,
`--mode` and `--cwsl-` options given after a `--driver` are that radio's:

```
ubersdr-skimmer-windows-x86_64.exe --call M9PSY ^
  --driver C:\Radios\HermesIntf_192.168.1.50.dll --mode iq192 --bands 160,80,40,30,20,17,15,12 ^
  --driver C:\Radios\HermesIntf_192.168.1.51.dll --bands 10
```

### Sharing the IQ with CWSL tools

As [CWSL_Tee](https://github.com/HrochL/CWSL) does, every receiver's IQ is put
in shared memory. CWSL_File, CWSL_Wave, Extio_CWSL (for HDSDR and Winrad),
CWSL_Net, CWSL_USBWave and a Skimmer Server running CWSL_Tee can read it,
alongside the skimmer, as they would from Skimmer Server.

| | |
|---|---|
| Names | the first radio's receivers are `CWSL0Band`, `CWSL1Band`, ...; the second radio's `CWSL0Band2`, ... (the names `CWSL_Tee2.dll`, `CWSL_File2.exe` and `Extio_CWSL2.dll` use); the third's `CWSL0Band3`, ... |
| `--cwsl-suffix S` | after a `--driver`: that radio's names become `CWSL0BandS`, ... |
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
