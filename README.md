# gaato/discord-cli

A command-line tool for Discord's bot REST API, written for coding agents
and built on [`gaato/discord`](https://mooncakes.io/docs/gaato/discord). It
reads the bot's identity, guilds, channels, and messages, sends messages, and
calls any other REST route, printing JSON. It comes with an agent skill that
tells an agent how to use it.

> **Status**: unofficial; not affiliated with Discord.

## Install

Run the prebuilt Wasm executable with MoonBit's `moonx`, which downloads the
latest release and runs it on moonrun. No native compiler or Node is needed.

```sh
moonx gaato/discord-cli --help
```

## Run

Supply a bot token as `DISCORD_TOKEN` through your environment or secret
manager, then:

```sh
moonx gaato/discord-cli me
moonx gaato/discord-cli guilds
moonx gaato/discord-cli channels 123456789012345678
moonx gaato/discord-cli messages 234567890123456789 --limit 10
moonx gaato/discord-cli send 234567890123456789 'Hello'
moonx gaato/discord-cli api GET /users/@me
```

| Option | Applies to | Meaning |
| --- | --- | --- |
| `--token TOKEN` | All commands | Overrides `DISCORD_TOKEN`; prefer the environment to avoid exposing arguments |
| `--help`, `-h` | All commands | Usage text |
| `--version` | Root | Version text |
| `--limit N`, `-n N` | `messages CHANNEL_ID` | Positive 32-bit integer; default 50; paginates beyond 100 |
| `--before ID` / `--after ID` | `messages CHANNEL_ID` | Exclusive cursors; cannot combine |
| `--stdin` | `send CHANNEL_ID [text...]` | Read UTF-8 input, overriding text arguments |
| `--reply-to ID` | `send CHANNEL_ID [text...]` | Reply to a message |
| `--body JSON`, `-d JSON` | `api METHOD PATH` | JSON body; path relative to `/api/v10` |

IDs are unsigned 64-bit decimal strings. Messages are sorted newest first;
`--after` fetches forward from its cursor. `guilds` fetches every page.

## Output and exit codes

Each successful data command prints one pretty JSON document on stdout;
`--help` and `--version` print text. Errors go to stderr as `error: ...`.
The exit code is 0 for success and help, 1 for a Discord API, network, or
other runtime failure, and 2 for invalid arguments, a missing token, or an
empty message.

## Tokens and writes

`DISCORD_TOKEN` must be a bot token, and the bot needs the permissions for
what it reads or posts. `send` and modifying `api` calls act as the bot, so
an agent should run them only when the user asked.

## Restricted host access

An optional moonrun policy permits only the token and Discord HTTPS, and
denies filesystem access and process spawning. Save this as
`discord-policy.json`:

```json
{
  "env": { "from_host": ["DISCORD_TOKEN"] },
  "net": { "connect": ["discord.com:443"] }
}
```

```sh
moonx --experimental-policy discord-policy.json gaato/discord-cli me
```

Help works without a token. `--stdin` still reads standard input, and shell
redirection opens files outside Wasm. The policy flag is experimental.

## Targets

The executable runs on moonrun, which provides its networking; browser,
WASI, and wasm-gc runtimes are not supported. It also builds for native.

## Agent skill

The [skill](https://github.com/gaato/discord-cli/blob/main/SKILL.md) covers
each command's output fields, when to post, and how to handle rate limits.

## Links

- [Changelog](https://github.com/gaato/discord-cli/blob/main/CHANGELOG.md)
- [Repository](https://github.com/gaato/discord-cli)
- [`gaato/discord`](https://github.com/gaato/discord.mbt), the library it is built on

## License

Apache-2.0
