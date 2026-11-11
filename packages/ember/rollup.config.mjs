import { babel } from '@rollup/plugin-babel'
import { Addon } from '@embroider/addon-dev/rollup'
import { entrypoints } from '../../scripts/entrypoints.mjs'
import { joineryCss } from './build-css.mjs'

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
    // The barrel, plus a subpath per module: src/components/button.gts or
    // src/components/button/index.gts becomes `@ember-joinery/ember/components/button`.
    // It goes after declarations() (see the plugin).
    entrypoints({ srcDir: 'src', declarationsDir: 'declarations' }),
    addon.clean(),
    // No module imports the CSS, so it is built beside the bundle: dist/joinery.css and the rest.
    joineryCss(),
  ],
}
