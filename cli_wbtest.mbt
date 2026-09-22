///|
fn parse_test(args : Array[String]) -> Command raise {
  parse_command(build_cli().parse(argv=args, env={}))
}

///|
fn expect_usage(args : Array[String], expected : String) -> Unit raise {
  try parse_test(args) catch {
    UsageError(message) => assert_eq(message, expected)
    err => raise err
  } noraise {
    _ => fail("expected usage error")
  }
}

///|
test "me guilds and channels positionals" {
  assert_true(parse_test(["me"]) is Me)
  assert_true(parse_test(["guilds"]) is Guilds)
  guard parse_test(["channels", "123"]) is Channels(id) else {
    fail("channels")
  }
  assert_eq(id.to_string(), "123")
}

///|
test "messages defaults options and pagination limits" {
  guard parse_test(["messages", "123"]) is Messages(id, limit~, before~, after~) else {
    fail("messages")
  }
  assert_eq(id.to_string(), "123")
  assert_eq(limit, 50)
  assert_eq(before, None)
  assert_eq(after, None)
  guard parse_test(["messages", "123", "--limit", "250", "--before", "456"])
    is Messages(_, limit~, before~, after~) else {
    fail("messages before")
  }
  assert_eq(limit, 250)
  assert_eq(before.unwrap().to_string(), "456")
  assert_eq(after, None)
  guard parse_test(["messages", "123", "-n", "1", "--after", "456"])
    is Messages(_, limit~, before~, after~) else {
    fail("messages after")
  }
  assert_eq(limit, 1)
  assert_eq(before, None)
  assert_eq(after.unwrap().to_string(), "456")
  expect_usage(["messages", "123", "--limit", "0"], "--limit must be positive")
  expect_usage(
    ["messages", "123", "--limit", "oops"],
    "--limit must be an integer",
  )
  expect_usage(
    ["messages", "123", "--limit", "2147483648"],
    "--limit must be an integer",
  )
  expect_usage(
    ["messages", "123", "--before", "1", "--after", "2"],
    "--before and --after cannot be used together",
  )
}

///|
test "send joins text supports reply and stdin takes precedence" {
  guard parse_test(["send", "123", "hello", "world", "--reply-to", "456"])
    is Send(id, content~, reply_to~) else {
    fail("send")
  }
  assert_eq(id.to_string(), "123")
  assert_eq(content, Some("hello world"))
  assert_eq(reply_to.unwrap().to_string(), "456")
  guard parse_test(["send", "123", "ignored", "--stdin"])
    is Send(_, content~, reply_to~) else {
    fail("stdin")
  }
  assert_eq(content, None)
  assert_eq(reply_to, None)
  guard parse_test(["send", "123", "--", "--literal"]) is Send(_, content~, ..) else {
    fail("literal")
  }
  assert_eq(content, Some("--literal"))
  expect_usage(["send", "123"], "send needs message text or --stdin")
  expect_usage(["send", "123", " \n\t"], "refusing to send an empty message")
  assert_eq(validate_content(" line\n"), " line\n")
}

///|
test "api methods body and relative path" {
  for
    (raw, expected) in [
      ("get", @ahttp.RequestMethod::Get),
      ("POST", Post),
      ("pUt", Put),
      ("patch", Patch),
      ("DELETE", Delete),
      ("head", Head),
      ("OPTIONS", Options),
    ] {
    assert_eq(parse_method(raw), expected)
  }
  guard parse_test([
      "api", "post", "/channels/123/messages", "-d", "{\"content\":\"hello\"}",
    ])
    is Api(route, body) else {
    fail("api")
  }
  assert_eq(route.method_(), Post)
  assert_eq(route.path(), "/channels/123/messages")
  assert_eq(body, Some({ "content": "hello" }))
  guard parse_test(["api", "GET", "/users/@me"]) is Api(_, body) else {
    fail("no body")
  }
  assert_eq(body, None)
  guard parse_test(["api", "PATCH", "/channels/123", "--body", "null"])
    is Api(_, body) else {
    fail("null body")
  }
  assert_eq(body, Some(Json::null()))
  expect_usage(["api", "TRACE", "/"], "unsupported HTTP method: TRACE")
  expect_usage(["api", "POST", "/", "--body", "{"], "--body must be valid JSON")
  for path in ["https://example.com", "users/@me", "//example.com", "/foo#bar"] {
    expect_usage(
      ["api", "GET", path],
      "invalid route: use a path beginning with / under /api/v10, without // or #",
    )
  }
}

///|
test "snowflakes are decimal uint64 values" {
  for raw in ["0", "00123", "18446744073709551615"] {
    let _ : @model.ChannelId = parse_id(raw, "channel_id")
  }
  for raw in ["", "-1", "+1", "1.0", " 1", "1 ", "abc", "18446744073709551616"] {
    expect_usage(
      ["channels", raw],
      "guild_id must be a Discord snowflake, got \{raw}",
    )
  }
  expect_usage(
    ["messages", "123", "--before", "bad"],
    "before must be a Discord snowflake, got bad",
  )
  expect_usage(
    ["messages", "123", "--after", "bad"],
    "after must be a Discord snowflake, got bad",
  )
  expect_usage(
    ["send", "123", "hi", "--reply-to", "bad"],
    "reply_to must be a Discord snowflake, got bad",
  )
}

