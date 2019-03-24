FROM bitwalker/alpine-elixir-phoenix:latest

EXPOSE 4000
ENV PORT=4000 MIX_ENV=dev

ADD . /home/app
WORKDIR /home/app
