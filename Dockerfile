FROM elixir:1.11.3-alpine

LABEL org.opencontainers.image.source=https://github.com/danepod/animover

WORKDIR /opt/ani_mover

# TODO: Use the prod environment
ENV MIX_ENV="dev" \
    JOB_FILE="/data/jobs.json"

COPY . .

# TODO: Package a release
RUN apk add --no-cache inotify-tools && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && mix compile

EXPOSE 4000

VOLUME [ "/data" ]

CMD ["iex", "-S", "mix", "phx.server"]
