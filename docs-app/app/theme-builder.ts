import type { ComponentLike } from '@glint/template'
import type { ThemeTokens } from 'virtual:joinery-themes'

/**
 * The theme builder's model (components/theme-builder.gts): a style, a base colour, a radius
 * and the tokens edited on top of the base colour, light and dark, and what they come to: the
 * tokens each preview takes, and the CSS an app pastes in.
 */

/** shadcn's token pairs, grouped as its Theming page's table lists them. */
const GROUPS: { title: string; tokens: string[] }[] = [
  { title: 'Page', tokens: ['background', 'foreground'] },
  { title: 'Card', tokens: ['card', 'card-foreground'] },
  { title: 'Popover', tokens: ['popover', 'popover-foreground'] },
  { title: 'Primary', tokens: ['primary', 'primary-foreground'] },
  { title: 'Secondary', tokens: ['secondary', 'secondary-foreground'] },
  { title: 'Muted', tokens: ['muted', 'muted-foreground'] },
  { title: 'Accent', tokens: ['accent', 'accent-foreground'] },
  { title: 'Destructive', tokens: ['destructive'] },
  { title: 'Borders and focus', tokens: ['border', 'input', 'ring'] },
  { title: 'Charts', tokens: ['chart-1', 'chart-2', 'chart-3', 'chart-4', 'chart-5'] },
  {
    title: 'Sidebar',
    tokens: [
      'sidebar',
      'sidebar-foreground',
      'sidebar-primary',
      'sidebar-primary-foreground',
      'sidebar-accent',
      'sidebar-accent-foreground',
      'sidebar-border',
      'sidebar-ring',
    ],
  },
]

export interface TokenGroup {
  title: string
  /** Custom property names, `--primary`. */
  tokens: string[]
}

/**
 * The colour tokens a base colour sets, in shadcn's groups, and any it sets that no group names
 * under "Other", so a token upstream adds still shows.
 */
export function tokenGroups(colors: ThemeTokens): TokenGroup[] {
  const names = Object.keys(colors.light).filter(name => name !== '--radius')
  const grouped = new Set<string>()
  const groups = GROUPS.map(group => ({
    title: group.title,
    tokens: group.tokens.map(token => `--${token}`).filter(token => names.includes(token)),
  })).filter(group => group.tokens.length > 0)
  for (const group of groups) for (const token of group.tokens) grouped.add(token)
  const other = names.filter(name => !grouped.has(name))
  return other.length ? [...groups, { title: 'Other', tokens: other }] : groups
}

/** Token edits, light and dark: custom property name to the value typed. */
export interface Edits {
  light: Record<string, string>
  dark: Record<string, string>
}

export type Mode = 'light' | 'dark'

/** Whether the browser reads a value as a colour (so a half-typed one isn't applied). */
export function isColor(value: string): boolean {
  return typeof CSS !== 'undefined' && CSS.supports('color', value.trim())
}

/**
 * A mode's tokens: the base colour's (dark ones over light ones, as `.dark` over `:root`), then
 * the edits that are colours.
 */
export function tokensFor(colors: ThemeTokens, edits: Edits, mode: Mode): Record<string, string> {
  const tokens: Record<string, string> = {
    ...colors.light,
    ...(mode === 'dark' ? colors.dark : {}),
  }
  delete tokens['--radius']
  for (const [name, value] of Object.entries(edits[mode])) {
    if (isColor(value)) tokens[name] = value.trim()
  }
  return tokens
}

/** A preview's `style` attribute: the tokens, then `--radius`. */
export function previewStyle(tokens: Record<string, string>, radius: number): string {
  return [...Object.entries(tokens), ['--radius', `${radius}rem`]]
    .map(([name, value]) => `${name}: ${value}`)
    .join('; ')
}

/** The style sheet an app imports for a style: Nova is `joinery.css`, the rest `styles/`. */
export function styleSheetFor(style: string): string {
  return style === 'nova' ? 'joinery.css' : `styles/${style}.css`
}

export interface ThemeCss {
  style: string
  baseColor: string
  radius: number
  light: Record<string, string>
  dark: Record<string, string>
}

const titleCase = (name: string) => name[0]!.toUpperCase() + name.slice(1)

/**
 * The theme as an app's CSS: shadcn's `:root` and `.dark` blocks with every token, which an app
 * puts in place of `tokens.css` (or after it), and a comment naming the style sheet to import.
 */
