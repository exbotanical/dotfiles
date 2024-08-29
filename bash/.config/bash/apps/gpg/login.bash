support::macos? && {
  # TODO: fix init::export
  export GPG_TTY="$(tty)"
}
