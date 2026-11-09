import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import {
  OUTPUT_DIR,
  portStyle,
  portStyles,
  renameClasses,
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
  assert.equal(unwrapStyleScope('.cn-a {}\n', 'nova'), '.cn-a {}\n', 'no wrapper, no change')
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
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})