export function themeCss(theme: ThemeCss): string {
  const block = (selector: string, tokens: Record<string, string>, radius?: number) =>
    [
      `${selector} {`,
      ...(radius === undefined ? [] : [`  --radius: ${radius}rem;`]),
      ...Object.entries(tokens).map(([name, value]) => `  ${name}: ${value};`),
      '}',
    ].join('\n')
  return [
    `/*`,
    ` * A Joinery theme: the ${titleCase(theme.baseColor)} base colour, edited, for the ${titleCase(theme.style)} style.`,
    ` * Import it in place of tokens.css, with the style's sheet:`,
    ` *   import '@ember-joinery/ember/${styleSheetFor(theme.style)}'`,
    ` */`,
    '',
    block(':root', theme.light, theme.radius),
    '',
    block('.dark', theme.dark),
    '',
  ].join('\n')
}

const round = (value: number, digits = 3) => {
  const rounded = Number(value.toFixed(digits))
  return Object.is(rounded, -0) ? 0 : rounded
}

/**
 * A `#rrggbb` colour (what `<input type="color">` gives) as `oklch(L C H)`, the form shadcn's
 * tokens take: sRGB to linear light, to OKLab (Björn Ottosson's matrices), to polar.
 */
export function hexToOklch(hex: string): string {
  const match = /^#?([0-9a-f]{6})$/i.exec(hex.trim())
  if (!match) throw new Error(`not a #rrggbb colour: ${hex}`)
  const [r, g, b] = [0, 2, 4].map(at => {
    const channel = parseInt(match[1]!.slice(at, at + 2), 16) / 255
    return channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4
  }) as [number, number, number]
  const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
  const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
  const L = 0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s
  const a = 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s
  const bb = 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s
  const C = Math.sqrt(a * a + bb * bb)
  if (C < 0.0005) return `oklch(${round(L)} 0 0)`
  const H = ((Math.atan2(bb, a) * 180) / Math.PI + 360) % 360
  return `oklch(${round(L)} ${round(C)} ${round(H)})`
}

let canvas: CanvasRenderingContext2D | null | undefined

/**
 * Any CSS colour as `#rrggbb`, for `<input type="color">`, which takes nothing else: the
 * browser paints it (OKLCH included) and reads the pixel back, so out-of-gamut colours land on
 * the sRGB colour the screen shows. Transparency is left out.
 */
export function colorToHex(value: string): string {
  if (canvas === undefined) {
    canvas = document.createElement('canvas').getContext('2d', { willReadFrequently: true })
  }
  if (!canvas || !isColor(value)) return '#000000'
  canvas.clearRect(0, 0, 1, 1)
  canvas.fillStyle = '#000'
  canvas.fillStyle = value
  canvas.fillRect(0, 0, 1, 1)
  const [r, g, b] = canvas.getImageData(0, 0, 1, 1).data
  return `#${[r, g, b].map(channel => channel!.toString(16).padStart(2, '0')).join('')}`
}

/** A component page's demo, as the builder's preview shows it. */
export interface Demo {
  /** The page, `components/button.md`. */
  page: string
  /** The page's title. */
  title: string
  /** The example its first `<Example>` shows. */
  example: string
  /** `rtl` when that example is shown right to left. */
  dir?: 'rtl'
}

/**
 * Each component page's demo: the example its first `<Example>` shows, as ui.shadcn.com's page
 * opens with it. A block (a whole screen, in a frame of its own) is left out.
 */
export function demosFromPages(pages: Record<string, string>): Demo[] {
  const demos: Demo[] = []
  for (const [path, text] of Object.entries(pages)) {
    const tag = /<Example\s[^>]*?@name="([^"]+)"[^>]*\/>/.exec(text)
    if (!tag || /@block=\{\{true\}\}/.test(tag[0])) continue
    const title = /^# (.+)$/m.exec(text)?.[1]?.trim() ?? tag[1]!
    demos.push({
      page: path,
      title,
      example: tag[1]!,
      ...(/@dir="rtl"/.test(tag[0]) && { dir: 'rtl' as const }),
    })
  }
  return demos.sort((a, b) => a.title.localeCompare(b.title))
}

const pages = import.meta.glob<string>('./templates/components/*.md', {
  query: '?raw',
  import: 'default',
})

/** Every component page's demo, loaded once. */
let loadingDemos: Promise<Demo[]> | undefined
export function loadDemos(): Promise<Demo[]> {
  loadingDemos ??= Promise.all(
    Object.entries(pages).map(
      async ([path, load]) => [path.slice('./templates/'.length), await load()] as const,
    ),
  ).then(entries => demosFromPages(Object.fromEntries(entries)))
  return loadingDemos
}

const examples = import.meta.glob<{ default: ComponentLike }>('./examples/*.gts')

/** An example's component, loaded on demand. */
export async function loadDemoComponent(name: string): Promise<ComponentLike | undefined> {
  const load = examples[`./examples/${name}.gts`]
  return load ? (await load()).default : undefined
}
