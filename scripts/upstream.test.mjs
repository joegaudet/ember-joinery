import { test } from 'node:test'
import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import {
  PATHS,
  SOURCES,
  buildChangesReport,
  buildInventory,
  changedStyleClasses,
  checkoutDir,
  classifyChange,
  componentForClass,
  fetchSource,
  frontMatter,
  ownerPage,
  parseChartRegistry,
  parseNameStatus,
  parsePreviews,
  readPins,
  renderChangesMarkdown,
  splitStyleName,
  stripFences,
  styleRules,
  writeInventory,
} from './upstream.mjs'

/** A throwaway directory holding the given files. */
function fixture(files, root = mkdtempSync(join(tmpdir(), 'upstream-'))) {
  for (const [path, source] of Object.entries(files)) {
    mkdirSync(dirname(join(root, path)), { recursive: true })
    writeFileSync(join(root, path), source)
  }
  return root
}

const git = (cwd, ...args) => {
  const result = spawnSync('git', args, { cwd, encoding: 'utf8' })
  assert.equal(result.status, 0, result.stderr)
  return result.stdout.trim()
}

const BUTTON_PAGE = `---
title: Button
description: Displays a button.
---

<ComponentPreview styleName="radix-nova" name="button-demo" />

\`\`\`tsx
<ComponentPreview styleName="radix-nova" name="not-a-preview" />
\`\`\`

<ComponentPreview
  styleName="radix-nova"
  name="button-group-demo"
  previewClassName="h-80"
  align="start"
  hideCode
/>

<ComponentPreview styleName="radix-nova" name="button-rtl" direction="rtl" />
`

const GROUP_PAGE = `---
title: Button Group
---

<ComponentPreview styleName="radix-nova" name="button-group-demo" />
<ComponentPreview styleName="base-nova" name="button-group-base" />
`

const CHART_REGISTRY = `export const charts = [
  {
    name: "chart-area-default",
    type: "registry:block",
    files: [{ path: "charts/chart-area-default.tsx", type: "registry:block" }],
    categories: ["charts", "charts-area"],
  },
]
`

/** An upstream checkout with two docs pages, their examples, ui, styles, a chart and a block. */
function upstreamFiles() {
  return {
    [`${PATHS.docs}/button.mdx`]: BUTTON_PAGE,
    [`${PATHS.docs}/button-group.mdx`]: GROUP_PAGE,
    [`${PATHS.docs}/toast.mdx`]: '---\ntitle: Toast\n---\n\nNo previews.\n',
    [`${PATHS.docs}/meta.json`]: '{}',
    [`${PATHS.examples('radix')}/button-demo.tsx`]: 'export default function A() {}',
    [`${PATHS.examples('radix')}/button-group-demo.tsx`]: 'export default function A() {}',
    [`${PATHS.examples('radix')}/button-rtl.tsx`]: 'export function ButtonRtl() {}',
    [`${PATHS.examples('base')}/button-group-base.tsx`]: 'export default function A() {}',
    [`${PATHS.ui}/button.tsx`]: 'export {}',
    [`${PATHS.ui}/button-group.tsx`]: 'export {}',
    [`${PATHS.ui}/_registry.ts`]: 'export {}',
    [`${PATHS.styles}/style-nova.css`]: '.style-nova {\n  .cn-button {\n    @apply h-8;\n  }\n}\n',
    [`${PATHS.charts}/_registry.ts`]: CHART_REGISTRY,
    [`${PATHS.charts}/chart-area-default.tsx`]: 'export default function C() {}',
    [`${PATHS.blocks}/login-01/page.tsx`]: 'export default function P() {}',
    [`${PATHS.blocks}/preview/index.tsx`]: 'export default function P() {}',
  }
}

const PINS = {
  'shadcn-ui': { repo: 'shadcn-ui/ui', branch: 'main', commit: 'a'.repeat(40) },
  'ember-primitives': {
    repo: 'universal-ember/ember-primitives',
    branch: 'main',
    commit: 'b'.repeat(40),
  },
}

