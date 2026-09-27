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
  ],
}
