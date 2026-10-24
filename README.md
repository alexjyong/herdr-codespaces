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

The menu has seven entries:

- **toggle**: pick a codespace (the list shows each one's state) to start it if it's stopped or stop it if it's
  running.
- **add**: pick a codespace and register it with herdr. If the codespace is stopped, it gets started (this takes about a
  minute). herdr may ask to install itself on the codespace. Say yes. The machine is labeled with the codespace's
  display name on GitHub (the one you can rename there).
- **refresh**: the same as add. Use it to start a codespace you stopped, after a rebuild changes its host key, or when
  herdr is stuck on "reconnecting": for an already registered codespace it makes open herdr clients reconnect right
  away.
- **remove**: take a codespace out of herdr. The codespace itself isn't touched.
- **start**: start a stopped codespace through the GitHub API, wait until it's available and reachable, then make open
  herdr clients reconnect to it right away.
- **stop**: shut a codespace down.
- **list**: all your codespaces, and which ones are in herdr.

The menu runs on the herdr server you have selected, so open it while Local is selected.

Everything also works from a terminal: `bin/herdr-codespaces add|refresh|remove|start|stop [name] [label]`, `toggle`,
`list`, or `menu`.

## Not paying for idle codespaces

herdr stays connected to every machine in the sidebar, and GitHub counts that connection as activity. So a codespace
you forget about never hits its idle timeout. herdr also reconnects on its own, which would start a codespace
right back up after you stopped it.

The plugin handles the second problem for you. Its ssh config checks the codespace's state before connecting and
refuses if the codespace isn't already running. So a stopped codespace stays stopped until you start, add, or refresh
it.

For the first problem, turn on autostop (macOS, WSL, or Linux on X11 with `xprintidle`):

```sh
bin/herdr-codespaces autostop on        # or: autostop on 120
```

That installs a job that runs every five minutes. Once your computer has had no keyboard or mouse input for an
hour, it stops every registered codespace, except ones where an agent is still working. `autostop off` removes it.

- **macOS**: a launchd job. It logs what it stopped to `~/Library/Logs/herdr-codespaces.log`.
- **Linux**: a systemd user timer, `herdr-codespaces-autostop.timer`. It logs to
  `journalctl --user -u herdr-codespaces-autostop`. Under WSL the input comes from Windows, so idle time is read
  through `powershell.exe`; elsewhere it uses `xprintidle`.

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
- **launchd** (macOS) or **systemd** (Linux) gets one job, but only if you turn on autostop.

## Tests

```sh
bash test/smoke.sh
```
