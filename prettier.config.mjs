import exbotanical from '@exbotanical/prettier-config'

const base = await exbotanical({
  docker: true,
  ini: { iniSpaceAroundEquals: true },
  shell: true,
  toml: true,
  xml: true,
})

export default {
  ...base,
  overrides: [
    ...(base.overrides ?? []),
    {
      files: ['git/.gitconfig.*'],
      options: { parser: 'ini' },
    },
    {
      files: ['**/.shellcheckrc'],
      options: { iniSpaceAroundEquals: false },
    },
    // Prettier detects shebangs only in file names without a dot, so this dotfile needs a glob.
    {
      files: ['x11/.xserverrc'],
      options: { parser: 'sh' },
    },
    // Code blocks in Markdown are documentation examples, including intentional BAD examples.
    {
      files: ['**/*.md'],
      options: { embeddedLanguageFormatting: 'off' },
    },
  ],
}
