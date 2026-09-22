///|
/// Discord REST CLI for coding agents, built on `gaato/discord`.
///
/// Run: DISCORD_TOKEN=... moonx gaato/discord-cli <command> [args]
/// Every command prints one JSON document on stdout and exits 0. Failures
/// print `error: ...` on stderr and exit 1; usage errors exit 2.
const DEFAULT_MESSAGE_LIMIT : Int = 50

///|
const MAX_PAGE_SIZE : Int = 100

///|
suberror UsageError {
  UsageError(String)
}

///|
fn describe_error(err : Error) -> String {
  match err {
    @dhttp.DiscordHttpError::Api(status~, error~) =>
      "Discord API responded \{status} (code \{error.code}): \{error.message}"
    @dhttp.DiscordHttpError::RateLimited(retry_after_ms~, global~) =>
      "rate limited (global=\{global}); retry after \{retry_after_ms} ms"
    @dhttp.DiscordHttpError::Deserialize(message~) =>
      "could not decode the response: \{message}"
    @dhttp.DiscordHttpError::Transport(message~) =>
      "transport failure: \{message}"
    @dhttp.DiscordHttpError::Timeout(timeout_ms~) =>
      "request timed out after \{timeout_ms} ms"
    @dhttp.DiscordHttpError::Validation(message~) =>
      "invalid request: \{message}"
    _ => err.to_string()
  }
}

///|
fn[M] parse_id(raw : String, what : String) -> @model.Id[M] raise UsageError {
  guard !raw.is_empty() && raw.iter().all(c => c >= '0' && c <= '9') else {
    raise UsageError("\{what} must be a Discord snowflake, got \{raw}")
  }
  @model.Id::parse(raw) catch {
    _ => raise UsageError("\{what} must be a Discord snowflake, got \{raw}")
  }
}

///|
fn[M] optional_id(
  matches : @argparse.Matches,
  name : String,
) -> @model.Id[M]? raise UsageError {
  match matches.values.get(name) {
    Some(values) if values.length() > 0 => Some(parse_id(values[0], name))
    _ => None
  }
}

///|
fn first_value(
  matches : @argparse.Matches,
  name : String,
) -> String raise UsageError {
  match matches.values.get(name) {
    Some(values) if values.length() > 0 => values[0]
    _ => raise UsageError("missing required argument: \{name}")
  }
}

///|
fn parse_method(raw : String) -> @ahttp.RequestMethod raise UsageError {
  match raw.to_upper() {
    "GET" => Get
    "POST" => Post
    "PUT" => Put
    "PATCH" => Patch
    "DELETE" => Delete
    "HEAD" => Head
    "OPTIONS" => Options
    other => raise UsageError("unsupported HTTP method: \{other}")
  }
}

///|
fn parse_command(matches : @argparse.Matches) -> Command raise UsageError {
  match matches.subcommand {
    Some(("me", _)) => Me
    Some(("guilds", _)) => Guilds
    Some(("channels", child)) => {
      let guild_id : @model.GuildId = parse_id(
        first_value(child, "guild_id"),
        "guild_id",
      )
      Channels(guild_id)
    }
    Some(("messages", child)) => {
      let channel_id : @model.ChannelId = parse_id(
        first_value(child, "channel_id"),
        "channel_id",
      )
      let limit = @string.parse_int(first_value(child, "limit")) catch {
        _ => raise UsageError("--limit must be an integer")
      }
      if limit <= 0 {
        raise UsageError("--limit must be positive")
      }
      let before = optional_id(child, "before")
      let after = optional_id(child, "after")
      if before is Some(_) && after is Some(_) {
        raise UsageError("--before and --after cannot be used together")
      }
      Messages(channel_id, limit~, before~, after~)
    }
    Some(("send", child)) => {
      let channel_id : @model.ChannelId = parse_id(
        first_value(child, "channel_id"),
        "channel_id",
      )
      let content = if child.flags.get("stdin") == Some(true) {
        None
      } else {
        match child.values.get("text") {
          Some(values) if values.length() > 0 =>
            Some(validate_content(values.join(" ")))
          _ => raise UsageError("send needs message text or --stdin")
        }
      }
      Send(channel_id, content~, reply_to=optional_id(child, "reply_to"))
    }
    Some(("api", child)) => {
      let request_method = parse_method(first_value(child, "method"))
      let path = first_value(child, "path")
      let body : Json? = match child.values.get("body") {
        Some(values) if values.length() > 0 =>
          Some(
            @json.parse(values[0]) catch {
              _ => raise UsageError("--body must be valid JSON")
            },
          )
        _ => None
      }
      let route = @dhttp.Route::custom(request_method~, path~) catch {
        _ =>
          raise UsageError(
            "invalid route: use a path beginning with / under /api/v10, without // or #",
          )
      }
      Api(route, body)
    }
    _ => raise UsageError("unknown command")
  }
}

