import { defineConfig } from 'vite'
import { extensions, classicEmberSupport, ember } from '@embroider/vite'
import { babel } from '@rollup/plugin-babel'
import { kolay } from 'kolay/vite'
import { writeGuideMeta } from '../scripts/gen-guide-meta.mjs'

// The A–Z sections' meta.json files come from the pages present, so they're written before
// Kolay reads them (on every build, test run and dev server start). A page added while the dev
// server runs shows up after a restart. See "Generated files" in CONTRIBUTING.md.
writeGuideMeta()

export default defineConfig({
  // The guide is served from joegaudet.com/ember-joinery/guide/.
  base: process.env.JOINERY_GUIDE ? '/ember-joinery/guide/' : '/',
  plugins: [
    classicEmberSupport(),
    ember(),
    kolay({
      // TypeDoc renders <APIDocs> from these packages' type declarations.
      packages: [
        '@ember-joinery/ember',
        '@ember-joinery/primitives',
        '@ember-joinery/test-support',
      ],
    }),
    babel({ babelHelpers: 'runtime', extensions }),
  ],
  build: {
    // TypeDoc's browser renderer (behind <APIDocs>) looks reflections up by class name.
    rolldownOptions: { output: { keepNames: true } },
  },
  optimizeDeps: {
    // Kolay injects its virtual modules at runtime.
    exclude: ['kolay'],
  },
})
