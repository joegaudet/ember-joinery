// The Vite plugin behind the parity reference app: it serves shadcn/ui's own examples from the
// upstream checkout (`node scripts/upstream.mjs fetch` puts it in .upstream/shadcn-ui) the way
// ui.shadcn.com builds them.
//
// Upstream's examples import `@/styles/<base>-<style>/ui/<component>`, a folder its registry
// build generates from `registry/bases/<base>/ui` and the style sheet `style-<style>.css`. This
// plugin generates the same folder into parity/.generated/styles with the same transforms, from
// the published `shadcn` package at the version upstream pins (createStyleMap and transformStyle
// inline each style's classes, transformIcons turns icon placeholders into lucide icons, and
// transformDirection makes the ui-rtl copies). Upstream's own build script is never run.
//
// It also resolves the rest of what the examples import: `@/` to upstream's apps/v4,
// `@shadcn/react` and `@shadcn/helpers` to their upstream sources, small stand-ins for Next.js'
// modules, and every bare package from this app's node_modules.

import { createHash } from 'node:crypto'
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs'
import { basename, dirname, join, relative, resolve, sep } from 'node:path'
import { fileURLToPath } from 'node:url'

export const parityRoot = dirname(fileURLToPath(import.meta.url))
export const repoRoot = resolve(parityRoot, '..')
export const checkout = join(repoRoot, '.upstream', 'shadcn-ui')
export const v4 = join(checkout, 'apps', 'v4')
export const generatedDir = join(parityRoot, '.generated')
export const inventoryPath = join(repoRoot, 'upstream', 'inventory.json')

const VIRTUAL_EXAMPLES = 'virtual:parity-examples'
const RESOLVED_EXAMPLES = `\0${VIRTUAL_EXAMPLES}`
const shims = join(parityRoot, 'src', 'shims')

/** Next.js and server modules the examples import, and the stand-ins the app uses for them. */
export const SHIMS = {
  'next/link': join(shims, 'next-link.tsx'),
  'next/image': join(shims, 'next-image.tsx'),
  'next/font/google': join(shims, 'next-font-google.ts'),
  'server-only': join(shims, 'server-only.ts'),
}

/** Upstream generates ui-rtl copies only for these styles (build-registry.mts). */
export function hasRtlCopy(styleName) {
  return /^(base|radix|aria)-nova$/.test(styleName)
}

/** Every example the app can render: the docs pages' examples, the charts and the blocks. */
export function exampleEntries(inventory) {
  const entries = []
  for (const [id, example] of Object.entries(inventory.examples)) {
    entries.push({
      id,
      kind: 'example',
      file: example.file,
      styleName: example.styleName,
      base: example.base,
      page: example.page,
      direction: example.direction ?? 'ltr',
      align: example.align ?? 'center',
    })
  }
  for (const chart of inventory.charts) {
    entries.push({
      id: chart.name,
      kind: 'chart',
      file: chart.file,
      styleName: chart.styleName,
      base: 'radix',
      page: 'chart',
      direction: 'ltr',
      // The gallery stretches each card down its grid cell, so it starts at the top, as
      // scripts/parity.mjs's layoutFor() asks.
      align: 'start',
    })
  }
  for (const block of inventory.blocks) {
    if (!block.file) continue
    entries.push({
      id: block.name,
      kind: 'block',
      file: block.file,
      styleName: block.styleName,
      base: 'radix',
      page: 'blocks',
      direction: 'ltr',
      align: 'start',
    })
  }
  return entries
}

/** `PARITY_EXAMPLES=a,b` limits a build to those ids; unset, every entry is included. */
export function selectEntries(entries, only) {
  if (!only) return entries
  const wanted = new Set(
    only
      .split(',')
      .map(id => id.trim())
      .filter(Boolean),
  )
  const unknown = [...wanted].filter(id => !entries.some(entry => entry.id === id))
  if (unknown.length) throw new Error(`parity: no upstream example named ${unknown.join(', ')}`)
  return entries.filter(entry => wanted.has(entry.id))
}

/** The `virtual:parity-examples` module: each entry's layout, and a loader for its module. */
export function examplesModule(entries) {
  const lines = ['export const examples = {']
  for (const entry of entries) {
    const { file, ...meta } = entry
    const specifier = `@/${file.replace(/^apps\/v4\//, '')}`
    lines.push(
      `  ${JSON.stringify(entry.id)}: { ...${JSON.stringify(meta)}, load: () => import(${JSON.stringify(specifier)}) },`,
    )
  }
  lines.push('}')
  return `${lines.join('\n')}\n`
}

/** The styles the entries are shown in (`radix-nova`, `radix-rhea`, …), without new-york-v4. */
export function stylesInUse(entries) {
  return [
    ...new Set(
      entries.map(entry => entry.styleName).filter(name => /^(radix|base|aria)-/.test(name)),
    ),
  ].sort()
}

/** The upstream folders whose files import `@/styles/<style>/…`. */
const SCANNED = ['examples', 'components', 'lib', 'hooks', 'registry/bases', 'registry/new-york-v4']

