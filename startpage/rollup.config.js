import html from 'rollup-plugin-html'
import { terser } from 'rollup-plugin-terser'
import typescript from '@rollup/plugin-typescript'
import json from '@rollup/plugin-json'
import fs from 'fs'

export default {
  input: 'src/index.ts',
  plugins: [
    typescript(),
    json(),
    terser(),
    {
      name: 'inline-html',
      writeBundle(options, bundle) {
        const jsFileName = Object.keys(bundle).find(name =>
          name.endsWith('.js'),
        )
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
