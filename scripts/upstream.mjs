#!/usr/bin/env node
// Joinery's view of upstream: shadcn-ui/ui and ember-primitives at the commits pinned in
// upstream.json (see "Parity and upstream watch" in JOINERY_PLAN.md).
//
//   node scripts/upstream.mjs fetch              sparse, shallow clones of the pins into .upstream/
//   node scripts/upstream.mjs inventory          writes upstream/inventory.json from .upstream/
//   node scripts/upstream.mjs inventory --check  fails if the committed inventory is stale
//   node scripts/upstream.mjs changes            what changed upstream since the pins, by component
//                [--json] [--out <file>]         (Markdown by default, as the tracking issue shows it)
//                [--issue-body <file>]           also the Markdown cut to fit an issue body
//
// Upstream is data: this script reads its files and its git history, and never runs its code.

import { spawnSync } from 'node:child_process'
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs'
import { basename, dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

export const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
export const PINS_FILE = 'upstream.json'
export const INVENTORY_FILE = 'upstream/inventory.json'
export const UPSTREAM_DIR = '.upstream'

const V4 = 'apps/v4'

/**
 * What each upstream checkout holds (`sparse`, as non-cone sparse-checkout patterns) and which of
 * those paths the upstream watch reports on (`watch`).
 */
export const SOURCES = {
  'shadcn-ui': {
    sparse: [
      // What Joinery ports: the Radix base, its style sheets, the examples and the docs pages.
      `/${V4}/registry/bases/radix/`,
      `/${V4}/registry/styles/`,
      `/${V4}/examples/radix/`,
      `/${V4}/content/docs/components/radix/`,
      // The charts gallery, and the new-york-v4 ui its charts import.
      `/${V4}/registry/new-york-v4/`,
      // A few docs pages (Combobox, the chart RTL example) show Base UI examples.
      `/${V4}/registry/bases/base/`,
      `/${V4}/examples/base/`,
      // What the examples import from the site itself, for the parity reference app.
      `/${V4}/registry/themes.ts`,
      `/${V4}/registry/base-colors.ts`,
      `/${V4}/registry/icons/`,
      `/${V4}/components/`,
      `/${V4}/hooks/`,
      `/${V4}/lib/`,
      `/${V4}/app/globals.css`,
      `/${V4}/app/style-registry.css`,
      `/${V4}/package.json`,
      // The headless parts some ui sources import (@shadcn/react) and the chat helpers.
      '/packages/react/src/',
      '/packages/react/package.json',
      '/packages/helpers/src/',
      '/packages/helpers/package.json',
    ],
    watch: [
      `${V4}/registry/bases/radix/ui`,
      `${V4}/registry/bases/radix/blocks`,
      `${V4}/registry/styles`,
      `${V4}/examples/radix`,
      `${V4}/examples/base`,
      `${V4}/registry/new-york-v4/charts`,
      `${V4}/content/docs/components/radix`,
      'packages/react/src',
    ],
  },
  'ember-primitives': {
    sparse: ['/ember-primitives/src/', '/ember-primitives/package.json', '/docs-app/public/docs/'],
    watch: ['ember-primitives/src'],
  },
}

export const PATHS = {
  docs: `${V4}/content/docs/components/radix`,
  ui: `${V4}/registry/bases/radix/ui`,
  styles: `${V4}/registry/styles`,
  charts: `${V4}/registry/new-york-v4/charts`,
  blocks: `${V4}/registry/bases/radix/blocks`,
  examples: base => `${V4}/examples/${base}`,
}

// ---------------------------------------------------------------------------------------------
// Pins and git

/** upstream.json, checked for the fields the scripts rely on. */
export function readPins(root = repoRoot) {
  const pins = JSON.parse(readFileSync(join(root, PINS_FILE), 'utf8'))
  for (const name of Object.keys(SOURCES)) {
    const pin = pins[name]
    if (
      !pin ||
      !/^[\w.-]+\/[\w.-]+$/.test(pin.repo ?? '') ||
      !/^[0-9a-f]{40}$/.test(pin.commit ?? '')
    ) {
      throw new Error(`${PINS_FILE}: "${name}" needs a repo ("owner/name") and a full commit sha`)
    }
  }
  return pins
}

/** Where a source is checked out. */
export function checkoutDir(name, root = repoRoot) {
  return join(root, UPSTREAM_DIR, name)
}

function git(args, { cwd, allowFailure = false } = {}) {
  const result = spawnSync('git', args, { cwd, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 })
  if (result.status !== 0 && !allowFailure) {
    throw new Error(`git ${args.join(' ')} failed:\n${result.stderr || result.stdout}`)
  }
  return result
}

const sleep = ms => new Promise(done => setTimeout(done, ms))

/** A network git command. On a rate limit (HTTP 429) it waits five seconds and tries once more. */
async function gitNetwork(args, options) {
  const first = git(args, { ...options, allowFailure: true })
  if (first.status === 0) return first
  if (/\b429\b/.test(first.stderr)) {
    await sleep(5000)
    return git(args, options)
  }
  throw new Error(`git ${args.join(' ')} failed:\n${first.stderr || first.stdout}`)
}

function hasCommit(dir, commit) {
  return (
    git(['cat-file', '-e', `${commit}^{commit}`], { cwd: dir, allowFailure: true }).status === 0
  )
}

/**
 * Makes `.upstream/<name>` a sparse, shallow, blobless checkout of the pinned commit. Running it
 * again is cheap: a checkout already at the pin with the same sparse paths is left alone.
 */
export async function fetchSource(
  name,
  { root = repoRoot, pins = readPins(root), log = console.log } = {},
) {
  const pin = pins[name]
  const source = SOURCES[name]
  const dir = checkoutDir(name, root)
  // `url` is for tests, which fetch from a local repository instead of GitHub.
  const url = pin.url ?? `https://github.com/${pin.repo}.git`

  if (!existsSync(join(dir, '.git'))) {
    mkdirSync(dir, { recursive: true })
    git(['init', '--quiet'], { cwd: dir })
    git(['remote', 'add', 'origin', url], { cwd: dir })
  } else {
    git(['remote', 'set-url', 'origin', url], { cwd: dir })
  }

  const sparse = git(['sparse-checkout', 'list'], { cwd: dir, allowFailure: true }).stdout
  const head = git(['rev-parse', '--verify', '--quiet', 'HEAD'], { cwd: dir, allowFailure: true })
  if (head.stdout.trim() === pin.commit && sparse.trim() === source.sparse.join('\n')) {
    log(`${name}: up to date at ${pin.commit.slice(0, 7)}`)
    return dir
  }

  git(['sparse-checkout', 'set', '--no-cone', ...source.sparse], { cwd: dir })
  if (!hasCommit(dir, pin.commit)) {
    log(`${name}: fetching ${pin.repo}@${pin.commit.slice(0, 7)}`)
    await gitNetwork(
      ['fetch', '--quiet', '--depth=1', '--filter=blob:none', 'origin', pin.commit],
      {
        cwd: dir,
      },
    )
  }
  await gitNetwork(['checkout', '--quiet', '--detach', pin.commit], { cwd: dir })
  log(`${name}: checked out ${pin.commit.slice(0, 7)} into ${UPSTREAM_DIR}/${name}`)
  return dir
}

/** The `fetch` command: every source, one after another. */
export async function fetchAll(options = {}) {
  for (const name of Object.keys(SOURCES)) await fetchSource(name, options)
}

// ---------------------------------------------------------------------------------------------
// Inventory

const PREVIEW_ATTRIBUTES = [
  'styleName',
  'direction',
  'align',
  'previewClassName',
  'className',
  'type',
]

/** Markdown with its fenced code blocks blanked out (line count kept), so samples aren't parsed. */
export function stripFences(markdown) {
  return markdown.replace(/^(```|~~~)[^\n]*\n[\s\S]*?^\1[^\n]*$/gm, block =>
    block.replace(/[^\n]/g, ''),
  )
}

/** The front matter's flat `key: value` pairs. */
export function frontMatter(markdown) {
  const match = /^---\n([\s\S]*?)\n---/.exec(markdown)
  const fields = {}
  if (!match) return fields
  for (const line of match[1].split('\n')) {
    const pair = /^([\w-]+):\s*(.*)$/.exec(line)
    if (pair) fields[pair[1]] = pair[2].replace(/^(["'])(.*)\1$/, '$2')
  }
  return fields
}

// One JSX attribute: a bare name, a quoted string, a string in braces, or any other expression in
// braces (one level of nested braces), which is kept as its source.
const ATTRIBUTE =
  /\s*([A-Za-z_][\w-]*)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|\{\s*"([^"]*)"\s*\}|\{\s*'([^']*)'\s*\}|(\{(?:[^{}]|\{[^{}]*\})*\})))?/y

/**
 * A JSX tag's attributes, in order: strings as strings, a bare name as `true`, `{true}` and
 * `{false}` as booleans, and any other `{…}` as its source. Throws on anything else, rather than
 * guessing.
 */
export function parseAttributes(body) {
  const attributes = {}
  let index = 0
  while (body.slice(index).trim() !== '') {
    ATTRIBUTE.lastIndex = index
    const match = ATTRIBUTE.exec(body)
    if (!match) throw new Error(`can't read the attributes at: ${body.slice(index).trim()}`)
    const [, key, ...values] = match
    const string = values.slice(0, 4).find(value => value !== undefined)
    const expression = values[4]
    attributes[key] =
      string ??
      (expression === undefined
        ? true
        : /^\{\s*(true|false)\s*\}$/.test(expression)
          ? expression.includes('true')
          : expression)
    index = ATTRIBUTE.lastIndex
  }
  return attributes
}

/**
 * Every `<ComponentPreview>` on a docs page, in order: its example `name`, its `styleName`, and
 * the attributes that change how upstream lays the preview out. Quoted values and `{…}` may hold
 * `>` (`className="[&_.preview>div]:w-full"`), so a tag runs to the first `>` outside them. A
 * preview without a name, or with attributes that can't be read, fails.
 */
export function parsePreviews(markdown) {
  const previews = []
  const text = stripFences(markdown)
  const tags = /<ComponentPreview\b((?:"[^"]*"|'[^']*'|\{(?:[^{}]|\{[^{}]*\})*\}|[^>"'{])*?)\/?>/g
  for (const match of text.matchAll(tags)) {
    const line = text.slice(0, match.index).split('\n').length
    let attributes
    try {
      attributes = parseAttributes(match[1])
    } catch (error) {
      throw new Error(`<ComponentPreview> on line ${line}: ${error.message}`, { cause: error })
    }
    if (typeof attributes.name !== 'string' || !attributes.name) {
      throw new Error(`<ComponentPreview> on line ${line} has no name`)
    }
    const preview = { name: attributes.name }
    for (const key of PREVIEW_ATTRIBUTES) {
      if (typeof attributes[key] === 'string') preview[key] = attributes[key]
    }
    if (attributes.hideCode === true) preview.hideCode = true
    preview.line = line
    previews.push(preview)
  }
  return previews
}

/** `radix-nova` → `{ base: 'radix', style: 'nova' }`. */
export function splitStyleName(styleName) {
  const match = /^(radix|base|aria)-([a-z]+)$/.exec(styleName ?? '')
  if (!match) throw new Error(`unknown styleName "${styleName}"`)
  return { base: match[1], style: match[2] }
}

/**
 * The page an example belongs to: of the pages showing it, the one whose name is the longest
 * prefix of the example's (`button-group-demo` is Button Group's, though Button shows it too).
 */
export function ownerPage(example, pages) {
  const prefixed = pages
    .filter(page => example === page || example.startsWith(`${page}-`))
    .sort((a, b) => b.length - a.length)
  return prefixed[0] ?? pages[0]
}

/** A folder's files with this extension, by name without it (`button` before `button-group`). */
function listFiles(dir, extension) {
  if (!existsSync(dir)) return []
  const stem = name => name.slice(0, -extension.length)
  return readdirSync(dir)
    .filter(name => name.endsWith(extension) && !name.startsWith('_'))
    .sort((a, b) => (stem(a) < stem(b) ? -1 : stem(a) > stem(b) ? 1 : 0))
}

/** The chart gallery's ids and categories, from its `_registry.ts`, checked against its files. */
export function parseChartRegistry(source) {
  const charts = []
  for (const match of source.matchAll(/name:\s*"([^"]+)"[\s\S]*?categories:\s*\[([^\]]*)\]/g)) {
    const categories = [...match[2].matchAll(/"([^"]+)"/g)].map(found => found[1])
    charts.push({ name: match[1], categories })
  }
  return charts
}

/**
 * The inventory: for each docs page, the examples it shows and the style each is shown in; every
 * example once, with the file it comes from; and the ui sources, style sheets, charts and blocks.
 */
export function buildInventory(checkout, pins) {
  const at = path => join(checkout, path)
  const pages = {}
  const examples = {}

  for (const file of listFiles(at(PATHS.docs), '.mdx')) {
    const page = basename(file, '.mdx')
    const markdown = readFileSync(at(`${PATHS.docs}/${file}`), 'utf8')
    const meta = frontMatter(markdown)
    let parsed
    try {
      parsed = parsePreviews(markdown)
    } catch (error) {
      throw new Error(`${PATHS.docs}/${file}: ${error.message}`, { cause: error })
    }
    const previews = parsed.map(preview => {
      // The line is for messages, not the inventory, which shouldn't churn when prose moves.
      const entry = { ...preview }
      delete entry.line
      return entry
    })
    pages[page] = {
      title: meta.title ?? page,
      description: meta.description ?? '',
      file: `${PATHS.docs}/${file}`,
      examples: previews,
    }
    for (const preview of previews) {
      const entry = (examples[preview.name] ??= { pages: [] })
      if (!entry.pages.includes(page)) entry.pages.push(page)
      if (entry.styleName && entry.styleName !== preview.styleName) {
        throw new Error(
          `${preview.name} is shown in two styles (${entry.styleName}, ${preview.styleName})`,
        )
      }
      for (const key of PREVIEW_ATTRIBUTES) {
        if (preview[key] !== undefined && entry[key] === undefined) entry[key] = preview[key]
      }
    }
  }

  const missing = []
  for (const [name, entry] of Object.entries(examples)) {
    // Upstream's ComponentPreview falls back to base-nova when a page names no style.
    entry.styleName ??= 'base-nova'
    const { base, style } = splitStyleName(entry.styleName)
    entry.page = ownerPage(name, entry.pages)
    entry.base = base
    entry.style = style
    entry.file = `${PATHS.examples(base)}/${name}.tsx`
    if (!existsSync(at(entry.file))) missing.push(entry.file)
  }
  if (missing.length)
    throw new Error(`examples the docs pages show are missing:\n  ${missing.join('\n  ')}`)

  const ui = listFiles(at(PATHS.ui), '.tsx').map(file => basename(file, '.tsx'))
  const styles = listFiles(at(PATHS.styles), '.css').map(file =>
    basename(file, '.css').replace(/^style-/, ''),
  )

  const chartFiles = listFiles(at(PATHS.charts), '.tsx').map(file => basename(file, '.tsx'))
  const registryPath = at(`${PATHS.charts}/_registry.ts`)
  const categories = existsSync(registryPath)
    ? new Map(
        parseChartRegistry(readFileSync(registryPath, 'utf8')).map(c => [c.name, c.categories]),
      )
    : new Map()
  const charts = chartFiles.map(name => ({
    name,
    file: `${PATHS.charts}/${name}.tsx`,
    styleName: 'new-york-v4',
    categories: categories.get(name) ?? [],
  }))

  // A block is a folder with a page.tsx. The folders with only an index.tsx (preview,
  // preview-02, preview-03) are the design-system previews on upstream's /create page.
  const blocks = existsSync(at(PATHS.blocks))
    ? readdirSync(at(PATHS.blocks), { withFileTypes: true })
        .filter(
          entry => entry.isDirectory() && existsSync(at(`${PATHS.blocks}/${entry.name}/page.tsx`)),
        )
        .map(entry => entry.name)
        .sort()
        .map(name => ({ name, file: `${PATHS.blocks}/${name}/page.tsx`, styleName: 'radix-nova' }))
    : []

  const sortedExamples = Object.fromEntries(
    Object.keys(examples)
      .sort()
      .map(name => {
        const { page, pages: shownOn, styleName, base, style, file, ...layout } = examples[name]
        return [name, { page, pages: shownOn, styleName, base, style, file, ...layout }]
      }),
  )

  return {
    $comment:
      'Generated by `node scripts/upstream.mjs inventory` from the shadcn-ui/ui commit in upstream.json. Do not edit it.',
    commit: pins['shadcn-ui'].commit,
    counts: {
      pages: Object.keys(pages).length,
      previews: Object.values(pages).reduce((sum, page) => sum + page.examples.length, 0),
      examples: Object.keys(examples).length,
      ui: ui.length,
      styles: styles.length,
      charts: charts.length,
      blocks: blocks.length,
    },
    pages,
    examples: sortedExamples,
    ui: ui.map(name => ({ name, file: `${PATHS.ui}/${name}.tsx` })),
    styles: styles.map(name => ({ name, file: `${PATHS.styles}/style-${name}.css` })),
    charts,
    blocks,
  }
}

export function renderInventory(inventory) {
  return `${JSON.stringify(inventory, null, 2)}\n`
}

/** The committed inventory, or undefined before there is one. */
export function readInventory(root = repoRoot) {
  const path = join(root, INVENTORY_FILE)
  return existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) : undefined
}

function checkedOutAtPin(name, root, pins) {
  const dir = checkoutDir(name, root)
  const head = existsSync(join(dir, '.git'))
    ? git(['rev-parse', 'HEAD'], { cwd: dir, allowFailure: true }).stdout.trim()
    : ''
  if (head !== pins[name].commit) {
    throw new Error(
      `${UPSTREAM_DIR}/${name} is not at the commit in ${PINS_FILE}; run \`node scripts/upstream.mjs fetch\``,
    )
  }
  return dir
}

/** The `inventory` command. With `check`, compares instead of writing. */
export function writeInventory({ root = repoRoot, check = false, log = console.log } = {}) {
  const pins = readPins(root)
  const dir = checkedOutAtPin('shadcn-ui', root, pins)
  const rendered = renderInventory(buildInventory(dir, pins))
  const path = join(root, INVENTORY_FILE)
  if (check) {
    const current = existsSync(path) ? readFileSync(path, 'utf8') : ''
    if (current !== rendered) {
      throw new Error(`${INVENTORY_FILE} is stale; run \`node scripts/upstream.mjs inventory\``)
    }
    log(`${INVENTORY_FILE} is up to date`)
    return
  }
  mkdirSync(dirname(path), { recursive: true })
  writeFileSync(path, rendered)
  const { counts } = JSON.parse(rendered)
  log(
    `wrote ${INVENTORY_FILE}: ${counts.pages} pages, ${counts.examples} examples (${counts.previews} previews), ` +
      `${counts.ui} ui sources, ${counts.styles} styles, ${counts.charts} charts, ${counts.blocks} blocks`,
  )
}

// ---------------------------------------------------------------------------------------------
// Changes since the pins

/** `git diff --name-status` output as `{ status, path }` entries (A, M, D; T counts as M). */
export function parseNameStatus(output) {
  return output
    .split('\n')
    .filter(Boolean)
    .map(line => {
      const [status, ...paths] = line.split('\t')
      return { status: status[0] === 'T' ? 'M' : status[0], path: paths.at(-1) }
    })
}

/**
 * A style sheet's rules, by semantic class: `{ 'cn-button': '@apply …;' }`. Rules are compared
 * by their text, so formatting-only changes still show up (they are rare upstream).
 */
export function styleRules(css) {
  const rules = {}
  for (const match of css.matchAll(/^\s*(\.cn-[^{]+?)\s*\{([^}]*)\}/gm)) {
    const selector = match[1].trim()
    const subject = /\.(cn-[a-z0-9-]+)/.exec(selector)[1]
    rules[selector] = { subject, body: match[2].trim() }
  }
  return rules
}

/** The semantic classes whose rules differ between two versions of a style sheet. */
export function changedStyleClasses(before, after) {
  const a = styleRules(before)
  const b = styleRules(after)
  const changed = new Set()
  for (const selector of new Set([...Object.keys(a), ...Object.keys(b)])) {
    if (a[selector]?.body !== b[selector]?.body) changed.add((a[selector] ?? b[selector]).subject)
  }
  return [...changed].sort()
}

/**
 * The component a semantic class styles: the longest ui source name it starts with
 * (`cn-button-group-separator` is Button Group's, `cn-button-size-sm` is Button's).
 */
export function componentForClass(className, components) {
  const name = className.replace(/^[cj]n-/, '')
  return (
    [...components]
      .filter(component => name === component || name.startsWith(`${component}-`))
      .sort((a, b) => b.length - a.length)[0] ?? null
  )
}

/** The Joinery component an upstream example id belongs to, for examples not in the inventory. */
function componentForExample(name, inventory) {
  if (inventory?.examples?.[name]) return inventory.examples[name].page
  return componentForClass(name, Object.keys(inventory?.pages ?? {}))
}

/**
 * ember-primitives' modules (a file under `src/` by its name, or a folder) and the Joinery
 * components that cover them, from "ember-primitives parity" in JOINERY_PLAN.md: shadcn's page
 * name where Joinery's component has one, and otherwise the `@ember-joinery/primitives` subpath.
 * A module that isn't listed is reported as new.
 */
export const EMBER_PRIMITIVES = {
  // Components: the headless part of the matching shadcn component.
  accordion: ['accordion'],
  avatar: ['avatar'],
  breadcrumb: ['breadcrumb'],
  dialog: ['dialog', 'alert-dialog', 'sheet'],
  drawer: ['drawer'],
  menu: ['dropdown-menu', 'context-menu', 'menubar'],
  popover: ['popover'],
  progress: ['progress'],
  separator: ['separator'],
  slider: ['slider'],
  switch: ['switch'],
  tabs: ['tabs'],
  toggle: ['toggle'],
  'toggle-group': ['toggle-group'],
  'one-time-password': ['input-otp'],
  otp: ['input-otp'],
  resizable: ['resizable'],
  'command-palette': ['command'],
  // Components only ember-primitives has, and its building blocks.
  rating: ['rating'],
  'file-drop': ['file-drop'],
  form: ['native-form'],
  'floating-ui': ['anchor'],
  portal: ['portal'],
  'portal-targets': ['portal'],
  'visually-hidden': ['visually-hidden'],
  keys: ['keys'],
  'color-scheme': ['color-scheme'],
  tabster: ['focus'],
  scroller: ['scroller'],
  zoetrope: ['zoetrope'],
  hero: ['hero'],
  'sticky-footer': ['sticky-footer'],
  link: ['link'],
  'external-link': ['external-link'],
  heading: ['heading'],
  'incremental-each': ['incremental-each'],
  shadowed: ['shadowed'],
  // Utilities, one subpath each.
  head: ['head'],
  qp: ['qp'],
  service: ['service'],
  store: ['store'],
  'body-class': ['body-class'],
  'proper-links': ['proper-links'],
  iframe: ['iframe'],
  load: ['load'],
  viewport: ['viewport'],
  'in-viewport': ['viewport'],
  'on-resize': ['on-resize'],
  'resize-observer': ['on-resize'],
  'dom-context': ['dom-context'],
  narrowing: ['narrowing'],
  'type-utils': ['narrowing'],
  // Test helpers fold into @ember-joinery/test-support.
  a11y: ['test-support'],
  dom: ['test-support'],
  routing: ['test-support'],
}

// ember-primitives' own plumbing: barrels, registries, private helpers and dev-only styles.
const EMBER_PRIMITIVES_INTERNAL =
  /^(-private|index|helpers|utils|template-registry|styles|violations|test-support|components)$/

/** The ember-primitives module a file under `src/` belongs to (`components/layout/hero.gts` is `hero`). */
function emberPrimitivesModule(path) {
  const parts = path.replace(/^ember-primitives\/src\//, '').split('/')
  const stem = name => name.replace(/(\.css)?\.(gts|ts|js|css)$/, '')
  if (parts[0] === 'components') {
    if (parts[1] === 'layout' && parts[2]) return stem(parts[2])
    return parts[1] ? stem(parts[1]) : 'components'
  }
  if (['helpers', 'test-support', 'viewport'].includes(parts[0]) && parts[1]) return stem(parts[1])
  return stem(parts[0])
}

/**
 * What one changed upstream file means for Joinery: the component it belongs to (or null),
 * every Joinery component it touches (`components`, where there can be several), and what kind
 * of file it is.
 */
export function classifyChange(source, path, inventory) {
  const file = basename(path)
  const stem = file.replace(/\.[^.]+$/, '')
  if (source === 'ember-primitives') {
    const module = emberPrimitivesModule(path)
    const kind = path.includes('/src/components/') ? 'primitive' : 'primitive-utility'
    const components = EMBER_PRIMITIVES[module]
    if (components) return { kind, component: components[0], components, module }
    if (EMBER_PRIMITIVES_INTERNAL.test(module)) return { kind, component: null, module }
    return { kind, component: null, module, unknown: true }
  }
  // Registries (`_registry.ts`) and tests describe upstream's build, not a component.
  if (file.startsWith('_') || /\.test\.[^.]+$/.test(file))
    return { kind: 'ignored', component: null }
  if (path.startsWith(`${PATHS.ui}/`)) return { kind: 'ui', component: stem }
  if (path.startsWith('packages/react/src/')) {
    // @shadcn/react: the headless behaviour behind the chat set, one folder per component.
    const folder = path.split('/')[3]
    return { kind: 'headless', component: folder?.includes('.') ? null : folder }
  }
  if (path.startsWith(`${PATHS.docs}/`))
    return { kind: 'docs', component: stem === 'meta' ? null : stem }
  if (path.startsWith(`${PATHS.styles}/`))
    return { kind: 'style', component: null, style: stem.replace(/^style-/, '') }
  if (path.startsWith(`${PATHS.charts}/`))
    return { kind: 'chart', component: 'chart', example: stem }
  if (path.startsWith(`${PATHS.blocks}/`)) {
    return {
      kind: 'block',
      component: null,
      block: path.slice(PATHS.blocks.length + 1).split('/')[0],
    }
  }
  for (const base of ['radix', 'base']) {
    if (path.startsWith(`${PATHS.examples(base)}/`)) {
      const known = inventory?.examples?.[stem]
      // Base UI examples matter only where a Radix docs page shows them.
      if (base === 'base' && known?.base !== 'base') return { kind: 'ignored', component: null }
      const component = componentForExample(stem, inventory)
      // An example no docs page shows (yet) is listed on its own.
      return component
        ? { kind: 'example', component, example: stem }
        : { kind: 'unlisted-example', component: null, example: stem }
    }
  }
  return { kind: 'other', component: null }
}

/**
 * Folds changed files into a report: by component, the new upstream components, the style
 * rules that changed, and anything that maps to no component.
 */
export function buildChangesReport({ pins: allPins, heads, files, styleChanges = {}, inventory }) {
  const pins = Object.fromEntries(Object.keys(SOURCES).map(name => [name, allPins[name]]))
  const components = {}
  const added = []
  const other = []
  const blocks = {}
  const unlisted = []
  const touch = (component, entry) => (components[component] ??= []).push(entry)
  const known = new Set([
    ...(inventory?.ui ?? []).map(u => u.name),
    ...Object.keys(inventory?.pages ?? {}),
  ])

  for (const { source, status, path } of files) {
    const change = classifyChange(source, path, inventory)
    if (change.kind === 'ignored') continue
    const entry = {
      source,
      status,
      path,
      kind: change.kind,
      ...(change.example && { example: change.example }),
    }
    if (change.kind === 'unlisted-example') {
      unlisted.push(entry)
    } else if (change.kind === 'block') {
      ;(blocks[change.block] ??= []).push(entry)
    } else if (change.kind === 'style') {
      // Rule-level changes are attributed below; the file itself is listed once here.
      other.push(entry)
    } else if (change.component) {
      for (const component of change.components ?? [change.component]) touch(component, entry)
      if (
        status === 'A' &&
        (change.kind === 'ui' || change.kind === 'docs') &&
        !known.has(change.component)
      ) {
        if (!added.includes(change.component)) added.push(change.component)
      }
    } else {
      // An ember-primitives module Joinery doesn't map yet is new to Joinery.
      if (change.unknown) {
        entry.module = change.module
        const name = `ember-primitives: ${change.module}`
        if (status === 'A' && !added.includes(name)) added.push(name)
      }
      other.push(entry)
    }
  }

  const componentNames = [...known, ...added]
  for (const [style, classes] of Object.entries(styleChanges)) {
    for (const className of classes) {
      const component = componentForClass(className, componentNames) ?? '(unmatched style rules)'
      const list = (components[component] ??= [])
      const existing = list.find(entry => entry.kind === 'style-rules')
      if (existing) {
        if (!existing.styles.includes(style)) existing.styles.push(style)
        if (!existing.classes.includes(className)) existing.classes.push(className)
      } else {
        list.push({
          source: 'shadcn-ui',
          kind: 'style-rules',
          styles: [style],
          classes: [className],
        })
      }
    }
  }

  const sortedComponents = Object.fromEntries(
    Object.keys(components)
      .sort()
      .map(name => [name, components[name]]),
  )
  return { pins, heads, components: sortedComponents, added: added.sort(), blocks, unlisted, other }
}

const short = sha => sha.slice(0, 7)
const commitLink = (repo, sha) => `[\`${short(sha)}\`](https://github.com/${repo}/commit/${sha})`

/** The tracking issue's body. The first line marks the issue, so the workflow can find it. */
export function renderChangesMarkdown(report) {
  const lines = ['<!-- joinery-upstream-watch -->', '## Upstream changes since the last sync', '']
  for (const [name, pin] of Object.entries(report.pins)) {
    if (!SOURCES[name]) continue
    const head = report.heads[name]
    if (!head || head.commit === pin.commit) {
      lines.push(`- **${pin.repo}**: up to date at ${commitLink(pin.repo, pin.commit)}.`)
    } else {
      lines.push(
        `- **${pin.repo}**: ${commitLink(pin.repo, pin.commit)} (pinned) → ${commitLink(pin.repo, head.commit)}` +
          ` (\`${pin.branch ?? 'main'}\`, ${head.date ?? 'unknown date'}), ` +
          `[compare](https://github.com/${pin.repo}/compare/${pin.commit}...${head.commit}).`,
      )
    }
  }
  lines.push('')

  const names = Object.keys(report.components)
  const unlisted = report.unlisted ?? []
  if (
    !names.length &&
    !report.added.length &&
    !Object.keys(report.blocks).length &&
    !unlisted.length &&
    !report.other.length
  ) {
    lines.push('Nothing Joinery tracks has changed.')
    return `${lines.join('\n')}\n`
  }

  if (report.added.length) {
    lines.push('### New upstream components', '')
    for (const name of report.added) lines.push(`- \`${name}\``)
    lines.push('')
  }

  if (names.length) {
    lines.push('### By component', '', '| Component | What changed |', '| --- | --- |')
    for (const name of names) {
      const parts = report.components[name].map(entry => {
        if (entry.kind === 'style-rules') {
          return `style rules in ${entry.styles.join(', ')}: ${entry.classes.map(c => `\`${c}\``).join(', ')}`
        }
        const label = entry.example ?? basename(entry.path)
        return `${entry.kind} \`${label}\` (${entry.status})`
      })
      lines.push(`| ${name} | ${parts.join('<br>')} |`)
    }
    lines.push('')
  }

  if (Object.keys(report.blocks).length) {
    lines.push('### Blocks', '')
    for (const [block, entries] of Object.entries(report.blocks)) {
      lines.push(
        `- \`${block}\`: ${entries.map(e => `\`${e.path.split('/').slice(-1)[0]}\` (${e.status})`).join(', ')}`,
      )
    }
    lines.push('')
  }

  if (unlisted.length) {
    lines.push(
      '### Examples no docs page shows',
      '',
      '<details><summary>' + unlisted.length + ' examples</summary>',
      '',
      ...unlisted.map(entry => `- \`${entry.example}\` (${entry.status})`),
      '',
      '</details>',
      '',
    )
  }

  if (report.other.length) {
    lines.push('### Other files', '')
    for (const entry of report.other)
      lines.push(`- ${entry.source}: \`${entry.path}\` (${entry.status})`)
    lines.push('')
  }

  lines.push(
    'A sync PR ports these changes and moves `upstream.json` to the new commits (see "Upstream sync" in CONTRIBUTING.md).',
  )
  return `${lines.join('\n')}\n`
}

