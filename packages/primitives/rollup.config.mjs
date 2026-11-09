import { babel } from '@rollup/plugin-babel'
import { Addon } from '@embroider/addon-dev/rollup'
import { entrypoints } from '../../scripts/entrypoints.mjs'

const addon = new Addon({ srcDir: 'src', destDir: 'dist' })

export default {
  output: addon.output(),
  plugins: [
    addon.dependencies(),
    babel({ extensions: ['.js', '.gjs', '.ts', '.gts'], babelHelpers: 'bundled' }),
    addon.gjs(),
    addon.declarations(
      'declarations',
      'ember-tsc --declaration --emitDeclarationOnly --noEmit false',
    ),
    // The barrel, plus one subpath export per feature: src/anchor.ts or src/anchor/index.ts
    // becomes `@ember-joinery/primitives/anchor`. It goes after declarations() (see the plugin).
    entrypoints({ srcDir: 'src', declarationsDir: 'declarations' }),
    addon.clean(),
  ],
}
