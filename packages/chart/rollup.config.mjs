import { fileURLToPath } from 'node:url'
import { babel } from '@rollup/plugin-babel'
import { Addon } from '@embroider/addon-dev/rollup'
import { entrypoints } from '../../scripts/entrypoints.mjs'

const addon = new Addon({ srcDir: 'src', destDir: 'dist' })

// The modules that port recharts' code. recharts is MIT licensed, and its licence asks for its
// notice to ship with the code, so every built module that holds one of these opens with it in
// a /*! comment (which bundlers and minifiers keep). NOTICE has the same text.
const RECHARTS_PORTS = [
  'cartesian.ts',
  'cartesian-chart.gts',
  'nice-ticks.ts',
  'paths.ts',
  'text-size.ts',
  'tick-interval.ts',
].map(file => fileURLToPath(new URL(`./src/-private/${file}`, import.meta.url)))

const RECHARTS_NOTICE = `/*!
 * @ember-joinery/chart ports recharts 3.8.0 (https://github.com/recharts/recharts): its tick
 * selection, nice tick values, text measurement, cartesian layout, tooltip placement and
 * rectangle path.
 *
 * The MIT License (MIT). Copyright (c) 2015-present recharts
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software
 * and associated documentation files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
 * BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */`

/** Opens each built module that holds recharts' ported code with its notice. */
function rechartsNotice() {
  const holdsPort = chunk => chunk.moduleIds.some(id => RECHARTS_PORTS.includes(id))
  return {
    name: 'recharts-notice',
    banner: chunk => (holdsPort(chunk) ? RECHARTS_NOTICE : ''),
    generateBundle(_options, bundle) {
      // A port that was renamed or moved would otherwise ship without the notice.
      const chunks = Object.values(bundle).filter(output => output.type === 'chunk')
      for (const port of RECHARTS_PORTS) {
        if (!chunks.some(chunk => chunk.moduleIds.includes(port))) {
          this.error(`${port} is listed as a recharts port, but no built module holds it`)
        }
      }
    },
  }
}

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
    // The barrels, plus a subpath per module: src/components/chart-container.gts becomes
    // `@ember-joinery/chart/components/chart-container`, and src/test-support/index.ts
    // `@ember-joinery/chart/test-support`. It goes after declarations() (see the plugin).
    entrypoints({ srcDir: 'src', declarationsDir: 'declarations' }),
    rechartsNotice(),
    addon.clean(),
  ],
}
