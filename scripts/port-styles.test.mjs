import { test } from 'node:test'
import assert from 'node:assert/strict'
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import {
  OUTPUT_DIR,
  checkPorted,
  logicalApply,
  portStyle,
  portStyles,
  renameClasses,
  splitSelectorList,
  unwrapStyleScope,
  whereSelectors,
} from './port-styles.mjs'
import { PATHS } from './upstream.mjs'

const NOVA = `.style-nova {
  /* MARK: Button */
  .cn-button {
    @apply rounded-lg border has-[>svg]:gap-1 [&_.cn-icon]:size-4;
  }

  .cn-card-content:has(> [data-slot=questionnaire-choices]) {
    @apply pt-0;
  }
}
`

test('renameClasses renames cn- classes only', () => {
  assert.equal(
    renameClasses(
      '.cn-button { @apply [&_.cn-icon]:size-4 group-has-[.cn-x]/a:p-1; } /* shadcn-ui */',
    ),
    '.jn-button { @apply [&_.jn-icon]:size-4 group-has-[.jn-x]/a:p-1; } /* shadcn-ui */',
  )
})

test('unwrapStyleScope drops the .style-<name> block and dedents it', () => {
  assert.equal(
    unwrapStyleScope(NOVA, 'nova'),
    `/* MARK: Button */
.cn-button {
  @apply rounded-lg border has-[>svg]:gap-1 [&_.cn-icon]:size-4;
}

.cn-card-content:has(> [data-slot=questionnaire-choices]) {
  @apply pt-0;
}
`,
  )
  assert.equal(
    unwrapStyleScope('/* A comment,\n   two lines. */\n\n.style-nova {\n  .cn-a {}\n}\n', 'nova'),
    '.cn-a {}\n',
    'comments before the wrapper are fine',
  )
  assert.throws(
    () => unwrapStyleScope('.cn-a {}\n', 'nova'),
    /expected its rules inside one \.style-nova \{ … \} block, found: \.cn-a \{\}/,
  )
  assert.throws(
    () => unwrapStyleScope('/* x */\n.style-lyra {\n  .cn-a {}\n}\n', 'nova'),
    /found: \.style-lyra \{/,
  )
  assert.throws(
    () => unwrapStyleScope('.style-nova {\n  .cn-a {}\n}\n.cn-b {\n}\n', 'nova'),
    /unexpected indentation: \}/,
    'a rule after the wrapper',
  )
  assert.throws(
    () => unwrapStyleScope('.style-nova {\n.cn-a {}\n}\n', 'nova'),
    /unexpected indentation/,
  )
})

test('whereSelectors puts top-level selectors in :where()', () => {
  assert.equal(
    whereSelectors('.jn-a {\n  @apply p-1;\n}\n.jn-b:has(> [x]) {\n}\n.jn-c, .jn-d {\n}\n'),
    ':where(.jn-a) {\n  @apply p-1;\n}\n:where(.jn-b:has(> [x])) {\n}\n:where(.jn-c), :where(.jn-d) {\n}\n',
  )
})

test('splitSelectorList splits at top-level commas only', () => {
  assert.deepEqual(splitSelectorList('.a:is(.b, .c), .d[data-x="1,2"] ,.e'), [
    '.a:is(.b, .c)',
    '.d[data-x="1,2"]',
    '.e',
  ])
  assert.equal(
    whereSelectors('.jn-x:is(.a, .b), .jn-y {\n}\n'),
    ':where(.jn-x:is(.a, .b)), :where(.jn-y) {\n}\n',
  )
})

