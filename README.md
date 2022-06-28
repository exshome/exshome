# Exshome

[![CI](https://github.com/exshome/exshome/workflows/CI/badge.svg?branch=main)](https://github.com/exshome/exshome/actions/workflows/ci.yml?query=branch%3Amain)
[![codecov](https://codecov.io/gh/exshome/exshome/branch/main/graph/badge.svg?token=N0HBNURO8P)](https://codecov.io/gh/exshome/exshome)
[![Hex Package](https://img.shields.io/hexpm/v/exshome.svg?color=green)](https://hex.pm/packages/exshome)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/exshome)

DIY Elixir-based smart home.

## System dependencies
- [MPV](https://mpv.io/) - Exshome uses it as a player. You will not be able to play any track without it.

## Project goals
- Mobile-friendly
- Extensibility
- Test coverage
- Should support different Single Board Computers

## Getting started with development
- Install dependencies with `mix deps.get`
- Setup database `mix ecto.setup`
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`. Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Launching as a script
You can use `bin/exshome` to start an application. It is an executable Elixir script. It downloads Exshome and starts the application.

You can download the latest version here:
```
wget https://raw.githubusercontent.com/exshome/exshome/main/bin/exshome
chmod +x exshome
./exshome
```

This script supports these environment variables:
- `EXSHOME_VERSION` - Exshome version. You can get the latest available version [at hex.pm](https://hex.pm/packages/exshome)
- `EXSHOME_HOST` - Host to listnen on, default is "0.0.0.0".
- `EXSHOME_PORT` - Application port, default is "5000".
- `EXSHOME_ROOT` - Path where all application data resides, default is "${HOME}/.exshome".

## Caveats
- [UNIX domain socket length is limited to about 100 bytes](https://unix.stackexchange.com/questions/367008/why-is-socket-path-length-limited-to-a-hundred-chars). Application uses these sockets to communicate with MPV. It will not work if the path is larger.

## Applications

Exshome includes simple applications. Each application has own pages.

### Clock (ExshomeClock)
Simple clock.

### Player (ExshomePlayer)
Allows to play music. You can upload your files or add links to the remote resources.

### Automation (ExshomeAutomation)
It is early WIP. Responsible for automating workflows.

## Security considerations
Right now Exshome is designed to run in a home network, so it has no auth. It can be dangerous to open it for a whole Internet.
