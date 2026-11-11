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
    // The barrels, plus a subpath per module: src/layout.gts becomes
    // `@ember-joinery/formwright/layout`, src/setup.ts `@ember-joinery/formwright/setup`, and
    // src/test-support/index.ts `@ember-joinery/formwright/test-support`. It goes after
    // declarations() (see the plugin).
    entrypoints({ srcDir: 'src', declarationsDir: 'declarations' }),
    addon.clean(),
  ],
}
