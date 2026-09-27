import exbotanical from '@exbotanical/prettier-config'

const base = exbotanical({
  plugins: {
    shell: true,
    toml: true,
    xml: true,
  },
})

export default {
  ...base,
  plugins: [...base.plugins, 'prettier-plugin-ini'],
  iniSpaceAroundEquals: true,
  overrides: [
    {
      files: ['git/.gitconfig.*'],
      options: { parser: 'ini' },
    },
  ],
}
