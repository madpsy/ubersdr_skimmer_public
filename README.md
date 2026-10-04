# ubersdr_skimmer

A wideband CW skimmer addon for [UberSDR](https://ubersdr.org) receivers. It
takes one wide IQ stream per band straight from the receiver, finds every CW
signal in them and reads them all at once, then spots them as CW Skimmer
Server does: on a DX-cluster telnet port, and optionally to the Reverse
Beacon Network as RBN Aggregator does (on by default). A live web page shows it at work.

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
| `REGION` | `1` | IARU region, for the CW sub-bands |
| `RBN` | `true` | report spots to the Reverse Beacon Network (as RBN Aggregator does); `false` turns it off. RBN needs the station's locator: without one (the receiver publishes no GPS locator and `LOCATOR` is unset) the reporter does not start, the log says so, and the skimmer runs on without it |
| `RBN_DRY_RUN` | `false` | sign on to RBN and judge spots, but upload none |
| `WEB_PORT` | `6101` | the web page |
| `TELNET_PORT` | `7300` | DX-cluster telnet, in CW Skimmer Server's format; `0` turns it off |
| `AGG_TELNET_PORT` | | with `RBN`, the reporter's local-user telnet port (as Aggregator's 7550) |
| `NOISE_FILTER` | `true` | keep tracks off SSB, data, noise and swept carriers in the CW segments (shown tinted on the web page); `false` tracks them as any signal |
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

## On Windows, from a radio (CW Skimmer Server drivers and CWSL)

The skimmer also runs on Windows by itself, without UberSDR and without
Docker, from a radio driven through its CW Skimmer Server driver. It does
CWSL_Tee's job as well. Download `ubersdr-skimmer-windows-x86_64.exe` from
[Releases](https://github.com/madpsy/ubersdr_skimmer_public/releases/latest).
It is one file and needs nothing installed beside it. `--driver` is for
Windows only.

```
ubersdr-skimmer-windows-x86_64.exe --driver C:\Radios\HermesIntf.dll --mode iq192 --bands 160,80,40,30,20,17,15,12 --call M9PSY
```

- `--driver` is the radio's Skimmer Server driver: the DLL you would put in
  Skimmer Server's directory (`HermesIntf.dll`, `Qs1rIntf.dll`, ...). It is
  the one a `CWSL_Tee.cfg` names on its first line. Skimmer Server and
  CWSL_Tee.dll are not needed.
- Each band of `--bands` takes one of the radio's receivers. The skimmer
  asks for no more than the radio has; if the bands need more, it says so.
- `--mode` is `iq48`, `iq96` (default) or `iq192`.
- Give `--call`, and for RBN `--name`, `--qth` and `--locator`: there is no
  receiver to take them from.
- Spots go to telnet port 7300, and the web page is at
  `http://localhost:9101/`.

**HermesIntf** ([k3it/HermesIntf](https://github.com/k3it/HermesIntf/releases))
drives OpenHPSDR radios: Hermes, Hermes Lite 2, ANAN, Red Pitaya and others.
It takes the first radio that answers. To pin it to one radio, rename the DLL
with the radio's IP address or the last two bytes of its MAC address:
`HermesIntf_192.168.1.50.dll` or `HermesIntf_693c.dll`.

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
