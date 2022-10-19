# Personal Configurations

This directory houses configuration files for my personal Linux machine. I'll also share how you can do this in the following sections.

## Better Bash Configurations

I don't use `.bashrc` (or common alternatives), not in a traditional manner anyway. Using a single config for the many settings one can configure for bash is cumbersome. Instead, my `.bashrc` sources from a special `$HOME/.config/bash` [directory](https://github.com/exbotanical/dotfiles/tree/master/bash/.config/bash), which houses separate files for discrete bash configurations. I recommend any regular bash user do the same.

These configs are:

- *alias* persistent aliases; we can add to these using a custom command `mk_alias`
- *cmd* reusable functions - these are sourced for use during interactive shell sessions
- *env* PATHs, global environment variables, and shellopts
- *interactive* settings for interactive mode; these are sourced on every session
- *login* settings and configurations that need only be sourced upon login

There's also the `scripts` directory under `$HOME/.config/bash`, which houses scripts used by the functions in `cmd.bash`, where a command is more complicated than can be crammed into `cmd.bash` alone.
