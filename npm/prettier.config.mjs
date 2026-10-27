// Prettier uses this config for files under $HOME that have no closer config. Stow links it
// into $HOME, and Node resolves the import from this file's real path in the dotfiles repo,
// which loads the packages `npm ci` installs in npm/node_modules.
import exbotanical from '@exbotanical/prettier-config'

export default await exbotanical({
  docker: true,
  ini: { iniSpaceAroundEquals: true },
  shell: true,
  toml: true,
  xml: true,
})
