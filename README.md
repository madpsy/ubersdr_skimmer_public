# ubersdr_skimmer

A wideband CW skimmer addon for [UberSDR](https://ubersdr.org) receivers. It
takes one wide IQ stream per band straight from the receiver, finds every CW
signal in them and reads them all at once, then spots them as CW Skimmer
Server does: on a DX-cluster telnet port, and optionally to the Reverse
Beacon Network as RBN Aggregator does. A live web page shows it at work.

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
| `RBN` | `false` | `true` reports spots to the Reverse Beacon Network |
| `RBN_DRY_RUN` | `false` | sign on to RBN and judge spots, but upload none |
| `WEB_PORT` | `6101` | the web page |
| `TELNET_PORT` | `7300` | DX-cluster telnet, in CW Skimmer Server's format; `0` turns it off |
| `AGG_TELNET_PORT` | | with `RBN`, the reporter's local-user telnet port (as Aggregator's 7550) |
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
