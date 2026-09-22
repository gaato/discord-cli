name = "gaato/discord-cli"

version = "0.1.2"

readme = "README.md"

repository = "https://github.com/gaato/discord-cli"

license = "Apache-2.0"

keywords = [ "discord", "cli", "skill", "agent" ]

description = "Discord REST CLI for coding agents: read guilds, channels and messages, send messages, and call raw routes with a bot token. Built on gaato/discord."

preferred_target = "wasm"

import {
  "gaato/discord@0.4.3",
  "moonbitlang/async@0.22.1",
  "moonbitlang/x@0.5.1",
}
