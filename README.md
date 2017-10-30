# Transformative

Transformative is a microblogging engine that powers my personal website [barryfrost.com][bf]. It's written in Ruby and supports several key [IndieWeb][] technologies as detailed below.

All my notes, articles, bookmarks, photos and more are hosted on my personal domain rather than in someone else's silo. I can choose how it looks and works while having fun building it for myself.

## IndieWeb

- [Microformats2][] (h-entry, h-event, h-cite, h-card)
- [Webmention][] sending and receiving
- [Micropub][] create, update and delete/undelete
- [POSSE][] syndication to Twitter via [Silo.pub][silopub] and Pinboard
- Reply-/repost-/like- [contexts][] fetched and displayed above posts
- [Backfeed][] of replies, reposts and likes imported via [Brid.gy][bridgy]
- Authorisation via [IndieAuth][] and [`rel=me`][relme]
- [WebSub][websub] hub pinging
- [`person-tag`][persontag] support

Implementation reports are available showing Transformative's compliance with the [Webmention][wm-ir] and [Micropub][mp-ir] specifications.

## How it works

Transformative has several parts. The most obvious is a [Sinatra][] web app that serves content from a database cache. It also exposes APIs so that compatible clients can create and edit content. Posts are first stored as flat JSON files in a git repository and then sucked down into the database and cached. Any external contexts, replies, likes and reposts are also imported.

### Storage

All content is stored on GitHub in my [content][] repo. Whenever a file is added or changed, either via a Micropub post to my endpoint or via a git push, GitHub notifies Transformative via a webhook.

The post is then pulled from GitHub and copied to a local Postgres database as a full [Microformats2 JSON][mf2json] document. Note: this database is a cache that can be rebuilt from the content repo at any time; the canonical store for all content is the GitHub repo.

Images and other media files are also stored in the content repo but are copied to and served from an Amazon S3 bucket.

### Micropub

Rather than build an admin system for creating and modifying posts, I've attempted to do without. I've exposed an API endpoint that's compliant with the Micropub specification for posting and editing using a compatible third-party app.

Using a tool like [Quill][] or [Micropublish][] I can log in and then post notes, bookmarks and likes to my site. A successful post is stored on GitHub and cached on my server which then fires off any webmentions, syndicates to silos like Twitter and fetches reply/repost/like contexts for display if appropriate.

Alternatively, I can write (or edit) a post as a file and simply push via git to my GitHub content repo and Transformative pulls it down and does the rest.

### Webmentions

Instead of a comments form, my site supports replies, reposts, likes or mentions via Webmention from another IndieWeb site. If someone wants to respond to a post they can write a note on their own site using Microformats2 h-entry markup and send a webmention ping to my endpoint.

The commenter's h-entry will then be parsed, stored and added underneath my post with an icon indicating its type. Further webmentions from the same permalink will update or remove it if the link (or the whole post) is gone.

And using the magic of [Bridgy][], responses to my tweets, Facebook posts and Instagram photos that have been syndicated from my site are pulled back in as webmentions.

## Requirements

- Ruby 2.3.1 or newer
- PostgreSQL 9.4 or newer -- required for its JSONB support
- GitHub account -- post canonical storage
- AWS S3 bucket -- media file hosting

## Installation

Transformative currently powers my personal site but should be considered experimental and likely to change at any time. You're welcome to fork and hack on it but its primary purpose is to evolve based on my needs. Use at your own risk!

### Hosting

I recommend hosting Transformative with [Heroku][]. I started building a new VPS with this setup and realised I could save myself the time by using a relatively cheap Heroku instance.

### Database

Create a fresh database instance with one table named `posts`:

```
# CREATE TABLE posts (url VARCHAR(255) PRIMARY KEY, data JSONB);
```

### GitHub

- Create a public repo in GitHub (suggested name: "content")
- Create a new webhook under this repo
    - Payload URL: your Micropub endpoint, e.g. https://barryfrost.com/micropub
    - Content type: `application/json`
    - Secret: Generate/decide on a secure password or token to use when setting `GITHUB_SECRET`
    - Select just the `push` event
- Generate a Personal Access Token with repo permissions and keep a note of it to use when setting `GITHUB_ACCESS_TOKEN `.

### Environment variables

You will need to define the following environment variables:

- `SITE_URL` e.g. https://barryfrost.com/
- `MEDIA_URL` e.g. https://barryfrost-media.s3.amazonaws.com/
- `GITHUB_USER` e.g. barryf
- `GITHUB_REPO` -- name of an empty repo to use as your content store
- `GITHUB_ACCESS_TOKEN` -- a personal access token generated from your GitHub account
- `GITHUB_SECRET` -- a (strong) random password/token you've generated for the webhook
- `SILOPUB_TWITTER_TOKEN` -- a token generated by SiloPub when syndicating to Twitter
- `DATABASE_URL` -- your Postgres connection (Heroku will create this for you on deploy)

Optional variables:

- `CAMO_KEY` -- your [Camo][] instance private key
- `CAMO_URL` -- your [Camo][] instance root URL
- `PUSHOVER_USER`, `PUSHOVER_TOKEN` -- account details for use with Pushover
- `PINBOARD_AUTH_TOKEN` -- Pinboard API key
- `PUBSUBHUBBUB_HUB` e.g. https://barryfrost.superfeedr.com

---

_This README also appears on my site as its [Colophon][]._

[bf]: https://barryfrost.com
[indieweb]: https://indieweb.org
[microformats2]: http://microformats.org/wiki/microformats2
[webmention]: https://webmention.net
[micropub]: https://micropub.net
[backfeed]: http://indieweb.org/backfeed
[posse]: http://indieweb.org/POSSE
[silopub]: https://silo.pub
[contexts]: http://indieweb.org/reply-context
[indieauth]: https://indieauth.com
[relme]: http://indieweb.org/rel-me
[websub]: http://indieweb.org/websub
[persontag]: http://indieweb.org/person-tag
[wm-ir]: https://github.com/w3c/webmention/blob/master/implementation-reports/transformative.md
[mp-ir]: https://micropub.rocks/implementation-report/server/30/Qr4kVp0CSxFGY9Zfpsfh
[sinatra]: sinatrarb.com
[content]: https://github.com/barryf/content
[mf2json]: http://microformats.org/wiki/microformats2-parsing
[quill]: https://quill.p3k.io
[micropublish]: https://micropublish.net
[bridgy]: https://brid.gy
[heroku]: https://www.heroku.com
[colophon]: https://barryfrost.com/2016/11/colophon