test('checkPorted fails on anything the port would let through', () => {
  assert.equal(
    checkPorted(':where(.jn-a) {\n  @apply p-1;\n}\n/* .cn-old {\n}*/\n', 'nova').length > 0,
    true,
  )
  assert.throws(
    () => checkPorted(':where(.jn-a) {\n  .jn-b {\n    @apply p-1;\n  }\n}\n', 'nova'),
    /line 2: a nested rule or block: \.jn-b \{/,
  )
  assert.throws(
    () => checkPorted('@media (width >= 40rem) {\n}\n', 'nova'),
    /line 1: not in :where\(\): @media/,
  )
  assert.throws(
    () => checkPorted(':where(.jn-a) {\n  @apply [&_.cn-b]:p-1;\n}\n', 'nova'),
    /a cn- class is left/,
  )
  assert.throws(
    () => portStyle('.cn-a {\n}\n', { style: 'nova', commit: 'a'.repeat(40) }),
    /expected its rules/,
  )
})

test('portStyle ports a sheet with a header naming its source', () => {
  const ported = portStyle(NOVA, {
    style: 'nova',
    commit: '8ab27715521cbd4f87ae6886cd989cbb678f6de7',
  })
  assert.match(ported, /^\/\*\n \* The Nova style, ported from shadcn-ui\/ui@8ab2771\n/)
  assert.match(ported, /Do not edit it/)
  assert.match(
    ported,
    /\n\/\* MARK: Button \*\/\n:where\(\.jn-button\) \{\n {2}@apply rounded-lg border has-\[>svg\]:gap-1 \[&_\.jn-icon\]:size-4;\n\}\n/,
  )
  assert.match(
    ported,
    /:where\(\.jn-card-content:has\(> \[data-slot=questionnaire-choices\]\)\) \{/,
  )
  assert.doesNotMatch(ported, /\bcn-|style-nova \{/)
})

test('logicalApply makes each @apply list work in both directions', () => {
  assert.equal(
    logicalApply(
      ':where(.jn-x) {\n  @apply pl-2 has-data-[icon=inline-end]:pr-1.5 text-left;\n}\n',
    ),
    ':where(.jn-x) {\n  @apply ps-2 has-data-[icon=inline-end]:pe-1.5 text-start;\n}\n',
  )
  const ported = portStyle(
    '.style-nova {\n  .cn-alert-action {\n    @apply absolute top-2 right-2;\n  }\n}\n',
    { style: 'nova', commit: '8ab27715521cbd4f87ae6886cd989cbb678f6de7' },
  )
  assert.match(ported, /@apply absolute top-2 end-2;/)
})

test('portStyles writes every sheet, and --check finds stale ones', () => {
  const root = mkdtempSync(join(tmpdir(), 'port-styles-'))
  const write = (path, content) => {
    mkdirSync(dirname(join(root, path)), { recursive: true })
    writeFileSync(join(root, path), content)
  }
  try {
    write(
      'upstream.json',
      JSON.stringify({
        'shadcn-ui': { repo: 'shadcn-ui/ui', commit: 'a'.repeat(40) },
        'ember-primitives': { repo: 'universal-ember/ember-primitives', commit: 'b'.repeat(40) },
      }),
    )
    write(`.upstream/shadcn-ui/${PATHS.styles}/style-nova.css`, NOVA)
    write(
      `.upstream/shadcn-ui/${PATHS.styles}/style-lyra.css`,
      NOVA.replace('style-nova', 'style-lyra'),
    )
    write(`.upstream/shadcn-ui/${PATHS.styles}/README.md`, 'not a sheet')

    assert.deepEqual(portStyles({ root, log: () => {} }), ['lyra', 'nova'])
    assert.match(readFileSync(join(root, OUTPUT_DIR, 'lyra.css'), 'utf8'), /The Lyra style/)
    assert.deepEqual(portStyles({ root, check: true, log: () => {} }), ['lyra', 'nova'])

    writeFileSync(join(root, OUTPUT_DIR, 'nova.css'), 'edited by hand')
    assert.throws(
      () => portStyles({ root, check: true, log: () => {} }),
      /stale ported styles[\s\S]*nova\.css/,
    )

    // A sheet upstream drops: --check reports the ported copy, and a port removes it. A file
    // the script didn't port stays.
    portStyles({ root, log: () => {} })
    rmSync(join(root, `.upstream/shadcn-ui/${PATHS.styles}/style-lyra.css`))
    write(`${OUTPUT_DIR}/extra.css`, '/* not ported */\n')
    assert.throws(
      () => portStyles({ root, check: true, log: () => {} }),
      /stale ported styles[^\n]*\n {2}packages\/ember\/src\/styles\/lyra\.css \(upstream has no style-lyra\.css any more\)$/,
    )
    const logs = []
    assert.deepEqual(portStyles({ root, log: line => logs.push(line) }), ['nova'])
    assert.equal(existsSync(join(root, OUTPUT_DIR, 'lyra.css')), false)
    assert.equal(existsSync(join(root, OUTPUT_DIR, 'extra.css')), true)
    assert.match(logs[0], /^removed packages\/ember\/src\/styles\/lyra\.css/)
    assert.deepEqual(portStyles({ root, check: true, log: () => {} }), ['nova'])
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})
