///|
/// Prints `text`, one line or more, on stderr and exits with `code`.
fn[T] exit_with(text : String, code~ : Int32) -> T {
  eprintln(text)
  @env.exit(code)
}

///|
fn[T] die(message : String, code~ : Int32) -> T {
  exit_with("error: " + message, code~)
}

///|
/// argparse parse failures are display-ready: they already start with
/// `error:` and carry the usage text, so they are printed as they are, less
/// the final newline that printing adds back.
fn argparse_failure_text(message : String) -> String {
  let text = if message.has_prefix("error:") {
    message
  } else {
    "error: " + message
  }
  match text.strip_suffix("\n") {
    Some(line) => line.to_owned()
    None => text
  }
}

///|
fn bot_token(matches : @argparse.Matches) -> String raise UsageError {
  match matches.values.get("token") {
    Some(values) if values.length() > 0 && values[0].trim() != "" => values[0]
    _ => raise UsageError("no bot token: set DISCORD_TOKEN or pass --token")
  }
}

///|
async fn main {
  let matches = build_cli().parse(env=@env.get_env_vars()) catch {
    err => exit_with(argparse_failure_text(err.to_string()), code=2)
  }
  try {
    let command = parse_command(matches)
    let token = bot_token(matches)
    let client = @dhttp.Client(token, max_connections=1)
    defer client.close()
    let result = run(client, command)
    println(result.stringify(indent=2))
  } catch {
    UsageError(message) => die(message, code=2)
    err => die(describe_error(err), code=1)
  }
}
