import { fileURLToPath } from 'node:url'

import { includeIgnoreFile } from '@eslint/compat'
import exbotanical from '@exbotanical/eslint-config'

const gitignore = fileURLToPath(new URL('.gitignore', import.meta.url))
const prettierignore = fileURLToPath(new URL('.prettierignore', import.meta.url))

export default exbotanical(
  {
    // Sorts keys only in files whose key order carries no meaning for the program that reads them.
    jsonc: { sortKeys: ['ohmyposh/**/*.json', 'startpage/src/*.json'] },
    yaml: { sortKeys: ['lsd/.config/lsd/*.yaml'] },
    jsonSchema: true,
    githubAction: true,
    packageJson: true,
  },
  includeIgnoreFile(gitignore),
  includeIgnoreFile(prettierignore),
  // The node/hashbang rule treats only package.json `bin` entries as executables; this script
  // is run directly and needs its shebang.
  {
    name: 'dotfiles/executable-scripts',
    files: ['**/*.?([cm])js'],
    rules: {
      'node/hashbang': [
        'error',
        {
          additionalExecutables: [
            'vscodium/.config/VSCodium/User/snippets/generate-gas-registers.js',
          ],
        },
      ],
    },
  },
)
