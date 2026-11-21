# gaato/discord-cli

Use Discord's bot REST API from a shell. Read the bot's guilds, channels and
recent messages, send a message or a reply, or call any other REST route, and
get JSON you can pipe into another program. It is designed to be run by coding
agents as well as by people, and comes with an agent skill. It is built on
[`gaato/discord`](https://mooncakes.io/docs/gaato/discord).

Unofficial, and not affiliated with Discord.

[日本語](https://github.com/gaato/discord-cli/blob/main/README.ja.md)

## Install

Run the prebuilt Wasm executable with MoonBit's `moonx`, which downloads the
latest release and runs it on moonrun. No native compiler or Node.js is
needed. Help works without a token:

```sh
moonx gaato/discord-cli --help
```

## Run

Put a bot token in the `DISCORD_TOKEN` environment variable, then:

```sh
moonx gaato/discord-cli me
moonx gaato/discord-cli guilds
moonx gaato/discord-cli channels 123456789012345678
moonx gaato/discord-cli messages 234567890123456789 --limit 10
moonx gaato/discord-cli send 234567890123456789 'Hello'
moonx gaato/discord-cli api GET /users/@me
```

To post the output of another command as a reply:

```sh
printf '%s\n' 'Build complete.' | moonx gaato/discord-cli send 234567890123456789 --stdin --reply-to 345678901234567890
```

| Option | Applies to | Meaning |
| --- | --- | --- |
| `--token TOKEN` | All commands | Overrides `DISCORD_TOKEN`. Prefer the environment, so the token does not appear in process listings. |
| `--help`, `-h` | All commands | Usage text |
| `--version` | Root | Version text |
| `--limit N`, `-n N` | `messages CHANNEL_ID` | Default 50. Larger limits are paginated. |
| `--before ID` / `--after ID` | `messages CHANNEL_ID` | Exclusive cursors. Use one or the other. |
| `--stdin` | `send CHANNEL_ID [text...]` | Read the message from standard input (UTF-8) instead of the arguments |
| `--reply-to ID` | `send CHANNEL_ID [text...]` | Reply to a message |
| `--body JSON`, `-d JSON` | `api METHOD PATH` | JSON body. The path is relative to `/api/v10`. |

IDs are unsigned 64-bit decimal strings. Keep them as strings in scripts, since
many JSON tools lose precision on numbers that large. Messages are sorted newest
first. `guilds` fetches every page.

## Output and exit codes

Each successful data command prints one pretty-printed JSON document on stdout.
Errors go to stderr as `error: ...`.

| Exit code | Meaning |
| --- | --- |
| 0 | Success, or help |
| 1 | A Discord API, network or other runtime failure |
| 2 | Invalid arguments, a missing token, or an empty message |

So an empty list is distinguishable from a failed request.

## Tokens and writes

`DISCORD_TOKEN` must be a bot token, and the bot needs Discord permissions for
what it reads or posts. `send` and modifying `api` calls act as the bot, and
other people see the result.

## Restricted host access

An optional moonrun policy allows only the token and Discord over HTTPS, and
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

`--stdin` still reads standard input, and shell redirection opens files
outside Wasm. The policy flag is experimental in moonx.

## Targets

The executable runs on moonrun, which provides its networking. Browser, WASI
and wasm-gc runtimes are not supported. It also builds for native.

## Agent skill

The [skill](https://github.com/gaato/discord-cli/blob/main/SKILL.md) describes
each command's output fields, when posting is appropriate, and how to handle
rate limits.

## Links

- [Changelog](https://github.com/gaato/discord-cli/blob/main/CHANGELOG.md)
- [Repository](https://github.com/gaato/discord-cli)
- [`gaato/discord`](https://mooncakes.io/docs/gaato/discord), the library it is
  built on

## License

Apache-2.0
