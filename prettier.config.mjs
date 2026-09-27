import exbotanical from '@exbotanical/prettier-config'

export default {
  ...exbotanical({
    plugins: {
      ini: true,
      shell: true,
      toml: true,
      xml: true,
    },
  }),
  iniSpaceAroundEquals: true,
  overrides: [
    {
      files: ['git/.gitconfig.*'],
      options: { parser: 'ini' },
    },
    {
      files: ['**/.shellcheckrc'],
      options: { iniSpaceAroundEquals: false },
    },
    // Code blocks in Markdown are documentation examples, including intentional BAD examples.
    {
      files: ['**/*.md'],
      options: { embeddedLanguageFormatting: 'off' },
    },
  ],
}
