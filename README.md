![Build status](https://github.com/neslinesli93/breakoutex/workflows/Build%20status/badge.svg)

A Breakoutex clone written in pure Elixir, using Phoenix LiveView. Can be played [here](https://breakoutex.tommasopifferi.com)

# Install

Clone the repo

```bash
$ git clone https://github.com/neslinesli93/breakoutex
```

Start the container:

```bash
$ docker-compose run --service-ports app
```

Install npm deps:

```bash
$ cd assets && npm i && cd ..
```

Start server:

```bash
$ ./run.sh # executes mix deps.get && mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

# Deploy

To build an image ready for production, run:

```bash
$ make build
```

This will build a new docker image, which can be pushed to some registry. If you want to test the production image locally, just run:

```bash
$ make run
```

And open `http://localhost:4000`. See `Makefile` for more info on the two command.

# Notes

Boilerplate taken from [here](https://github.com/chrismccord/phoenix_live_view_example)

# TODO

- [x] Lose game
- [x] Win game
- [ ] Function to call in order to receive a new, updated ball instance
- [ ] Progressive ball acceleration
- [x] CSS of the page
- [x] Use coordinates of the center of the ball?
- [x] Use coordinates of the center of the paddle?
- [x] Refactor everything NOT to use integer matrix coordinates, and instead compute everything inside config file?
- [x] Transfer the project on a fresh, clean mix one (just like the guy that made the board game)
- [x] How to deploy?
- [ ] Article(s) or tutorial?
- [ ] Instructions for deploying
