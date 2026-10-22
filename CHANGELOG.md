# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed

- **The README has sections for running, output, tokens, host access and
  targets.** The README and the agent skill run `moonx gaato/discord-cli`
  without a version, which takes the latest release, and write shell
  examples for `sh`. Development notes moved out of the published README.
- The internal `Command` and `UsageError` types are private; they were never
  usable from outside the executable.

## [0.1.8] - 2026-10-22

- Built on `gaato/discord` 0.13.0 and MoonBit 0.10.16. `--version` prints
  the release's own version again.

## [0.1.7] - 2026-10-19

- Built on `gaato/discord` 0.12.1. `--version` wrongly printed 0.1.6.

## [0.1.6] - 2026-10-19

- Built on `gaato/discord` 0.11.0.

## [0.1.5] - 2026-10-16

- Built on `gaato/discord` 0.8.0.

## [0.1.4] - 2026-10-08

- Built on `gaato/discord` 0.7.0; argument errors print one `error:` prefix.

## [0.1.3] - 2026-09-29

- Built on `gaato/discord` 0.6.0, `moonbitlang/async` 0.22.4 and
  `moonbitlang/x` 0.5.5, and requires `gaato/http-async` 0.1.2.

## [0.1.2] - 2026-09-23

- Runs as Wasm on moonrun through `moonx`, with an optional moonrun policy.

## [0.1.1] - 2026-09-23

- Documents that the executable needs a native runner.

## [0.1.0] - 2026-09-22

- First release: the Discord REST command and its agent skill.

[Unreleased]: https://github.com/gaato/discord-cli/commits/main
