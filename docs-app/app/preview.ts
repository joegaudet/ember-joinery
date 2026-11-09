import { baseColors, styles } from 'virtual:joinery-themes'

/**
 * How a preview shows its example: the frame's switchers (example.gts) pick these, and the
 * preview's stage carries them. The style is `data-style` (the guide loads every style, each
 * scoped to the stages that pick it; see joinery-css.mjs), dark mode is shadcn's `.dark`
 * class, and the base colour and radius are the theme's tokens, set on the stage.
 */
export interface PreviewTheme {
  /** One of the eight styles. Default `nova`. */
  style: string
  /** One of the base colours. Default `neutral`. */
  baseColor: string
  /** `--radius`, in rem. Default 0.625, shadcn's. */
  radius: number
  dark: boolean
}

export const STYLES: readonly string[] = styles
export const BASE_COLORS: readonly string[] = Object.keys(baseColors)

/** shadcn's radius choices, in rem. */
export const RADII: readonly number[] = [0, 0.3, 0.5, 0.625, 0.75, 1]

/** The widths a preview can take, in CSS pixels: a phone, a tablet and a laptop. */
export const WIDTHS: readonly number[] = [375, 768, 1440]

export const DEFAULT_THEME: Readonly<PreviewTheme> = {
  style: 'nova',
  baseColor: 'neutral',
  radius: 0.625,
  dark: false,
}

/** The radius steps the style sheets derive from `--radius` (as joinery.css's base does). */
const RADIUS_STEPS: ReadonlyArray<readonly [name: string, factor: number]> = [
  ['sm', 0.6],
  ['md', 0.8],
  ['lg', 1],
  ['xl', 1.4],
  ['2xl', 1.8],
  ['3xl', 2.2],
  ['4xl', 2.6],
]

/** The title-case name of a style or base colour, as the switchers show it. */
export function titleOf(name: string): string {
  return name[0]!.toUpperCase() + name.slice(1)
}

/**
 * The stage's tokens, as a `style` attribute: the base colour's, light or dark, then `--radius`
 * and its steps. They are set on the stage itself, so the theme applies to the example alone.
 */
export function stageTokens(theme: PreviewTheme): string {
  const colors = baseColors[theme.baseColor] ?? baseColors[DEFAULT_THEME.baseColor]!
  const tokens = { ...colors.light, ...(theme.dark ? colors.dark : {}) }
  tokens['--radius'] = `${theme.radius}rem`
  for (const [step, factor] of RADIUS_STEPS) {
    tokens[`--radius-${step}`] = `calc(var(--radius) * ${factor})`
  }
  return Object.entries(tokens)
    .map(([name, value]) => `${name}: ${value}`)
    .join('; ')
}

/** Whether the guide shows dark now: `.dark` on `<html>`, or else the system's preference. */
export function pageIsDark(): boolean {
  const root = document.documentElement
  if (root.classList.contains('dark')) return true
  if (root.classList.contains('light')) return false
  return typeof matchMedia === 'function' && matchMedia('(prefers-color-scheme: dark)').matches
}
