# Personal Configurations

This directory houses my configuration files. It's also home to perhaps the most elaborate bash setup ever created.

## How it works

Here's how it all works.

First, I manage all dotfiles via [Gnu Stow](https://www.gnu.org/software/stow/). Stow allows one to manage all dotfiles from a single place, then symlink them to their respective locations. For example, all of my dotfiles are housed in a `dotfiles` directory under my home directory. Suppose I need my i3wm config file to reside at `~/.config/i3/config`. I would then structure this as `~/dotfiles/i3/.config/i3/config`. The top-level `i3` directory is simply nominal; everything therein specifies the filepath at which it will exist on the host system when I invoke `stow`.

I use a Makefile to do this: `make install` will invoke `stow`. `make unit_test` will, shockingly, run the unit tests.

Other examples follow. As an exercise to the reader, try looking through the dotfiles directory for each of the following:

- VSCodium config files must reside in `~/.config/VSCodium/User/*`.
- X11 configurations reside in the home directory itself.

As of ~~7/26/2024~~ 10/27/2026 my primary setup consists of:

- desktop env: x11
- window manager: i3wm
- notifications daemon: dunst
- toolbar: eww
- shell: bash
- terminal: alacritty

## Packages and Makefiles

- Each top-level directory constitutes a stow package except for those whose names are dot-prefixed; these contain dev tooling. We therefore filter these packages when running `stow`.
- The root Makefile runs repo-wide commands; for commands which have per-package counterparts, the target delegates to the corresponding target on each underlying package-level Makefile.
- Viz., a package that requires setup or has tests maintains its own subsidiarys `Makefile` with these targets e.g.
  - `all` - always the first and therefore default target. `make install` runs in every package prior to stowing. It is empty when the package needs no setup.
  - `postinstall` - runs after stowing.
  - `unit_test` - runs the package's tests.
- A package that adds a `Makefile`, tests, or install files enumerates said files in a package-local `.stow-local-ignore` to prevent them from being inadvertently stowed.

## Tests

- `make unit_test` runs the `unit_test` target of every package whose Makefile defines one, irrespective of the test framework therein; CI runs the same target. These are - hence the name - unit tests.
- `make integ_test` builds a container per distro, runs `make bootstrap` in it, checks the installed state, runs the unit tests, and reinstalls.

## Bootstrap

On a fresh Arch, Ubuntu, or AL2023 machine, clone the repo and run `make bootstrap`; this will install all prerequisite packages. Once done, run `make install`.

- Each `.bootstrap/modules/NN-name/` whose `detect.bash` file (which determines whether the module meets the criteria required for it to run e.g. dependencies satisfied) returns 0 runs in ls order; `install.bash` skips what is already installed.
- Dependency package names are housed under `.bootstrap/packages/`. `<manager>.<profile>.txt` contains distro-agnostic packages per profile whereas `<distro>/<manager>.<profile>.txt` files exist for each supported distro's distro-specific packages.
- The profile is `headless` on AL2023 and `desktop` elsewhere; override it with `PROFILE=headless`.
- Filtering: e.g. `ONLY=41-rust` runs only the named modules, and `SKIP=43-haskell,61-eww` skips them.

## Global NPM

The npm package furnishes fallback configs for npm-based tools (e.g. Prettier) such that any project under $HOME lacking its own config and node_modules defaults to those used here. We do this in such a way that we avoid polluting ~/node_modules, which every project under $HOME would otherwise resolve against.

- Stow links each config (e.g. npm/prettier.config.mjs) into ~; tools use the nearest config, so projects with their own are unaffected.
- Node resolves a symlinked module's imports from its real path; thus the symlinked configs will load their plugins from npm/node_modules if they are not present locally. This means we do not need a node_modules in ~ and which pollutes all npm packages therein.
- npm/Makefile runs npm ci and installs, globally, the version of each tool that npm/package-lock.json pins (e.g. Prettier, for VSCodium); the global tool thus matches the plugins it loads. nvm maintains one global folder per Node version, so rerun make -C npm after switching versions.
- npm/.stow-local-ignore keeps package.json and node_modules out of ~; otherwise, npm would treat ~ as the package root of every directory beneath it.

## Bash Config Framework

I love Bash; it's a bizarre language that can do far more than it should. You may find my Bash config of interest. Instead of the usual rc file, I've written a bespoke Bash configurations framework that allows one to logically and functionally separate commands, aliases, runtime/interactive settings, one-time login settings, and application-specific configurations.

I've taken and adapted a lot of ideas from various folks across the internet, but a noteworthy influence for this setup (and one that certainly deserves accreditation) has been Ted Lilley @binaryphile - some of the setup code has been taken directly from his work, which can be found [here](https://github.com/binaryphile/init.bash).

The entrypoint for my Bash config resides in [init.bash](bash/.config/bash/init.bash), where we load in a [utility library](bash/.config/bash/lib/utils.bash) and all settings files. This means the utility library is accessible to all settings files; at the end of the init script, we remove all of the utility functions and temporary variables from the shell environment so as not to prevent pollution. The utilities allow us to easily append to the `PATH` (and prevent duplication therein, which is quite a common problem), toggle globbing, temporarily change `IFS`, etc.

We load several files:

- [`alias.bash`](bash/.config/bash/src/alias.bash) - global aliases that are non-program specific
- [`cmd.bash`](bash/.config/bash/src/cmd.bash) - global commands
- [`env.bash`](bash/.config/bash/src/env.bash) - global environment settings
- [`interative.bash`](bash/.config/bash/src/interactive.bash) - interactive mode settings. These are loaded every time a new shell is spawned.
- [`login.bash`](bash/.config/bash/src/login.bash) - login settings. These are loaded once, when first initializing the machine.

There's also a directory called [`apps`](bash/.config/bash/apps). This houses the same 5 configuration files seen above but in the context of a specific application. For example, `git` houses configurations that explicitly pertain to and rely on `git`. In `init.bash`, there's logic that determines whether each program in the `apps` directory actually exists on the machine. If it does, it loads the configuration files; if it doesn't, nothing happens. There's an escape hatch here - `detect.bash`, which can override the app loader and tell it to explicitly load or not load the configurations based on the return code in the file.

Thus, `:` inside `detect.bash` (e.g. [here](bash/.config/bash/apps/rust/detect.bash)) means we will _always_ load that app's configurations. In other cases, we may check the host OS or [specific files](bash/.config/bash/apps/go/detect.bash) and figure it out from there.

Last, the [config](bash/.config/bash/config) directory houses config for the Bash setup logic - things like feature flags.

### Testing

The Bash config loader is fully unit-tested using `shpec`. One can find the tests [here](bash/tests). The tests are also run as part of a CI workflow in this GitHub repository.

### Scripts

I've written various Bash scripts that are housed [here](bash/.config/bash/scripts). When loading the login configurations, I [load](bash/.config/bash/settings/login.bash#L3) these into `/usr/bin` so they're on the `PATH`.
