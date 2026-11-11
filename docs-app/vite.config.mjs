import { defineConfig } from 'vite'
import { extensions, classicEmberSupport, ember } from '@embroider/vite'
import { babel } from '@rollup/plugin-babel'
import { kolay } from 'kolay/vite'
import tailwindcss from '@tailwindcss/vite'
import { joineryCss } from './joinery-css.mjs'
import { apiDocs } from './api-docs.mjs'
import { writeGuideMeta } from '../scripts/gen-guide-meta.mjs'

// The A–Z sections' meta.json files come from the pages present, so they're written before
// Kolay reads them (on every build, test run and dev server start). A page added while the dev
// server runs shows up after a restart. See "Generated files" in CONTRIBUTING.md.
writeGuideMeta()

/**
 * The packages the Reference section documents, one page each (app/templates/reference/), from
 * their type declarations: TypeDoc reads each one's `exports` types, so build the packages first.
 */
const API_PACKAGES = [
  '@ember-joinery/ember',
  '@ember-joinery/primitives',
  '@ember-joinery/test-support',
  '@ember-joinery/chart',
  '@ember-joinery/carousel',
  '@ember-joinery/data-table',
  '@ember-joinery/code-block',
  '@ember-joinery/file-upload',
  '@ember-joinery/tiptap',
  '@ember-joinery/power-calendar',
  '@ember-joinery/maskito',
  '@ember-joinery/formwright',
]

export default defineConfig({
  // The guide is served from joegaudet.com/ember-joinery/guide/.
  base: process.env.JOINERY_GUIDE ? '/ember-joinery/guide/' : '/',
  plugins: [
    classicEmberSupport(),
    ember(),
    // TypeDoc renders <APIDocs> from these packages' type declarations, and apiDocs() refines
    // what it writes for the reference (see api-docs.mjs).
    kolay({ packages: API_PACKAGES }),
    apiDocs({ packages: API_PACKAGES }),
    // The examples' utility classes (app/styles/examples.css).
    tailwindcss(),
    // Every style, scoped to the previews that pick it, and the base colours' tokens.
    joineryCss(),
    babel({ babelHelpers: 'runtime', extensions }),
  ],
  build: {
    // TypeDoc's browser renderer (behind <APIDocs>) looks reflections up by class name.
    rolldownOptions: { output: { keepNames: true } },
  },
  optimizeDeps: {
    // Kolay injects its virtual modules at runtime.
    exclude: ['kolay'],
    // With Kolay left out of pre-bundling, so are its dependencies, and the dev server sends them
    // to the browser as they are. Two in its markdown pipeline are CommonJS, which a browser can't
    // import: `debug` (micromark's development build imports it) and `extend` (from unified).
    // Without these lines every guide page fails to render under `pnpm guide:start`; builds,
    // including the test builds, bundle them and never had the problem.
    include: [
      'kolay > remark-parse > mdast-util-from-markdown > micromark > debug',
      'kolay > unified > extend',
    ],
  },
})
