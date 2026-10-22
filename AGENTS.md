# Development

- Use `moon` on PATH and the toolchain pinned by `moonbit-version`.
- The root is the only executable package. Keep CLI parsing in `cli.mbt`, REST execution in `commands.mbt`, and process/output handling in `main.mbt`.
- Wasm on moonrun is the default; native is also supported and needs a C toolchain. Do not claim browser, WASI, or wasm-gc support.
- Before handoff run the checks below. Review the generated `pkg.generated.mbti`; do not edit it by hand.
- Keep tests offline. Pass explicit argv and environment maps to argparse; use `@dhttp.Client::offline` to test REST dispatch, including success and 401 responses, without tokens or network.
- Inspect dependency APIs in `.mooncakes/gaato/discord/src/{http,model}/pkg.generated.mbti`. Do not modify `.mooncakes/`.
- Successful data commands print one JSON document on stdout. Help/version are text. Runtime errors exit 1; usage/input errors exit 2; stderr errors start with `error: `.
- Keep SKILL.md concise and directed at agents, and keep its examples and the README consistent with parser behavior. Write shell examples in both as `sh`, not fish: they are public documents that people and agents paste into whatever shell they use, so POSIX syntax is the one that works everywhere.
- Never commit secrets. Do not publish or operate VCS unless the user explicitly requests it. Sending Discord messages or running modifying REST calls requires the user's request.
- A release changes the version in `moon.mod` and the `version=` of the command in `cli.mbt` together, and turns `## [Unreleased]` in `CHANGELOG.md` into the version heading: `--version` prints the one in `cli.mbt`, and 0.1.7 shipped printing 0.1.6 because only `moon.mod` moved. The README and SKILL.md run `moonx gaato/discord-cli` without a version, which takes the latest release, so they do not change.

## Checks

Run `moon fmt`, then `scripts/gates.sh`. CI and the toolchain canary (`.github/workflows/`) run the same script, so the checks cannot drift between them; add a check there, not here. In CI it also fails when `moon info` changes a committed `pkg.generated.mbti`.

## Documentation

- `README.md` is for people visiting the module page: what the command does, how to run it, its output, and links. mooncakes.io renders it as the module page, so development notes such as these checks belong here, not there.
- The README is a plain file rather than a link to a compiled `overview.mbt.md`, unlike gaato's library modules: the root package is the executable, and moon warns that main packages will stop compiling `.mbt.md` files. `scripts/docs_audit.allow` records this exception.
- Links in published files are absolute URLs, because mooncakes.io serves them away from the repository. Files only the repository needs go in `.moonignore`, which also tells the docs audit that they are not published. SKILL.md stays published: skills.mooncakes.io reads it from the package.
- Run `moon run scripts/docs_audit.mbtx` after changing docs or declarations. `scripts/docs_audit.mbtx` is shared by every gaato MoonBit repository: copy it from gaato/discord.mbt rather than editing it here, and keep this repository's exceptions in `scripts/docs_audit.json` and `scripts/docs_audit.allow`.
- Record user-visible changes under `## [Unreleased]` in `CHANGELOG.md`; it is the history the README links to.