/** GitHub refuses an issue body over 65,536 characters; this leaves room to spare. */
export const ISSUE_BODY_LIMIT = 65000

/**
 * The report cut to fit an issue body: whole lines up to the limit, any open `<details>`
 * closed, and a last line saying where the whole report is (`link`, the workflow run).
 */
export function fitIssueBody(markdown, { limit = ISSUE_BODY_LIMIT, link } = {}) {
  if (markdown.length <= limit) return markdown
  const footer = [
    '',
    `**Cut short to fit an issue.** The whole report is in ${link ? `[the workflow run's summary](${link})` : "the workflow run's summary"}.`,
    '',
  ].join('\n')
  const kept = []
  let length = 0
  let open = 0
  for (const line of markdown.split('\n')) {
    const closing = open > 0 ? '\n</details>\n'.length * open : 0
    if (length + line.length + 1 + closing + footer.length > limit) break
    kept.push(line)
    length += line.length + 1
    open += (line.match(/<details>/g) ?? []).length - (line.match(/<\/details>/g) ?? []).length
  }
  for (; open > 0; open--) kept.push('', '</details>')
  return `${kept.join('\n')}\n${footer}`
}

/** Fetches the branch head of a source (shallow, blobless) and lists the watched files that differ. */
async function sourceChanges(name, { root, pins }) {
  const pin = pins[name]
  const dir = await fetchSource(name, { root, pins, log: () => {} })
  await gitNetwork(
    ['fetch', '--quiet', '--depth=1', '--filter=blob:none', 'origin', pin.branch ?? 'main'],
    { cwd: dir },
  )
  const head = git(['rev-parse', 'FETCH_HEAD'], { cwd: dir }).stdout.trim()
  const date = git(['log', '-1', '--format=%cs', head], { cwd: dir }).stdout.trim()
  const diff = git(
    ['diff', '--no-renames', '--name-status', pin.commit, head, '--', ...SOURCES[name].watch],
    {
      cwd: dir,
    },
  ).stdout
  const files = parseNameStatus(diff).map(file => ({ source: name, ...file }))

  const styleChanges = {}
  for (const file of files) {
    if (
      name !== 'shadcn-ui' ||
      !file.path.startsWith(`${PATHS.styles}/`) ||
      !file.path.endsWith('.css')
    )
      continue
    const show = rev =>
      git(['show', `${rev}:${file.path}`], { cwd: dir, allowFailure: true }).stdout ?? ''
    const style = basename(file.path, '.css').replace(/^style-/, '')
    styleChanges[style] = changedStyleClasses(show(pin.commit), show(head))
  }
  return { head: { commit: head, date }, files, styleChanges }
}

/** The `changes` command. */
export async function changes({ root = repoRoot, json = false } = {}) {
  const pins = readPins(root)
  const heads = {}
  const files = []
  const styleChanges = {}
  for (const name of Object.keys(SOURCES)) {
    const result = await sourceChanges(name, { root, pins })
    heads[name] = result.head
    files.push(...result.files)
    Object.assign(styleChanges, result.styleChanges)
  }
  const report = buildChangesReport({
    pins,
    heads,
    files,
    styleChanges,
    inventory: readInventory(root),
  })
  return json ? `${JSON.stringify(report, null, 2)}\n` : renderChangesMarkdown(report)
}

// ---------------------------------------------------------------------------------------------

async function main(argv) {
  const [command, ...rest] = argv
  const flag = name => rest.includes(name)
  const option = name => {
    const index = rest.indexOf(name)
    return index === -1 ? undefined : rest[index + 1]
  }
  switch (command) {
    case 'fetch':
      return fetchAll()
    case 'inventory':
      return writeInventory({ check: flag('--check') })
    case 'changes': {
      const output = await changes({ json: flag('--json') })
      const out = option('--out')
      if (out) writeFileSync(resolve(out), output)
      else process.stdout.write(output)
      // The tracking issue's copy, cut to GitHub's limit, linking to this run when in Actions.
      const issue = option('--issue-body')
      if (issue) {
        const {
          GITHUB_SERVER_URL: server,
          GITHUB_REPOSITORY: repo,
          GITHUB_RUN_ID: run,
        } = process.env
        const link = server && repo && run ? `${server}/${repo}/actions/runs/${run}` : undefined
        writeFileSync(resolve(issue), fitIssueBody(output, { link }))
      }
      return
    }
    default:
      console.error(
        'usage: node scripts/upstream.mjs <fetch | inventory [--check] | changes [--json] [--out <file>] [--issue-body <file>]>',
      )
      process.exitCode = 1
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).catch(error => {
    console.error(error.message)
    process.exitCode = 1
  })
}
