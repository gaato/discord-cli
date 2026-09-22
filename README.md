# discord-cli

A MoonBit CLI for Discord's bot REST API, with an agent skill in [SKILL.md](SKILL.md). Reads identity, guilds, channels and messages, sends messages, and supports custom REST routes.

## Run

Run the prebuilt linear-memory Wasm executable with MoonBit's `moonx`. No native compiler or Node is needed to run the published executable.

```fish
# Supply DISCORD_TOKEN through your environment or secret manager.
moonx gaato/discord-cli@0.1.2 --help
moonx gaato/discord-cli@0.1.2 me
moonx gaato/discord-cli@0.1.2 guilds
moonx gaato/discord-cli@0.1.2 channels 123456789012345678
moonx gaato/discord-cli@0.1.2 messages 234567890123456789 --limit 10
moonx gaato/discord-cli@0.1.2 send 234567890123456789 'Hello'
moonx gaato/discord-cli@0.1.2 api GET /users/@me
```

`DISCORD_TOKEN` must be a bot token. Posting requires the user's explicit request and appropriate bot permissions. Each successful data command prints one pretty JSON document. Errors use stderr; exit codes are 0 (success/help), 1 (runtime/API failure), and 2 (usage/input/token missing).

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

IDs are unsigned 64-bit decimal strings. Messages are sorted newest first; `--after` fetches forward from its cursor. `guilds` fetches every page. See the skill for output fields, write guidance, and rate-limit handling.

## Develop

Use `moon` on PATH with the version pinned in `moonbit-version`. Source builds require Node for the Discord dependency's prebuild hook. Wasm is the default; native additionally requires a C toolchain. The hook does not download native libraries for Wasm.

```fish
moon fmt
moon info
moon check --target wasm --deny-warn
moon test --target wasm
moon build --target wasm --release
moon check --target native
moon test --target native
moon build --target native
moon run --target native . -- --help
```

Tests run offline, including simulated REST success and 401 responses. The root package is the only executable. Licensed under Apache-2.0.

## Restricted host access

Save this as `discord-policy.json` (also included in the repository):

```json
{
  "env": { "from_host": ["DISCORD_TOKEN"] },
  "net": { "connect": ["discord.com:443"] }
}
```

```fish
moonx --experimental-policy discord-policy.json gaato/discord-cli@0.1.2 me
```

This optional moonrun policy permits the token and Discord HTTPS, denies filesystem access and process spawning, and allows help without a token. `--stdin` still reads standard input; shell redirection opens files outside Wasm. The policy flag is experimental. This executable requires moonrun host networking; browser, WASI, and wasm-gc runtimes are not supported.
