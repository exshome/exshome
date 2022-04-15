# Exshome

[![CI](https://github.com/exshome/exshome/workflows/CI/badge.svg?branch=main)](https://github.com/exshome/exshome/actions/workflows/ci.yml?query=branch%3Amain)
[![codecov](https://codecov.io/gh/exshome/exshome/branch/main/graph/badge.svg?token=N0HBNURO8P)](https://codecov.io/gh/exshome/exshome)

DIY elixir-based smart home.

## Depends on
- [MPV](https://mpv.io/)

## Project goals
- Extensibility
- Test coverage
- Should support different Single Board Computers

## Getting started
- Install dependencies with `mix deps.get`
- Setup database `mix ecto.setup`
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`. Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Caveats
- [UNIX domain socket length is limited to about 100 bytes](https://unix.stackexchange.com/questions/367008/why-is-socket-path-length-limited-to-a-hundred-chars). Application uses these sockets to communicate with MPV. It will not work if the path is larger.