test('readPins needs a repo and a full sha for each source', () => {
  const root = fixture({ 'upstream.json': JSON.stringify(PINS) })
  try {
    assert.equal(readPins(root)['shadcn-ui'].commit, 'a'.repeat(40))
    writeFileSync(
      join(root, 'upstream.json'),
      JSON.stringify({ ...PINS, 'shadcn-ui': { repo: 'x/y', commit: 'abc' } }),
    )
    assert.throws(() => readPins(root), /full commit sha/)
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})

test('parsePreviews reads every preview, single- or multi-line, and skips code samples', () => {
  const previews = parsePreviews(BUTTON_PAGE)
  assert.deepEqual(
    previews.map(preview =>
      Object.fromEntries(Object.entries(preview).filter(([key]) => key !== 'line')),
    ),
    [
      { name: 'button-demo', styleName: 'radix-nova' },
      {
        name: 'button-group-demo',
        styleName: 'radix-nova',
        align: 'start',
        previewClassName: 'h-80',
        hideCode: true,
      },
      { name: 'button-rtl', styleName: 'radix-nova', direction: 'rtl' },
    ],
  )
  assert.equal(previews[0].line, 6)
})

test('stripFences blanks fenced code but keeps the line count', () => {
  const markdown = 'a\n```tsx\n<X />\n```\nb\n'
  const stripped = stripFences(markdown)
  assert.equal(stripped.split('\n').length, markdown.split('\n').length)
  assert.doesNotMatch(stripped, /<X/)
  assert.match(stripped, /^a\n[\s\S]*\nb\n$/)
})

test('frontMatter, splitStyleName and ownerPage', () => {
  assert.deepEqual(frontMatter('---\ntitle: "Button"\nbase: radix\n---\n'), {
    title: 'Button',
    base: 'radix',
  })
  assert.deepEqual(splitStyleName('radix-nova'), { base: 'radix', style: 'nova' })
  assert.deepEqual(splitStyleName('base-rhea'), { base: 'base', style: 'rhea' })
  assert.throws(() => splitStyleName('new-york-v4'), /unknown styleName/)
  assert.equal(ownerPage('button-group-demo', ['button', 'button-group']), 'button-group')
  assert.equal(ownerPage('card-rtl', ['card', 'direction']), 'card')
  assert.equal(ownerPage('field-demo', ['label', 'field']), 'field')
})

test('parseChartRegistry lists the gallery with its categories', () => {
  assert.deepEqual(parseChartRegistry(CHART_REGISTRY), [
    { name: 'chart-area-default', categories: ['charts', 'charts-area'] },
  ])
})

test('buildInventory lists pages, each example once, ui, styles, charts and blocks', () => {
  const root = fixture(upstreamFiles())
  try {
    const inventory = buildInventory(root, PINS)
    assert.equal(inventory.commit, PINS['shadcn-ui'].commit)
    assert.deepEqual(inventory.counts, {
      pages: 3,
      previews: 5,
      examples: 4,
      ui: 2,
      styles: 1,
      charts: 1,
      blocks: 1,
    })
    assert.deepEqual(Object.keys(inventory.pages), ['button', 'button-group', 'toast'])
    assert.equal(inventory.pages.button.title, 'Button')
    assert.deepEqual(inventory.pages.toast.examples, [])
    assert.deepEqual(inventory.examples['button-group-demo'], {
      page: 'button-group',
      pages: ['button', 'button-group'],
      styleName: 'radix-nova',
      base: 'radix',
      style: 'nova',
      file: `${PATHS.examples('radix')}/button-group-demo.tsx`,
      align: 'start',
      previewClassName: 'h-80',
    })
    assert.equal(inventory.examples['button-rtl'].direction, 'rtl')
    assert.equal(
      inventory.examples['button-group-base'].file,
      `${PATHS.examples('base')}/button-group-base.tsx`,
    )
    assert.deepEqual(
      inventory.ui.map(ui => ui.name),
      ['button', 'button-group'],
    )
    assert.deepEqual(inventory.styles, [{ name: 'nova', file: `${PATHS.styles}/style-nova.css` }])
    assert.deepEqual(inventory.charts[0].categories, ['charts', 'charts-area'])
    assert.deepEqual(
      inventory.blocks.map(block => [block.name, block.file]),
      [['login-01', `${PATHS.blocks}/login-01/page.tsx`]],
      'design-system previews (an index.tsx, no page.tsx) are not blocks',
    )
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})

test('buildInventory fails when a docs page shows an example that has no file', () => {
  const files = upstreamFiles()
  delete files[`${PATHS.examples('radix')}/button-rtl.tsx`]
  const root = fixture(files)
  try {
    assert.throws(() => buildInventory(root, PINS), /missing:\n.*button-rtl\.tsx/)
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})

test('fetch makes a sparse, shallow checkout of the pin, and inventory reads it', async () => {
  const work = mkdtempSync(join(tmpdir(), 'upstream-fetch-'))
  try {
    // A local "upstream" repository standing in for GitHub.
    const remote = fixture(
      { ...upstreamFiles(), 'apps/v4/next.config.mjs': 'export default {}' },
      join(work, 'remote'),
    )
    git(remote, 'init', '--quiet')
    git(remote, 'config', 'uploadpack.allowFilter', 'true')
    git(remote, 'config', 'uploadpack.allowAnySHA1InWant', 'true')
    git(remote, 'add', '-A')
    git(remote, '-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '--quiet', '-m', 'one')
    const commit = git(remote, 'rev-parse', 'HEAD')

    const root = join(work, 'joinery')
    const pins = {
      'shadcn-ui': { repo: 'shadcn-ui/ui', commit, url: `file://${remote}` },
      'ember-primitives': PINS['ember-primitives'],
    }
    fixture({ 'upstream.json': JSON.stringify(pins) }, root)
    const logs = []
    await fetchSource('shadcn-ui', { root, log: line => logs.push(line) })
    const dir = checkoutDir('shadcn-ui', root)
    assert.equal(git(dir, 'rev-parse', 'HEAD'), commit)
    assert.ok(existsSync(join(dir, PATHS.ui, 'button.tsx')), 'a sparse path is checked out')
    assert.ok(!existsSync(join(dir, 'apps/v4/next.config.mjs')), 'other paths are not')
    assert.equal(git(dir, 'sparse-checkout', 'list'), SOURCES['shadcn-ui'].sparse.join('\n'))

    await fetchSource('shadcn-ui', { root, log: line => logs.push(line) })
    assert.match(logs.at(-1), /up to date/)

    writeInventory({ root, log: () => {} })
    const written = JSON.parse(readFileSync(join(root, 'upstream/inventory.json'), 'utf8'))
    assert.equal(written.counts.examples, 4)
    writeInventory({ root, check: true, log: () => {} })
    writeFileSync(join(root, 'upstream/inventory.json'), '{}\n')
    assert.throws(() => writeInventory({ root, check: true, log: () => {} }), /stale/)
  } finally {
    rmSync(work, { recursive: true, force: true })
  }
})

test('parseNameStatus reads git diff --name-status', () => {
  assert.deepEqual(parseNameStatus('A\ta.tsx\nM\tb.css\nD\tc.mdx\nT\td.ts\n'), [
    { status: 'A', path: 'a.tsx' },
    { status: 'M', path: 'b.css' },
    { status: 'D', path: 'c.mdx' },
    { status: 'M', path: 'd.ts' },
  ])
})

test('changedStyleClasses names the rules that differ between two sheets', () => {
  const before =
    '.style-nova {\n  .cn-button {\n    @apply h-8;\n  }\n  .cn-badge {\n    @apply h-5;\n  }\n}\n'
  const after =
    '.style-nova {\n  .cn-button {\n    @apply h-9;\n  }\n  .cn-badge {\n    @apply h-5;\n  }\n  .cn-kbd {\n    @apply h-5;\n  }\n}\n'
  assert.deepEqual(Object.keys(styleRules(before)), ['.cn-button', '.cn-badge'])
  assert.deepEqual(changedStyleClasses(before, after), ['cn-button', 'cn-kbd'])
  assert.deepEqual(changedStyleClasses(after, before), ['cn-button', 'cn-kbd'])
})

test('componentForClass picks the longest component a class starts with', () => {
  const components = ['button', 'button-group', 'alert', 'alert-dialog']
  assert.equal(componentForClass('cn-button-size-sm', components), 'button')
  assert.equal(componentForClass('cn-button-group-separator', components), 'button-group')
  assert.equal(componentForClass('jn-alert-dialog-title', components), 'alert-dialog')
  assert.equal(componentForClass('cn-unknown', components), null)
})

test('classifyChange maps upstream files to Joinery components', () => {
  const inventory = {
    examples: {
      'button-group-demo': { page: 'button-group', base: 'radix' },
      'combobox-basic': { page: 'combobox', base: 'base' },
    },
    pages: { button: {}, 'button-group': {}, combobox: {} },
  }
  const cases = [
    [`${PATHS.ui}/button.tsx`, { kind: 'ui', component: 'button' }],
    [`${PATHS.ui}/_registry.ts`, { kind: 'ignored', component: null }],
    [`${PATHS.docs}/button.mdx`, { kind: 'docs', component: 'button' }],
    [`${PATHS.styles}/style-nova.css`, { kind: 'style', component: null, style: 'nova' }],
    [
      `${PATHS.charts}/chart-bar-default.tsx`,
      { kind: 'chart', component: 'chart', example: 'chart-bar-default' },
    ],
    [`${PATHS.blocks}/login-01/page.tsx`, { kind: 'block', component: null, block: 'login-01' }],
    [
      `${PATHS.examples('radix')}/button-group-demo.tsx`,
      { kind: 'example', component: 'button-group', example: 'button-group-demo' },
    ],
    [
      `${PATHS.examples('radix')}/button-new.tsx`,
      { kind: 'example', component: 'button', example: 'button-new' },
    ],
    [
      `${PATHS.examples('radix')}/chat-demo.tsx`,
      { kind: 'unlisted-example', component: null, example: 'chat-demo' },
    ],
    [
      `${PATHS.examples('base')}/combobox-basic.tsx`,
      { kind: 'example', component: 'combobox', example: 'combobox-basic' },
    ],
    [`${PATHS.examples('base')}/button-demo.tsx`, { kind: 'ignored', component: null }],
    [
      'packages/react/src/message-scroller/use-x.ts',
      { kind: 'headless', component: 'message-scroller' },
    ],
    ['packages/react/src/message-scroller/x.test.tsx', { kind: 'ignored', component: null }],
  ]
  for (const [path, expected] of cases)
    assert.deepEqual(classifyChange('shadcn-ui', path, inventory), expected, path)
  assert.deepEqual(
    classifyChange(
      'ember-primitives',
      'ember-primitives/src/components/accordion/item.gts',
      inventory,
    ),
    {
      kind: 'primitive',
      component: 'accordion',
    },
  )
  assert.deepEqual(
    classifyChange('ember-primitives', 'ember-primitives/src/components/rating.gts', inventory),
    {
      kind: 'primitive',
      component: 'rating',
    },
  )
  assert.deepEqual(
    classifyChange('ember-primitives', 'ember-primitives/src/color-scheme.ts', inventory),
    {
      kind: 'primitive-utility',
      component: 'color-scheme',
    },
  )
})

test('the changes report groups by component and renders the tracking issue', () => {
  const inventory = {
    examples: { 'button-demo': { page: 'button', base: 'radix' } },
    pages: { button: {} },
    ui: [{ name: 'button' }],
  }
  const pins = { $comment: 'x', ...PINS }
  const heads = {
    'shadcn-ui': { commit: 'c'.repeat(40), date: '2026-11-15' },
    'ember-primitives': { commit: PINS['ember-primitives'].commit, date: '2026-11-06' },
  }
  const files = [
    { source: 'shadcn-ui', status: 'M', path: `${PATHS.examples('radix')}/button-demo.tsx` },
    { source: 'shadcn-ui', status: 'A', path: `${PATHS.ui}/gauge.tsx` },
    { source: 'shadcn-ui', status: 'A', path: `${PATHS.docs}/gauge.mdx` },
    { source: 'shadcn-ui', status: 'M', path: `${PATHS.styles}/style-nova.css` },
    { source: 'shadcn-ui', status: 'M', path: `${PATHS.blocks}/login-01/page.tsx` },
    { source: 'shadcn-ui', status: 'A', path: `${PATHS.examples('radix')}/chat-demo.tsx` },
  ]
  const report = buildChangesReport({
    pins,
    heads,
    files,
    styleChanges: { nova: ['cn-button', 'cn-gauge-track'], lyra: ['cn-button'] },
    inventory,
  })
  assert.deepEqual(Object.keys(report.pins), ['shadcn-ui', 'ember-primitives'])
  assert.deepEqual(report.added, ['gauge'])
  assert.deepEqual(Object.keys(report.components), ['button', 'gauge'])
  assert.deepEqual(report.components.button.at(-1), {
    source: 'shadcn-ui',
    kind: 'style-rules',
    styles: ['nova', 'lyra'],
    classes: ['cn-button'],
  })
  assert.deepEqual(Object.keys(report.blocks), ['login-01'])
  assert.deepEqual(
    report.unlisted.map(entry => entry.example),
    ['chat-demo'],
  )
  assert.deepEqual(
    report.other.map(entry => entry.path),
    [`${PATHS.styles}/style-nova.css`],
  )

  const markdown = renderChangesMarkdown(report)
  assert.match(markdown, /^<!-- joinery-upstream-watch -->\n/)
  assert.match(markdown, /\*\*shadcn-ui\/ui\*\*: \[`aaaaaaa`\].*→ \[`ccccccc`\].*2026-11-15/)
  assert.match(markdown, /\*\*universal-ember\/ember-primitives\*\*: up to date/)
  assert.match(markdown, /### New upstream components\n\n- `gauge`/)
  assert.match(
    markdown,
    /\| button \| example `button-demo` \(M\)<br>style rules in nova, lyra: `cn-button` \|/,
  )
  assert.match(markdown, /### Blocks\n\n- `login-01`: `page.tsx` \(M\)/)
  assert.match(markdown, /<summary>1 examples<\/summary>/)
})

test('an unchanged upstream renders as up to date', () => {
  const heads = {
    'shadcn-ui': { commit: PINS['shadcn-ui'].commit },
    'ember-primitives': { commit: PINS['ember-primitives'].commit },
  }
  const markdown = renderChangesMarkdown(
    buildChangesReport({ pins: PINS, heads, files: [], inventory: {} }),
  )
  assert.match(markdown, /Nothing Joinery tracks has changed\./)
})
