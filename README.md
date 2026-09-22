# discord-cli

A native MoonBit CLI for Discord's bot REST API, with an agent skill in [SKILL.md](SKILL.md). Reads identity, guilds, channels and messages, sends messages, and supports custom REST routes.

## Run

This CLI requires a native C toolchain and Node on PATH (required by the Discord dependency's prebuild hook). `moonx` defaults to Wasm, so it requires an explicit native target:

```fish
# Supply DISCORD_TOKEN through your environment or secret manager.
moonx --target native gaato/discord-cli --help
moonx --target native gaato/discord-cli me
moonx --target native gaato/discord-cli guilds
moonx --target native gaato/discord-cli channels 123456789012345678
moonx --target native gaato/discord-cli messages 234567890123456789 --limit 10
moonx --target native gaato/discord-cli send 234567890123456789 'Hello'
moonx --target native gaato/discord-cli api GET /users/@me
```

`moonx --target native` is deprecated in current MoonBit toolchains. If it is unavailable, build and run from source:

```fish
ghq get gaato/discord-cli
cd ~/ghq/github.com/gaato/discord-cli
moon update
moon run --target native . -- --help
```

The module does not provide a prebuilt Wasm executable. Publishing to mooncakes does not by itself guarantee listing in the Wasm-oriented skills marketplace.

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

Use `moon` on PATH with the version pinned in `moonbit-version`. Dependencies are declared in `moon.mod`. Only native is supported because the pinned `moonbitlang/async` library has no wasm backend.

```fish
moon fmt
moon info
moon check --target native
moon test --target native
moon build --target native
moon run --target native . -- --help
```

Tests run offline, including simulated REST success and 401 responses. The root package is the only executable. Licensed under Apache-2.0.
