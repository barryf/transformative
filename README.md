# Transformative

Transformative is a microblogging engine that powers my personal website [barryfrost.com][bf]. It's written in Ruby and supports several key [IndieWeb][] technologies as detailed below.

All my notes, articles, bookmarks, photos and more are hosted on my personal domain rather than in someone else's silo. I can choose how it looks and works while having fun building it for myself.

## IndieWeb

- Microformats2 (h-entry, h-event, h-cite, h-card)
- Webmention sending and receiving
- Micropub create, update and delete/undelete
- POSSE syndication to Twitter and Pinboard, via Silo.pub
- Reply/repost/like contexts fetched and displayed above posts
- Authorization via IndieAuth and `rel=me`
- PubSub(HubBub) hub pinging
- `person-tag`
- RSS feeds

## How it works

Posts are cached with just a URL and a JSON document. Entries are searched for and then rendered on the fly.

### Storage

All content is stored on GitHub in my [content][] repo. Whenever a file is added or changed, either via a Micropub post to my endpoint or via a git push, GitHub notifies my site via Transformative's webhook.

The new or updated post is then pulled from GitHub and copied to a local Postgres database as a JSON document. Note: this database is a cache that can be rebuilt from the content repo at any time; the canonical source of all content is the GitHub repo.

Images and other media files are also stored in the content repo but are copied to and served from an Amazon S3 bucket.

### Micropub

Rather than build an admin system for creating and modifying posts, I've attempted to do without. Instead I've exposed an API endpoint that's compliant with the Micropub specification for posting using a compatible third-party app.

Using a tool like [Quill][] or [Micropublish][] I can log in and then post notes, bookmarks and likes to my site. A successful post is stored on GitHub and cached on my server which then fires off any webmentions, syndicates to silos like Twitter and fetches reply/repost/like contexts for display if appropriate.

Alternatively, I can write (or edit) a post as a file and simply push via git to my GitHub content repo.

### Webmentions

Instead of a comments form, my site supports replies, reposts, likes or mentions via Webmention from another IndieWeb site. If someone wants to respond to a post they can write their note on their own site using Microformats2 h-entry markup and send a webmention ping to my endpoint.

Their h-entry will then be parsed, stored and added underneath my post with an icon indicating its type. Additional webmentions from the same permalink will update or remove it.

And using the magic of [Bridgy][], responses to my tweets, Facebook posts and Instagram photos that have been syndicated from my site are pulled back in as webmentions.

## Requirements

- Ruby 2.3.1 or newer
- PostgreSQL 9.5 or newer -- required for its JSONB support
- GitHub account -- post canonical storage
- AWS S3 bucket -- media file hosting

## Installation

Transformative currently powers my personal site but should be considered experimental and likely to change at any time. You're welcome to fork and hack on it but its primary purpose is to evolve based on my needs. Use at your own risk!

I host with and recommend Heroku.

TODO: finish installation

---

_This README is also hosted on my site as its [Colophon][]._

[bf]: https://barryfrost.com
[indieweb]: https://indieweb.org
[content]: https://github.com/barryf/content
[colophon]: https://barryfrost.com/2016/11/colophon
