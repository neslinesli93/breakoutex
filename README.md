# Notes

Boilerplate taken from [here](https://github.com/chrismccord/phoenix_live_view_example)

# TODO
- [x] Lose game
- [ ] Win game
- [ ] Progressive ball acceleration
- [ ] CSS of the page
- [x] Use coordinates of the center of the ball?
- [x] Use coordinates of the center of the paddle?
- [ ] Refactor everything NOT to use integer matrix coordinates, and instead compute everything inside config file?
- [ ] Transfer the project on a fresh, clean mix one (just like the guy that made the board game)
- [ ] How to deploy?
- [ ] Article(s) or tutorial?

# Install

Clone the repo.

Start the container:
```bash
$ docker-compose run --service-ports app
```

Install elixir deps:
```bash
$ mix deps.get
```

Setup db:
```bash
$ mix ecto.create && mix ecto.migrate
```

Setup frontend assets:
```bash
$ cd assets && npm i
```

Start phoenix server:
```bash
$ mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
