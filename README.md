# Notes

Boilerplate taken from [here](https://github.com/chrismccord/phoenix_live_view_example)

# TODO
- [x] Lose game
- [x] Win game
- [ ] Function to call in order to receive a new, updated ball instance
- [ ] Progressive ball acceleration
- [ ] CSS of the page
- [x] Use coordinates of the center of the ball?
- [x] Use coordinates of the center of the paddle?
- [ ] Refactor everything NOT to use integer matrix coordinates, and instead compute everything inside config file?
- [x] Transfer the project on a fresh, clean mix one (just like the guy that made the board game)
- [x] How to deploy?
- [ ] Article(s) or tutorial?

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
$ ./run.sh # alias of mix deps.get && mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
