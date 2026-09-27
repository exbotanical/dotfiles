import { fileURLToPath } from 'node:url'

import { includeIgnoreFile } from '@eslint/compat'
import exbotanical from '@exbotanical/eslint-config'

const gitignore = fileURLToPath(new URL('.gitignore', import.meta.url))
const prettierignore = fileURLToPath(new URL('.prettierignore', import.meta.url))

export default exbotanical(
  {},
  includeIgnoreFile(gitignore),
  includeIgnoreFile(prettierignore),
  // @exbotanical/eslint-config 1.1.2 enables these rules on files that Prettier formats,
  // and their fixes conflict with Prettier's output.
  {
    name: 'dotfiles/yaml-prettier-conflicts',
    files: ['**/*.y?(a)ml'],
    rules: { 'capitalized-comments': 'off' },
  },
  {
    name: 'dotfiles/toml-prettier-conflicts',
    files: ['**/*.toml'],
    rules: { 'toml/array-bracket-spacing': 'off' },
  },
)