/**
 * Every style the entries are shown in, and every `@/styles/<style>/` the files under `dirs`
 * import, sorted.
 */
export function stylesImported(dirs, entries = []) {
  const found = new Set(stylesInUse(entries))
  const walk = dir => {
    if (!existsSync(dir)) return
    for (const item of readdirSync(dir, { withFileTypes: true })) {
      const path = join(dir, item.name)
      if (item.isDirectory()) walk(path)
      else if (/\.(tsx?|mts)$/.test(item.name)) {
        for (const match of readFileSync(path, 'utf8').matchAll(
          /@\/styles\/((?:radix|base|aria)-[a-z]+)\//g,
        )) {
          found.add(match[1])
        }
      }
    }
  }
  dirs.forEach(walk)
  return [...found].sort()
}

/** Runs shadcn's icon transform on a file that uses icon placeholders (lucide, as upstream). */
async function transformIconPlaceholders(content, name) {
  if (!content.includes('IconPlaceholder')) return content
  const { transformIcons } = await import('shadcn/utils')
  const { Project, ScriptKind } = await import('ts-morph')
  const project = new Project({ useInMemoryFileSystem: true })
  const sourceFile = project.createSourceFile(name, content, {
    scriptKind: ScriptKind.TSX,
    overwrite: true,
  })
  await transformIcons({
    filename: name,
    raw: content,
    sourceFile,
    config: { iconLibrary: 'lucide' },
  })
  return sourceFile.getText()
}

/** upstream's rewriteRegistryImportsToStyle, after its base → style rename. */
export function rewriteImports(content, { base, styleName }) {
  return content
    .replaceAll(`@/registry/bases/${base}/`, `@/registry/${styleName}/`)
    .replaceAll(`@/registry/${styleName}/ui/`, `@/styles/${styleName}/ui/`)
    .replaceAll(`@/registry/${styleName}/lib/utils`, '@/lib/utils')
    .replaceAll(`@/registry/${styleName}/hooks/use-mobile`, '@/hooks/use-mobile')
    .replaceAll(`@/registry/${styleName}/lib/`, '@/lib/')
    .replaceAll(`@/registry/${styleName}/hooks/`, '@/hooks/')
}

function hash(...parts) {
  const digest = createHash('sha256')
  for (const part of parts) digest.update(part).update('\0')
  return digest.digest('hex')
}

/**
 * Writes `.generated/styles/<styleName>/ui` (and `ui-rtl` for the Nova styles) for each style,
 * as upstream's registry build does. Skips a style whose sources and transforms are unchanged.
 */
export async function generateStyles(styleNames, { log = console.log } = {}) {
  const { createStyleMap, transformDirection, transformStyle } = await import('shadcn/utils')
  const shadcnVersion = JSON.parse(
    readFileSync(join(parityRoot, 'node_modules/shadcn/package.json'), 'utf8'),
  ).version
  for (const styleName of styleNames) {
    const [base, style] = styleName.split('-')
    const uiDir = join(v4, 'registry', 'bases', base, 'ui')
    const cssPath = join(v4, 'registry', 'styles', `style-${style}.css`)
    if (!existsSync(uiDir) || !existsSync(cssPath)) {
      throw new Error(
        `parity: ${relative(repoRoot, uiDir)} or its style sheet is missing; run \`node scripts/upstream.mjs fetch\``,
      )
    }
    const css = readFileSync(cssPath, 'utf8')
    const files = readdirSync(uiDir)
      .filter(name => /\.tsx?$/.test(name) && !name.startsWith('_'))
      .sort()
    const sources = files.map(name => readFileSync(join(uiDir, name), 'utf8'))
    const key = hash('3', shadcnVersion, styleName, css, ...files, ...sources)
    const outDir = join(generatedDir, 'styles', styleName)
    const stamp = join(outDir, '.key')
    if (existsSync(stamp) && readFileSync(stamp, 'utf8') === key) continue

    const started = Date.now()
    rmSync(outDir, { recursive: true, force: true })
    const styleMap = createStyleMap(css)
    for (const [index, name] of files.entries()) {
      let content = await transformStyle(sources[index], { styleMap })
      content = rewriteImports(content, { base, styleName })
      if (name.endsWith('.tsx')) content = await transformIconPlaceholders(content, name)
      mkdirSync(join(outDir, 'ui'), { recursive: true })
      writeFileSync(join(outDir, 'ui', name), content)
      if (hasRtlCopy(styleName)) {
        const rtl = (await transformDirection(content, true)).replaceAll(
          `@/styles/${styleName}/ui/`,
          `@/styles/${styleName}/ui-rtl/`,
        )
        mkdirSync(join(outDir, 'ui-rtl'), { recursive: true })
        writeFileSync(join(outDir, 'ui-rtl', name), rtl)
      }
    }
    writeFileSync(stamp, key)
    log(
      `parity: generated styles/${styleName} (${files.length} ui files) in ${Date.now() - started}ms`,
    )
  }
}

