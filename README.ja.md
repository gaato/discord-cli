# gaato/discord-cli

Discord のボットの REST API をシェルから使えます。ボットのサーバー・チャンネル・最近のメッセージを読み、メッセージや返信を送り、ほかの REST のルートも呼べて、結果は別のプログラムへパイプで渡せる JSON で返ります。人だけでなくコーディングエージェントが動かすことも想定していて、エージェント用のスキルが付いています。[`gaato/discord`](https://mooncakes.io/docs/gaato/discord) の上に作っています。

非公式で、Discord とは関係ありません。

[English](https://github.com/gaato/discord-cli/blob/main/README.md)

## インストール

ビルド済みの Wasm の実行ファイルを MoonBit の `moonx` で動かします。`moonx` は最新のリリースを取ってきて moonrun の上で動かすので、native のコンパイラーも Node.js も要りません。ヘルプはトークンなしで見られます:

```sh
moonx gaato/discord-cli --help
```

## 使い方

ボットのトークンを環境変数 `DISCORD_TOKEN` に入れて、次のように実行します:

```sh
moonx gaato/discord-cli me
moonx gaato/discord-cli guilds
moonx gaato/discord-cli channels 123456789012345678
moonx gaato/discord-cli messages 234567890123456789 --limit 10
moonx gaato/discord-cli send 234567890123456789 'Hello'
moonx gaato/discord-cli api GET /users/@me
```

別のコマンドの出力を返信として投稿するには:

```sh
printf '%s\n' 'Build complete.' | moonx gaato/discord-cli send 234567890123456789 --stdin --reply-to 345678901234567890
```

| オプション | 対象 | 意味 |
| --- | --- | --- |
| `--token TOKEN` | すべてのコマンド | `DISCORD_TOKEN` より優先する。プロセスの一覧にトークンが出ないよう、環境変数の方を勧める |
| `--help`, `-h` | すべてのコマンド | 使い方の表示 |
| `--version` | ルート | 版の表示 |
| `--limit N`, `-n N` | `messages CHANNEL_ID` | 既定は 50。それより多いとページを送って取る |
| `--before ID` / `--after ID` | `messages CHANNEL_ID` | その ID を含まない位置指定。どちらか一方だけを使う |
| `--stdin` | `send CHANNEL_ID [text...]` | 引数の代わりに標準入力(UTF-8)からメッセージを読む |
| `--reply-to ID` | `send CHANNEL_ID [text...]` | メッセージに返信する |
| `--body JSON`, `-d JSON` | `api METHOD PATH` | JSON の本文。パスは `/api/v10` からの相対 |

ID は符号なし 64 ビットの十進の文字列です。多くの JSON の道具はこの大きさの数で精度を失うので、スクリプトでは文字列のまま扱ってください。メッセージは新しい順に並びます。`guilds` はすべてのページを取ってきます。

## 出力と終了コード

データを返すコマンドは、成功すると整形した JSON の文書を一つ標準出力に書きます。エラーは標準エラーに `error: ...` として出ます。

| 終了コード | 意味 |
| --- | --- |
| 0 | 成功、またはヘルプ |
| 1 | Discord API・ネットワーク・その他の実行時の失敗 |
| 2 | 引数の誤り、トークンがない、メッセージが空 |

なので、空の一覧と失敗したリクエストを区別できます。

## トークンと書き込み

`DISCORD_TOKEN` はボットのトークンでなければならず、ボットには読む・投稿するものに応じた Discord の権限が要ります。`send` と、変更を加える `api` の呼び出しはボットとして動き、結果はほかの人にも見えます。

## ホストへのアクセスを絞る

任意の moonrun のポリシーで、トークンと HTTPS での Discord への接続だけを許し、ファイルシステムへのアクセスとプロセスの起動を禁じられます。次を `discord-policy.json` として保存します:

```json
{
  "env": { "from_host": ["DISCORD_TOKEN"] },
  "net": { "connect": ["discord.com:443"] }
}
```

```sh
moonx --experimental-policy discord-policy.json gaato/discord-cli me
```

`--stdin` は引き続き標準入力を読み、シェルのリダイレクトは Wasm の外でファイルを開きます。ポリシーのフラグは moonx では実験的です。

## ターゲット

実行ファイルは moonrun の上で動き、ネットワークも moonrun が提供します。ブラウザー・WASI・wasm-gc の実行環境には対応していません。native 向けにもビルドできます。

## エージェント用のスキル

[スキル](https://github.com/gaato/discord-cli/blob/main/SKILL.md)には、各コマンドの出力の欄、投稿してよい場面、レート制限の扱いが書いてあります。

## リンク

- [変更履歴](https://github.com/gaato/discord-cli/blob/main/CHANGELOG.md)
- [リポジトリ](https://github.com/gaato/discord-cli)
- 土台のライブラリ [`gaato/discord`](https://mooncakes.io/docs/gaato/discord)

## ライセンス

Apache-2.0 です。
