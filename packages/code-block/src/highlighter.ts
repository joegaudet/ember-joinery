import { waitForPromise } from '@ember/test-waiters'
import type {
  GrammarState,
  HighlighterCore,
  LanguageInput,
  LanguageRegistration,
  ThemeInput,
  ThemeRegistrationAny,
  ThemedToken,
} from 'shiki/core'

/**
 * One run of text in a line of code. A highlighted token has a `style`: Shiki's colours for it
 * in the light and the dark theme, as `--shiki-light` and `--shiki-dark`, which Joinery's CSS
 * picks between (`.dark` picks the dark one). A plain token has none.
 */
export interface CodeToken {
  readonly content: string
  readonly style?: string
}

/**
 * One line of code, as `highlightedCode` and `highlightCode` return it and `<b.Line @code>`
 * takes it: its tokens, in order. A plain line is one token without a style, and an empty line
 * has none.
 */
export type CodeLine = readonly CodeToken[]

/** What `loadHighlighter` gives: a highlighter for one language. */
export interface CodeHighlighter {
  /** The language it highlights: a name from the list, or `ansi`. */
  readonly language: string
  /**
   * Highlights `code`: one `CodeLine` per line, and the grammar's state after the last line.
   * Pass that state back with the code that follows, to carry on where it left off (as
   * `highlightedCode` does while code streams in).
   */
  highlight(
    code: string,
    state?: GrammarState,
  ): { lines: CodeLine[]; state: GrammarState | undefined }
}

/** The light and dark themes tokens are coloured with: Shiki themes, or loaders for them. */
export interface HighlighterThemes {
  light: ThemeInput
  dark: ThemeInput
}

/**
 * GitHub's high-contrast themes, Joinery's default. Upstream highlights with `github-light` and
 * `github-dark`, but some of their tokens fall below WCAG AA contrast (github-light's
 * `#E36209`, which colours parameters, is 3.5:1 on white), and Joinery's components meet AA.
 * Every token of these is 4.5:1 or more on the code block's backgrounds. To use upstream's
 * themes, or any others, pass them to `configureHighlighter`.
 */
export const DEFAULT_THEMES: Readonly<HighlighterThemes> = {
  light: () => import('shiki/themes/github-light-high-contrast.mjs'),
  dark: () => import('shiki/themes/github-dark-high-contrast.mjs'),
}

// Upstream's list (lib/highlighter.tsx). Each language loads the first time it is used; add
// more with registerLanguage().
const languages = new Map<string, LanguageInput>([
  ['bash', () => import('shiki/langs/shellscript.mjs')],
  ['css', () => import('shiki/langs/css.mjs')],
  ['diff', () => import('shiki/langs/diff.mjs')],
  ['html', () => import('shiki/langs/html.mjs')],
  ['javascript', () => import('shiki/langs/javascript.mjs')],
  ['json', () => import('shiki/langs/json.mjs')],
  ['jsx', () => import('shiki/langs/jsx.mjs')],
  ['markdown', () => import('shiki/langs/markdown.mjs')],
  ['python', () => import('shiki/langs/python.mjs')],
  ['sql', () => import('shiki/langs/sql.mjs')],
  ['tsx', () => import('shiki/langs/tsx.mjs')],
  ['typescript', () => import('shiki/langs/typescript.mjs')],
  ['yaml', () => import('shiki/langs/yaml.mjs')],
])

const aliases = new Map<string, string>([
  ['js', 'javascript'],
  ['md', 'markdown'],
  ['py', 'python'],
  ['sh', 'bash'],
  ['shell', 'bash'],
  ['shellscript', 'bash'],
  ['ts', 'typescript'],
  ['yml', 'yaml'],
  ['zsh', 'bash'],
])

let themes: HighlighterThemes = DEFAULT_THEMES

interface Shiki {
  core: HighlighterCore
  light: string
  dark: string
  /** Each language loaded so far, by its name in the list: its grammar's name in Shiki. */
  grammars: Map<string, string>
}

let instance: Promise<Shiki> | undefined

/** A theme (or a loader for one, or a module whose default export is one), resolved. */
async function resolveTheme(input: ThemeInput): Promise<ThemeRegistrationAny> {
  const value = (await (typeof input === 'function' ? input() : input)) as
    ThemeRegistrationAny | { default: ThemeRegistrationAny }
  return 'default' in value ? value.default : value
}

/**
 * The one Shiki instance, made on first use. Shiki itself loads then too, so a code block that
 * is never highlighted doesn't load it. It uses Shiki's JavaScript regex engine, so there is no
 * WASM to load.
 */
function getShiki(): Promise<Shiki> {
  return (instance ??= (async () => {
    const [{ createHighlighterCore }, { createJavaScriptRegexEngine }, light, dark] =
      await Promise.all([
        import('shiki/core'),
        import('shiki/engine/javascript'),
        resolveTheme(themes.light),
        resolveTheme(themes.dark),
      ])
    const core = await createHighlighterCore({
      themes: [light, dark],
      langs: [],
      engine: createJavaScriptRegexEngine({ forgiving: true }),
    })
    return { core, light: light.name ?? 'light', dark: dark.name ?? 'dark', grammars: new Map() }
  })())
}

/**
 * A language's grammars (or a loader for them, or a module whose default export is them),
 * resolved. The language's own grammar comes last, after any it embeds, as in Shiki's modules.
 */
