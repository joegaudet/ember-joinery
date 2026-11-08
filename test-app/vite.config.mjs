import { defineConfig } from 'vite'
import { extensions, classicEmberSupport, ember } from '@embroider/vite'
import { babel } from '@rollup/plugin-babel'

/**
 * `JOINERY_ANCHOR_FALLBACK=1` at build time forces the Floating UI fallback in place of CSS
 * anchor positioning (CI runs the suite once more that way). The flag reaches the page as
 * `globalThis.JOINERY_ANCHOR_FALLBACK`, set by an inline script that runs before any module;
 * `@ember-joinery/primitives` reads it when it positions a part.
 */
function anchorFallback() {
  return {
    name: 'joinery-anchor-fallback',
    transformIndexHtml() {
      if (process.env.JOINERY_ANCHOR_FALLBACK !== '1') return
      return [
        {
          tag: 'script',
          children: 'globalThis.JOINERY_ANCHOR_FALLBACK = true',
          injectTo: 'head-prepend',
        },
      ]
    },
  }
}

export default defineConfig({
  // The demo build is served from joegaudet.com/ember-joinery/demo/.
  base: process.env.JOINERY_DEMO ? '/ember-joinery/demo/' : '/',
  // Exposes the build's JOINERY_* flags to app code as import.meta.env.JOINERY_*.
  envPrefix: ['VITE_', 'JOINERY_'],
  plugins: [
    classicEmberSupport(),
    ember(),
    babel({ babelHelpers: 'runtime', extensions }),
    anchorFallback(),
  ],
})
