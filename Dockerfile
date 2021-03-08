FROM elixir:1.11.3-alpine

WORKDIR /opt/ani_mover

ENV MIX_ENV dev

COPY . .

RUN apk add --no-cache inotify-tools && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && mix compile

EXPOSE 4000

VOLUME [ "/data" ]

CMD ["iex", "-S", "mix", "phx.server"]
