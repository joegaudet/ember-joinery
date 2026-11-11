import { createHighlighterCore, type HighlighterCore } from 'shiki/core'
import { createOnigurumaEngine } from 'shiki/engine/oniguruma'

/**
 * GitHub's high-contrast themes: every token meets WCAG AA contrast on the guide's code
 * backgrounds, light and dark, so the pages pass their axe audits.
 */
export const THEMES = { light: 'github-light-high-contrast', dark: 'github-dark-high-contrast' }

let instance: Promise<HighlighterCore> | undefined

/** One Shiki instance for the pages and the example frames. */
export function highlighter(): Promise<HighlighterCore> {
  return (instance ??= createHighlighterCore({
    themes: [
      import('shiki/themes/github-light-high-contrast.mjs'),
      import('shiki/themes/github-dark-high-contrast.mjs'),
    ],
    langs: [
      import('shiki/langs/typescript.mjs'),
      import('shiki/langs/javascript.mjs'),
      import('shiki/langs/glimmer-ts.mjs'),
      import('shiki/langs/glimmer-js.mjs'),
      import('shiki/langs/handlebars.mjs'),
      import('shiki/langs/css.mjs'),
      import('shiki/langs/html.mjs'),
      import('shiki/langs/bash.mjs'),
      import('shiki/langs/json.mjs'),
    ],
    engine: createOnigurumaEngine(() => import('shiki/wasm')),
  }))
}

export async function highlight(code: string, lang = 'glimmer-ts'): Promise<string> {
  return (await highlighter()).codeToHtml(code.trimEnd(), {
    lang,
    themes: THEMES,
    defaultColor: 'light-dark()',
  })
}
