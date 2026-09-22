///|
enum Command {
  Me
  Guilds
  Channels(@model.GuildId)
  Messages(
    @model.ChannelId,
    limit~ : Int,
    before~ : @model.MessageId?,
    after~ : @model.MessageId?
  )
  Send(@model.ChannelId, content~ : String?, reply_to~ : @model.MessageId?)
  Api(@dhttp.Route, Json?)
}

///|
fn validate_content(content : String) -> String raise UsageError {
  if content.trim(chars=" \n\r\t") == "" {
    raise UsageError("refusing to send an empty message")
  }
  content
}

///|
fn[T : ToJson] to_json_array(items : Array[T]) -> Json {
  Json::array(items.map(item => item.to_json()))
}

///|
async fn run(client : @dhttp.Client, command : Command) -> Json {
  match command {
    Me => client.get_current_user().to_json()
    Guilds => {
      let pages = client.paginate_current_user_guilds(
        page_size=200,
        with_counts=true,
      )
      let guilds = []
      while pages.next_page() is Some(page) {
        guilds.append(page)
      }
      to_json_array(guilds)
    }
    Channels(id) => to_json_array(client.guild_ref(id).channels())
    Messages(id, limit~, before~, after~) => {
      let messages = client
        .channel_ref(id)
        .messages(before?, after?, page_size=limit.min(MAX_PAGE_SIZE))
        .collect(max=limit)
      messages.sort_by((a, b) => b.id.compare(a.id))
      to_json_array(messages)
    }
    Send(id, content~, reply_to~) => {
      let content = match content {
        Some(text) => text
        None => {
          let data = @stdio.stdin.read_all()
          validate_content(
            data.text() catch {
              _ => raise UsageError("stdin is not valid UTF-8")
            },
          )
        }
      }
      client.channel_ref(id).send(content~, reply_to?).to_json()
    }
    Api(route, body) => client.request(route, body?)
  }
}
