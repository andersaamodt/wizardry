# UNIX Settings Template

UNIX Settings is a live, constitutional interface to system authority. It is designed as a minimal POSIX CGI-based site with no databases and no long-running daemons. Every fact is derived live from the OS; every mutation is explicit, per-action, and fully revealed.

## Highlights

- Domain-based navigation: Users, Services, Network, Storage, System, Software, Configuration.
- Object-centric rosters with compact, scan-first layouts.
- Escape hatches for every action: reveal command, reveal file, open man page.
- Per-site CGI scripts under `cgi/` (site-specific CGI is resolved before shared CGI paths).

## Local development

```sh
web-wizardry build unix-settings
web-wizardry serve unix-settings
```

The site expects `/cgi/unix-roster`, `/cgi/unix-action`, and `/cgi/unix-man` to be available in the per-site CGI directory.
