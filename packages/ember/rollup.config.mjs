import { babel } from '@rollup/plugin-babel'
import { Addon } from '@embroider/addon-dev/rollup'
import { joineryCss } from './build-css.mjs'

const addon = new Addon({ srcDir: 'src', destDir: 'dist' })

export default {
  output: addon.output(),
  plugins: [
    // The barrel, plus a subpath for every module (`@ember-joinery/ember/components/button`).
    addon.publicEntrypoints(['**/*.js']),
    addon.dependencies(),
    babel({ extensions: ['.js', '.gjs', '.ts', '.gts'], babelHelpers: 'bundled' }),
    addon.gjs(),
    addon.declarations(
      'declarations',
      'ember-tsc --declaration --emitDeclarationOnly --noEmit false',
    ),
    addon.clean(),
    // No module imports the CSS, so it is built beside the bundle: dist/joinery.css and the rest.
    joineryCss(),
  ],
}
