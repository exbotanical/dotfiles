import fs from 'node:fs'

import json from '@rollup/plugin-json'
import typescript from '@rollup/plugin-typescript'
import { terser } from 'rollup-plugin-terser'

export default {
  input: 'src/index.ts',
  plugins: [
    typescript(),
    json(),
    terser(),
    {
      name: 'inline-html',
      writeBundle(_options, bundle) {
        const jsFileName = Object.keys(bundle).find(name => name.endsWith('.js'))
        const jsCode = bundle[jsFileName].code

        const htmlTemplate = fs.readFileSync('src/index.html', 'utf8')
        const finalHtml = htmlTemplate.replace(
          '</body>',
          `<script>${jsCode}</script></body>`,
        )

        fs.writeFileSync('startpage.html', finalHtml)
      },
    },
  ],
  output: {
    format: 'iife',
    file: 'bundle.js',
    sourcemap: false,
  },
}
