// The parity reference app: renders one shadcn/ui example, by id, the way its docs page shows it.
//
//   /<id>?theme=dark&dir=rtl&align=start&base=neutral   (or /parity/<id>?…)
//
// - `theme`: `light` (default) or `dark`, as upstream's `.dark` class;
// - `dir` and `align`: default to what the docs page uses for the example (upstream/inventory.json);
// - `fullWidth=true`: stretches the example across the stage, as upstream's preview does with
//   `[&_.preview>div]:w-full` (the chart demo) and the charts gallery with a full-width cell;
// - `base`: the base colour whose tokens the page uses (shadcn's `neutral` by default, as Joinery).
//
// When the example has rendered and the fonts have loaded, `<html data-parity-ready>` is set
// (`error` if it threw), which is what scripts/parity.mjs waits for. `/` lists every id.

import '@fontsource-variable/geist'
import '@fontsource-variable/geist-mono'
import '@fontsource-variable/noto-sans-arabic'
import '@fontsource-variable/noto-sans-hebrew'
import '../.generated/upstream.css'

import * as React from 'react'
import { createRoot } from 'react-dom/client'
import { ThemeProvider } from 'next-themes'
import { examples } from 'virtual:parity-examples'
import { THEMES } from '@/registry/themes'
import { LanguageProvider } from '@/components/language-selector'
import { DirectionProvider as BaseDirectionProvider } from '@/registry/bases/base/ui/direction'
import { DirectionProvider as RadixDirectionProvider } from '@/registry/bases/radix/ui/direction'
import { TooltipProvider } from '@/styles/radix-nova/ui/tooltip'
import { Toaster } from '@/styles/radix-nova/ui/sonner'

type Entry = (typeof examples)[string]
type Module = Record<string, unknown>

