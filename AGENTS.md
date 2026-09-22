# Development

- Use `moon` on PATH and the toolchain pinned by `moonbit-version`. Node must be on PATH for the Discord dependency's prebuild hook.
- The root is the only executable package. Keep CLI parsing in `cli.mbt`, REST execution in `commands.mbt`, and process/output handling in `main.mbt`.
- Only native is supported: the pinned `moonbitlang/async` has no wasm backend. Use `moon check --target native` (the native form of `moon check`), `moon test --target native`, and `moon build --target native`.
- Before handoff run `moon fmt`, `moon info`, then the check/test/build commands above. Review the generated `pkg.generated.mbti`; do not edit it by hand.
- Keep tests offline. Pass explicit argv and environment maps to argparse; use `@dhttp.Client::offline` to test REST dispatch without tokens or network.
- Inspect dependency APIs in `.mooncakes/gaato/discord/src/{http,model}/pkg.generated.mbti`. Do not modify `.mooncakes/`.
- Successful data commands print one JSON document on stdout. Help/version are text. Runtime errors exit 1; usage/input errors exit 2; stderr errors start with `error: `.
- Keep SKILL.md concise and directed at agents, and keep its examples and README.md consistent with parser behavior. Interactive examples use fish syntax.
- Never commit secrets. Do not publish or operate VCS unless the user explicitly requests it. Sending Discord messages or running modifying REST calls requires the user's request.
