declare global {
  /** Set by the test app's build when JOINERY_ANCHOR_FALLBACK=1; see vite.config.mjs. */
  var JOINERY_ANCHOR_FALLBACK: boolean | undefined
}

export {}