///|
test "argparse rejects missing arguments extra arguments and unknown options" {
  for
    args in [
      [],
      ["unknown"],
      ["channels"],
      ["messages"],
      ["send"],
      ["api", "GET"],
      ["me", "extra"],
      ["me", "--unknown"],
      ["messages", "1", "--limit"],
      ["messages", "1", "--limit", "-1"],
    ] {
    try parse_test(args) catch {
      _ => ()
    } noraise {
      _ => fail("expected parse failure")
    }
  }
}

///|
test "token precedence global position and missing token" {
  let cli = build_cli()
  assert_eq(
    bot_token(cli.parse(argv=["me"], env={ "DISCORD_TOKEN": "env-token" })),
    "env-token",
  )
  for args in [["--token", "explicit", "me"], ["me", "--token", "explicit"]] {
    assert_eq(
      bot_token(cli.parse(argv=args, env={ "DISCORD_TOKEN": "env-token" })),
      "explicit",
    )
  }
  for env in [{}, { "DISCORD_TOKEN": "" }, { "DISCORD_TOKEN": "  " }] {
    try bot_token(cli.parse(argv=["me"], env~)) catch {
      UsageError(message) =>
        assert_eq(message, "no bot token: set DISCORD_TOKEN or pass --token")
      err => raise err
    } noraise {
      _ => fail("expected missing token")
    }
  }
}

///|
test "Discord error messages" {
  let cases : Array[(@dhttp.DiscordHttpError, String)] = [
    (
      Api(status=401, error={
        code: 0,
        message: "401: Unauthorized",
        errors: None,
      }),
      "Discord API responded 401 (code 0): 401: Unauthorized",
    ),
    (
      RateLimited(retry_after_ms=1234L, global=true),
      "rate limited (global=true); retry after 1234 ms",
    ),
    (Deserialize(message="bad JSON"), "could not decode the response: bad JSON"),
    (Transport(message="offline"), "transport failure: offline"),
    (Timeout(timeout_ms=30000), "request timed out after 30000 ms"),
    (Validation(message="bad content"), "invalid request: bad content"),
  ]
  for (err, expected) in cases {
    assert_eq(describe_error(err), expected)
  }
  let err : Error = Failure("I/O failure")
  assert_eq(describe_error(err), err.to_string())
}

///|
async test "api command dispatch and error mapping offline" {
  let calls = Ref(0)
  let client = @dhttp.Client::offline(request => {
    calls.val += 1
    assert_eq(request.route.path(), "/channels/123/messages")
    assert_eq(request.route.method_(), Post)
    assert_eq(request.body, Some({ "content": "hello" }))
    { status: 200, headers: {}, body: { "id": "456", "content": "hello" }, }
  })
  defer client.close()
  let result = run(
    client,
    parse_test([
      "api", "POST", "/channels/123/messages", "--body", "{\"content\":\"hello\"}",
    ]),
  )
  assert_eq(result, { "id": "456", "content": "hello" })
  assert_eq(calls.val, 1)
  let unauthorized = @dhttp.Client::offline(_ => {
    status: 401,
    headers: {},
    body: { "code": 0, "message": "401: Unauthorized" },
  })
  defer unauthorized.close()
  try run(unauthorized, parse_test(["me"])) catch {
    err =>
      assert_eq(
        describe_error(err),
        "Discord API responded 401 (code 0): 401: Unauthorized",
      )
  } noraise {
    _ => fail("expected 401")
  }
}

///|
fn message_fixture(id : String) -> Json {
  {
    "id": id,
    "channel_id": "123",
    "author": {
      "id": "7",
      "username": "bot",
      "discriminator": "0",
      "avatar": Json::null(),
    },
    "content": "hello",
    "timestamp": "2026-09-22T00:00:00Z",
    "edited_timestamp": Json::null(),
    "tts": false,
    "mention_everyone": false,
    "mentions": [],
    "mention_roles": [],
    "attachments": [],
    "embeds": [],
    "pinned": false,
    "type": 0,
  }
}

///|
async test "messages after cursor returns newest first offline" {
  let client = @dhttp.Client::offline(request => {
    assert_true(request.route.path().has_prefix("/channels/123/messages"))
    {
      status: 200,
      headers: {},
      body: [message_fixture("8"), message_fixture("10"), message_fixture("9")],
    }
  })
  defer client.close()
  let result = run(client, parse_test(["messages", "123", "--after", "7"]))
  guard result is Array(items) else { fail("expected array") }
  assert_eq(items.length(), 3)
  assert_true(items[0] is { "id": String("10"), .. })
  assert_true(items[1] is { "id": String("9"), .. })
  assert_true(items[2] is { "id": String("8"), .. })
}

///|
async test "guilds does not silently truncate at 1000 offline" {
  let calls = Ref(0)
  let client = @dhttp.Client::offline(_ => {
    let start = calls.val * 200
    calls.val += 1
    let count = if calls.val <= 5 { 200 } else { 1 }
    let guilds : Array[Json] = Array::makei(count, i => {
      "id": (start + i + 1).to_string(),
      "name": "guild",
      "icon": Json::null(),
      "banner": Json::null(),
      "owner": false,
      "permissions": "0",
      "features": [],
    })
    { status: 200, headers: {}, body: Json::array(guilds), }
  })
  defer client.close()
  let result = run(client, parse_test(["guilds"]))
  guard result is Array(items) else { fail("expected array") }
  assert_eq(items.length(), 1001)
  assert_eq(calls.val, 6)
}