const params = new URLSearchParams(location.search)
// `/parity/<id>` works too, the path the Joinery guide uses.
const id = decodeURIComponent(location.pathname.replace(/^\/+|\/+$/g, '').replace(/^parity\//, ''))
const theme = params.get('theme') === 'dark' ? 'dark' : 'light'
const baseColor = params.get('base') ?? 'neutral'

/**
 * The page's fonts, each with a character to load it for (scripts/parity.mjs's FONTS). They load
 * before the example renders: a part that measures itself on mount keeps what it measured, as
 * Radix's collapsible and accordion content pin their height, so an example rendered while
 * Geist was still loading would keep the fallback font's line breaks after Geist arrived (a
 * runner whose fallback is DejaVu Sans wraps an accordion's answer onto one more line).
 * ui.shadcn.com preloads Geist with next/font for the same reason.
 */
const FONTS: [font: string, text: string][] = [
  ['400 16px "Geist Variable"', 'a'],
  ['400 16px "Geist Mono Variable"', 'a'],
  ['400 16px "Noto Sans Arabic Variable"', 'ع'],
  ['400 16px "Noto Sans Hebrew Variable"', 'א'],
]

/** Loads the page's fonts; one that fails is left for scripts/parity.mjs's check to report. */
const fontsLoaded = () =>
  Promise.all(FONTS.map(([font, text]) => document.fonts.load(font, text).catch(() => [])))

const ready = (state: 'true' | 'error') => {
  document.fonts.ready.then(() => {
    requestAnimationFrame(() =>
      requestAnimationFrame(() => (document.documentElement.dataset.parityReady = state)),
    )
  })
}

/** The theme's tokens, light on :root and dark on .dark, as shadcn's CLI writes them. */
function themeCss(name: string) {
  const found = THEMES.find(theme => theme.name === name)
  if (!found?.cssVars) throw new Error(`no base colour named ${name}`)
  const block = (selector: string, vars: Record<string, string> = {}) =>
    `${selector} {\n${Object.entries(vars)
      .map(([key, value]) => `  --${key}: ${value};`)
      .join('\n')}\n}`
  return `${block(':root', { ...found.cssVars.theme, ...found.cssVars.light })}\n${block('.dark', found.cssVars.dark)}`
}

const pascal = (value: string) =>
  value.replace(/(^|-)(\w)/g, (_m, _d, c: string) => c.toUpperCase())

/** Upstream renders an example's default export, or else its named one. */
function pickComponent(module: Module, id: string) {
  const isComponent = (value: unknown) => typeof value === 'function'
  if (isComponent(module.default)) return module.default as React.ComponentType
  const named = module[pascal(id)] ?? Object.values(module).find(isComponent)
  if (!isComponent(named)) throw new Error(`${id} exports no component`)
  return named as React.ComponentType
}

class Boundary extends React.Component<
  { id: string; children: React.ReactNode },
  { error?: Error }
> {
  state: { error?: Error } = {}
  static getDerivedStateFromError(error: Error) {
    return { error }
  }
  componentDidCatch() {
    ready('error')
  }
  render() {
    if (this.state.error) {
      return (
        <p role="alert" data-parity-error={this.props.id}>
          {this.props.id} threw: {this.state.error.message}
        </p>
      )
    }
    return this.props.children
  }
}

function Ready({ children }: { children: React.ReactNode }) {
  React.useEffect(() => ready('true'), [])
  return children
}

function Stage({ entry, Component }: { entry: Entry; Component: React.ComponentType }) {
  const dir = (params.get('dir') ?? entry.direction) as 'ltr' | 'rtl'
  const align = params.get('align') ?? entry.align
  const fullWidth = params.get('fullWidth') === 'true'
  // As upstream's DirectionProviderWrapper does: Base UI's provider takes `direction`, and
  // Radix's (upstream's wrapper of it) `dir`.
  const example =
    entry.base === 'base' ? (
      <BaseDirectionProvider direction={dir}>
        <Component />
      </BaseDirectionProvider>
    ) : (
      <RadixDirectionProvider dir={dir}>
        <Component />
      </RadixDirectionProvider>
    )
  const stage = (
    <div
      className="parity-stage"
      data-parity={entry.id}
      data-align={align}
      data-full-width={fullWidth ? 'true' : undefined}
      dir={dir}
      data-lang={dir === 'rtl' ? 'ar' : undefined}
    >
      {example}
    </div>
  )
  return dir === 'rtl' ? <LanguageProvider defaultLanguage="ar">{stage}</LanguageProvider> : stage
}

function Index() {
  React.useEffect(() => ready('true'), [])
  const byPage = new Map<string, string[]>()
  for (const entry of Object.values(examples)) {
    byPage.set(entry.page, [...(byPage.get(entry.page) ?? []), entry.id])
  }
  return (
    <div className="parity-index">
      <h1>shadcn/ui examples ({Object.keys(examples).length})</h1>
      {[...byPage].map(([page, ids]) => (
        <p key={page}>
          <strong>{page}</strong>:{' '}
          {ids.map(name => (
            <a key={name} href={`/${name}`} style={{ marginInlineEnd: '0.75em' }}>
              {name}
            </a>
          ))}
        </p>
      ))}
    </div>
  )
}

async function main() {
  const style = document.createElement('style')
  style.id = 'parity-theme'
  style.textContent = themeCss(baseColor)
  document.head.append(style)

  const root = createRoot(document.getElementById('root')!)
  if (!id) {
    root.render(<Index />)
    return
  }
  const entry = examples[id]
  if (!entry) {
    root.render(
      <p role="alert" data-parity-missing={id}>
        No upstream example named “{id}”.
      </p>,
    )
    ready('error')
    return
  }
  let Component: React.ComponentType
  try {
    const [module] = await Promise.all([entry.load(), fontsLoaded()])
    Component = pickComponent(module as Module, id)
  } catch (error) {
    root.render(
      <p role="alert" data-parity-error={id}>
        {id} failed to load: {(error as Error).message}
      </p>,
    )
    ready('error')
    return
  }
  root.render(
    <ThemeProvider attribute="class" forcedTheme={theme} disableTransitionOnChange>
      <TooltipProvider delayDuration={0}>
        <Boundary id={id}>
          <Ready>
            <Stage entry={entry} Component={Component} />
          </Ready>
        </Boundary>
        <Toaster position="top-center" />
      </TooltipProvider>
    </ThemeProvider>,
  )
}

main()