/**
 * The app's style sheet: upstream's own globals.css (Tailwind, tw-animate-css, shadcn's
 * variants, the token mapping and base rules), pointed at the generated styles and the upstream
 * sources, then the parity page's own rules.
 */
export function upstreamCss(globals, { pageCss }) {
  const posix = path => path.split(sep).join('/')
  const sources = [
    join(v4, 'examples'),
    join(v4, 'registry', 'new-york-v4'),
    join(v4, 'registry', 'bases', 'radix', 'blocks'),
    join(v4, 'registry', 'bases', 'radix', 'components'),
    join(v4, 'components'),
    join(checkout, 'packages', 'react', 'src'),
    join(generatedDir, 'styles'),
  ]
  const body = globals
    .split('\n')
    .filter(line => !/^@import "\.\/legacy-themes\.css";/.test(line))
    .map(line =>
      line
        .replace(
          /^@source "\.\.\/node_modules\/(.*)";$/,
          (_m, rest) => `@source "${posix(join(parityRoot, 'node_modules', rest))}";`,
        )
        .replace(
          /^@source "\.\.\/styles\/(.*)";$/,
          (_m, rest) => `@source "${posix(join(generatedDir, 'styles', rest))}";`,
        ),
    )
    .join('\n')
  return [
    '/* Generated by parity/upstream-plugin.mjs from shadcn-ui/ui apps/v4/app/globals.css. */',
    body,
    '',
    ...sources.map(path => `@source "${posix(path)}";`),
    '',
    pageCss,
  ].join('\n')
}

/** The Vite plugin. */
export default function upstreamPlugin({ only = process.env.PARITY_EXAMPLES } = {}) {
  let entries = []
  const main = join(parityRoot, 'src', 'main.tsx')

  const prepare = async () => {
    if (!existsSync(inventoryPath))
      throw new Error(
        'parity: upstream/inventory.json is missing; run `node scripts/upstream.mjs inventory`',
      )
    if (!existsSync(v4))
      throw new Error(
        'parity: .upstream/shadcn-ui is missing; run `node scripts/upstream.mjs fetch`',
      )
    const inventory = JSON.parse(readFileSync(inventoryPath, 'utf8'))
    entries = selectEntries(exampleEntries(inventory), only)
    // Generated ui imports other ui of its style, and the site's own components import styles
    // too (the chat examples' Markdown uses base-rhea), so every style anything imports is built,
    // whatever the selection.
    await generateStyles(
      stylesImported(
        [...SCANNED].map(path => join(v4, path)),
        exampleEntries(inventory),
      ),
    )
    const globals = readFileSync(join(v4, 'app', 'globals.css'), 'utf8')
    const pageCss = readFileSync(join(parityRoot, 'src', 'page.css'), 'utf8')
    mkdirSync(generatedDir, { recursive: true })
    const cssPath = join(generatedDir, 'upstream.css')
    const css = upstreamCss(globals, { pageCss })
    if (!existsSync(cssPath) || readFileSync(cssPath, 'utf8') !== css) writeFileSync(cssPath, css)
  }

  return {
    name: 'joinery-parity-upstream',
    enforce: 'pre',

    config() {
      return {
        resolve: {
          alias: [
            { find: /^@\/styles\//, replacement: `${join(generatedDir, 'styles')}/` },
            {
              find: /^@shadcn\/react\/(.*)$/,
              replacement: `${join(checkout, 'packages', 'react', 'src')}/$1`,
            },
            {
              find: /^@shadcn\/helpers\/(.*)$/,
              replacement: `${join(checkout, 'packages', 'helpers', 'src')}/$1`,
            },
            { find: /^@\//, replacement: `${v4}/` },
            ...Object.entries(SHIMS).map(([find, replacement]) => ({ find, replacement })),
          ],
          dedupe: ['react', 'react-dom'],
        },
        server: { fs: { allow: [repoRoot] } },
      }
    },

    async buildStart() {
      await prepare()
    },

    async resolveId(id, importer, options) {
      if (id === VIRTUAL_EXAMPLES) return RESOLVED_EXAMPLES
      // Upstream's files sit outside this app, so their bare imports would miss its
      // node_modules: resolve them as if this app's entry imported them.
      if (
        importer &&
        importer.startsWith(checkout) &&
        /^[\w@][^:]*$/.test(id) &&
        !id.startsWith('@/')
      ) {
        return this.resolve(id, main, { ...options, skipSelf: true })
      }
      return null
    },

    load(id) {
      if (id === RESOLVED_EXAMPLES) return examplesModule(entries)
      return null
    },

    async transform(code, id) {
      // Blocks import the base's ui and icon placeholders; the site builds them against a style.
      const blocks = join(v4, 'registry', 'bases', 'radix', 'blocks')
      if (id.startsWith(blocks) && /\.tsx?$/.test(id)) {
        const styled = code.replaceAll('@/registry/bases/radix/ui/', '@/styles/radix-nova/ui/')
        return { code: await transformIconPlaceholders(styled, basename(id)), map: null }
      }
      return null
    },
  }
}
