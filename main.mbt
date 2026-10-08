///|
async fn exit_with(text : String, code~ : Int) -> Unit {
  @stdio.stderr.write(text) catch {
    _ => ()
  }
  @sys.exit(code)
}

///|
async fn die(message : String, code~ : Int) -> Unit {
  exit_with("error: " + message + "\n", code~)
}

///|
/// argparse parse failures are display-ready: they already start with
/// `error:` and carry the usage text, so they are printed as they are.
fn argparse_failure_text(message : String) -> String {
  let text = if message.has_prefix("error:") {
    message
  } else {
    "error: " + message
  }
  if text.has_suffix("\n") {
    text
  } else {
    text + "\n"
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
    err => {
      exit_with(argparse_failure_text(err.to_string()), code=2)
      return
    }
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
