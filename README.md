# herdr-codespaces

Use your GitHub Codespaces as [herdr](https://herdr.dev) machines. Pick a codespace from a menu and it shows up in
your sidebar next to your local workspaces.

## Install

```sh
herdr plugin install alexjyong/herdr-codespaces
```

Or from a clone: `herdr plugin link /path/to/herdr-codespaces`.

You'll need `gh` logged in with the `codespace` scope, and herdr 0.9 or newer. `fzf` makes the pickers nicer, but
the plugin works without it.

Then bind a key to the menu in `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+m"
type = "plugin_action"
command = "alexjyong.codespaces.open"
description = "codespaces"
```

Run `herdr server reload-config` or restart herdr, and `ctrl+b m` opens the menu. (Don't use `prefix+g`. herdr
already uses it for goto.)

## Using it

The menu has five entries:

- **add**: pick a codespace and register it with herdr. If the codespace is stopped, it gets started (this takes about a
  minute). herdr may ask to install itself on the codespace. Say yes. The machine is labeled with the codespace name
  minus the random suffix, so `obscure-parakeet-pv45jwpqvghrv6g` becomes `obscure-parakeet`.
- **refresh**: the same as add. Use it to start a codespace you stopped, or after a rebuild changes its host key.
- **remove**: take a codespace out of herdr. The codespace itself isn't touched.
- **stop**: shut a codespace down.
- **list**: all your codespaces, and which ones are in herdr.

Everything also works from a terminal: `bin/herdr-codespaces add|refresh|remove|stop [name] [label]`, `list`, or `menu`.

## Not paying for idle codespaces

herdr stays connected to every machine in the sidebar, and GitHub counts that connection as activity. So a codespace
you forget about never hits its idle timeout. herdr also reconnects on its own, which would start a codespace
right back up after you stopped it.

The plugin handles the second problem for you. Its ssh config checks the codespace's state before connecting and
refuses if the codespace isn't already running. So a stopped codespace stays stopped until you add or refresh it.

For the first problem, turn on autostop (macOS only):

```sh
bin/herdr-codespaces autostop on        # or: autostop on 120
```

That installs a launchd job that runs every five minutes. Once your Mac has had no keyboard or mouse input for an
hour, it stops every registered codespace, except ones where an agent is still working. `autostop off` removes it.
It logs what it stopped to `~/Library/Logs/herdr-codespaces.log`.

A spending limit in your GitHub billing settings is a good backstop either way.

## What it changes on your machine

Worth knowing before you install it:

- **`~/.ssh/codespaces`** gets one `Host herdr-cs.<name>` block per codespace, and `~/.ssh/config` gets an `Include`
  line for it (the old file is backed up to `~/.ssh/config.bak`). The block comes from `gh codespace ssh --config`
  with three changes:
  - a stable host name, since gh's own name includes the branch and breaks when you switch branches
  - host keys saved in `~/.ssh/codespaces_known_hosts`, because gh writes them to `/dev/null`, which herdr's strict
    host checking rejects
  - the state check described above
- **On the codespace:**
  - `~/.local/bin/herdr` is symlinked into `/usr/local/bin`, because that's where herdr looks for it over ssh.
  - A marked block is added to `~/.bashrc`. herdr panes aren't login shells, so the codespace's usual login setup
    never runs, and without the block `git pull` asks for a password and new panes open in `~` instead of the repo.
    The block loads the git token and moves you into the repo.
  - If Claude Code is set up there, add offers to install herdr's Claude integration, which lets herdr resume Claude
    sessions after a restart. If it's already installed, you won't be asked.
- **launchd** gets one job, but only if you turn on autostop.

## Tests

```sh
bash test/smoke.sh
```
