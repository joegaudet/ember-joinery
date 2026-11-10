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
    // The barrels, plus a subpath per module: src/components/data-table.gts becomes
    // `@ember-joinery/data-table/components/data-table`, src/table.ts `@ember-joinery/data-table/table`,
    // and src/test-support/index.ts `@ember-joinery/data-table/test-support`. It goes after
    // declarations() (see the plugin).
    entrypoints({ srcDir: 'src', declarationsDir: 'declarations' }),
    addon.clean(),
  ],
}