async function resolveLanguage(input: LanguageInput): Promise<LanguageRegistration[]> {
  type Grammars = LanguageRegistration | LanguageRegistration[]
  const value = (await (typeof input === 'function' ? input() : input)) as
    Grammars | { default: Grammars }
  const grammars = 'default' in value ? value.default : value
  return Array.isArray(grammars) ? grammars : [grammars]
}

/** A language's name in the list, `ansi`, or `null` for one that isn't listed. */
function languageOf(language: string): string | null {
  const name = language.toLowerCase()
  if (name === 'ansi') return name
  if (languages.has(name)) return name
  return aliases.get(name) ?? null
}

/** Shiki's inline style for a token, as a string, or undefined when it has none. */
function styleOf(token: ThemedToken): string | undefined {
  const style = token.htmlStyle
  if (!style) return undefined
  const declarations = Object.entries(style).map(([property, value]) => `${property}:${value}`)
  return declarations.length ? declarations.join(';') : undefined
}

/**
 * Adds a language to the list, or replaces one: its Shiki grammar (usually a loader,
 * `() => import('shiki/langs/rust.mjs')`, so it loads the first time it is used), and any
 * aliases it goes by. Upstream's list, which you'd edit there, has `bash`, `css`, `diff`,
 * `html`, `javascript`, `json`, `jsx`, `markdown`, `python`, `sql`, `tsx`, `typescript` and
 * `yaml`, with the aliases `js`, `md`, `py`, `sh`, `shell`, `shellscript`, `ts`, `yml` and `zsh`.
 *
 *   registerLanguage('rust', () => import('shiki/langs/rust.mjs'), { aliases: ['rs'] })
 */
export function registerLanguage(
  name: string,
  grammar: LanguageInput,
  { aliases: names = [] }: { aliases?: readonly string[] } = {},
): void {
  const key = name.toLowerCase()
  languages.set(key, grammar)
  for (const alias of names) aliases.set(alias.toLowerCase(), key)
}

/** The languages in the list, and their aliases, A–Z. */
export function registeredLanguages(): string[] {
  return [...languages.keys(), ...aliases.keys()].sort()
}

/**
 * Sets the themes tokens are coloured with, for every code block highlighted from then on; with
 * no themes, it goes back to `DEFAULT_THEMES`. Give each as a Shiki theme or a loader for one:
 *
 *   configureHighlighter({
 *     themes: {
 *       light: () => import('shiki/themes/github-light.mjs'),
 *       dark: () => import('shiki/themes/github-dark.mjs'),
 *     },
 *   })
 *
 * Choose themes whose tokens keep 4.5:1 contrast on your code blocks' backgrounds.
 */
export function configureHighlighter({ themes: next }: { themes?: HighlighterThemes } = {}): void {
  themes = next ?? DEFAULT_THEMES
  instance = undefined
}

/**
 * Loads a language, and Shiki on first use, and returns a highlighter for it, or `null` for a
 * language that isn't in the list (its code shows as plain text). `ansi` renders the colours
 * of terminal output; each of its lines is highlighted on its own, so colours don't carry
 * from one line to the next, as upstream's.
 *
 * Tests wait for it: `await render()` and `settled()` return once it has loaded.
 */
export function loadHighlighter(language: string): Promise<CodeHighlighter | null> {
  return waitForPromise(load(language))
}

async function load(language: string): Promise<CodeHighlighter | null> {
  const lang = languageOf(language)
  if (!lang) return null
  const shiki = await getShiki()
  const { core, grammars } = shiki
  let grammar = lang === 'ansi' ? lang : grammars.get(lang)
  if (!grammar) {
    const registrations = await resolveLanguage(languages.get(lang)!)
    await core.loadLanguage(...registrations)
    grammar = registrations.at(-1)!.name
    grammars.set(lang, grammar)
  }
  const loaded = grammar
  const themes = { light: shiki.light, dark: shiki.dark }

  return {
    language: lang,
    highlight(code, state) {
      const tokenize = (text: string) =>
        core.codeToTokens(text, {
          lang: loaded,
          themes,
          defaultColor: false,
          grammarState: state,
        }).tokens

      // ANSI has no grammar state, so each line is tokenized on its own and gets the same
      // colours whether it arrives in one piece or streams.
      const tokens =
        lang === 'ansi' ? code.split('\n').flatMap(line => tokenize(line)) : tokenize(code)

      return {
        lines: tokens.map(line =>
          line.map(token => {
            const style = styleOf(token)
            return style ? { content: token.content, style } : { content: token.content }
          }),
        ),
        state: lang === 'ansi' ? undefined : core.getLastGrammarState(tokens),
      }
    },
  }
}

/** Code as plain lines: one token each, none for an empty line. */
export function plainLines(code: string): CodeLine[] {
  return code.split('\n').map(line => (line ? [{ content: line }] : []))
}

/**
 * Highlights code once, outside a template: one `CodeLine` per line, or `null` for a language
 * that isn't in the list. A trailing newline is ignored. Render the lines with `<b.Line @code>`.
 *
 *   const lines = (await highlightCode(code, 'tsx')) ?? plainLines(code)
 */
export async function highlightCode(code: string, language: string): Promise<CodeLine[] | null> {
  const highlighter = await loadHighlighter(language)
  const text = code.endsWith('\n') ? code.slice(0, -1) : code
  return highlighter ? highlighter.highlight(text).lines : null
}