///|
fn build_cli() -> @argparse.Command {
  let snowflake_positional = (name : String, about : String) => {
    @argparse.PositionArg(name, about~, num_args=@argparse.ValueRange::single())
  }
  @argparse.Command(
    "discord-cli",
    about="Discord REST CLI for coding agents. Reads the bot token from DISCORD_TOKEN or --token.",
    version="0.1.0",
    subcommand_required=true,
    options=[
      @argparse.OptionArg(
        "token",
        long="token",
        about="Bot token. Defaults to the DISCORD_TOKEN environment variable.",
        env="DISCORD_TOKEN",
        global=true,
        hidden=false,
      ),
    ],
    subcommands=[
      @argparse.Command("me", about="Show the bot user behind the token."),
      @argparse.Command(
        "guilds",
        about="List the guilds the bot belongs to (with member counts).",
      ),
      @argparse.Command("channels", about="List every channel in a guild.", positionals=[
        snowflake_positional("guild_id", "Guild snowflake."),
      ]),
      @argparse.Command(
        "messages",
        about="Fetch recent messages from a channel, newest first.",
        options=[
          @argparse.OptionArg(
            "limit",
            short='n',
            long="limit",
            about="How many messages to fetch.",
            default_values=[DEFAULT_MESSAGE_LIMIT.to_string()],
          ),
          @argparse.OptionArg(
            "before",
            long="before",
            about="Only messages older than this message snowflake.",
          ),
          @argparse.OptionArg(
            "after",
            long="after",
            about="Only messages newer than this message snowflake.",
          ),
        ],
        positionals=[snowflake_positional("channel_id", "Channel snowflake.")],
      ),
      @argparse.Command(
        "send",
        about="Send a message to a channel.",
        flags=[
          @argparse.FlagArg(
            "stdin",
            long="stdin",
            about="Read the message body from stdin instead of the arguments.",
          ),
        ],
        options=[
          @argparse.OptionArg(
            "reply_to",
            long="reply-to",
            about="Reply to this message snowflake.",
          ),
        ],
        positionals=[
          snowflake_positional("channel_id", "Channel snowflake."),
          @argparse.PositionArg(
            "text",
            about="Message text (joined with spaces).",
            num_args=@argparse.ValueRange(lower=0),
            allow_hyphen_values=true,
          ),
        ],
      ),
      @argparse.Command(
        "api",
        about="Call any REST route with the bot token; prints the JSON response.",
        options=[
          @argparse.OptionArg(
            "body",
            short='d',
            long="body",
            about="JSON request body.",
          ),
        ],
        positionals=[
          @argparse.PositionArg(
            "method",
            about="HTTP method (GET, POST, PATCH, PUT, DELETE, HEAD, OPTIONS).",
            num_args=@argparse.ValueRange::single(),
          ),
          @argparse.PositionArg(
            "path",
            about="Route path under /api/v10, for example /users/@me/guilds.",
            num_args=@argparse.ValueRange::single(),
          ),
        ],
      ),
    ],
  )
}
