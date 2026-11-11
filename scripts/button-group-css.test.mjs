import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { styles } from '../packages/ember/build-css.mjs'
import { repoRoot } from './upstream.mjs'

// button-group.css restates the group's rules one overlay root down (see its comment "Through an
// overlay's root"). These hold each copy to what it copies: the inline rules extract-classes.mjs
// wrote above it, and each style sheet's rule for the group's last part.

const read = file => readFileSync(join(repoRoot, 'packages/ember/src', file), 'utf8')
const withoutComments = css => css.replace(/\/\*[\s\S]*?\*\//g, '')
const css = withoutComments(read('components/button-group.css'))

/** The `@apply` of the rule whose selector starts with `selector` and contains `marker`. */
function applyOf(selector, marker = '') {
  const rule = [...css.matchAll(/([^{}]+)\{\s*@apply ([^;]+);\s*\}/g)].find(
    ([, head]) => head.trim().startsWith(selector) && head.includes(marker),
  )
  assert.ok(rule, `button-group.css has a rule ${selector} … ${marker}`)
  return rule[2].trim().split(/\s+/)
}

/** The inline orientation rule's utilities for `[&>*:<pseudo>]`, as extract-classes.mjs wrote them. */
function inline(orientation, pseudo) {
  const utilities = applyOf(`:where(.jn-button-group-orientation-${orientation}) {`.slice(0, -2))
  const prefix = `[&>*:${pseudo}]:`
  return utilities.filter(u => u.startsWith(prefix)).map(u => u.slice(prefix.length))
}

for (const orientation of ['horizontal', 'vertical']) {
  for (const pseudo of ['not(:first-child)', 'not(:last-child)']) {
    test(`button-group.css restates ${orientation} [&>*:${pseudo}] one overlay root down`, () => {
      const expected = inline(orientation, pseudo)
      assert.ok(expected.length, 'the inline rule has utilities for it')
      const copy = applyOf(
        `:where(.jn-button-group-orientation-${orientation})\n  > :where(`,
        `):${pseudo}\n`,
      )
      assert.deepStrictEqual(copy, expected)
    })
  }

  test(`button-group.css restates each sheet's ${orientation} last-part rule for a trigger in the last root`, () => {
    // The rule's selectors put each root in :not(:has(…)); its block holds a variant per style.
    const head = new RegExp(
      `:where\\(\\.jn-button-group-orientation-${orientation}\\)\\n  > :where\\([^{]*?\\):not\\(\\n    :has\\(`,
    ).exec(css)
    assert.ok(head, `button-group.css restates the ${orientation} last-part rule`)
    const block = css.slice(head.index)
    const variants = block.slice(0, block.indexOf('\n}\n'))
    const prefix = '[&>[data-slot]:not(:has(~[data-slot]))]:'
    for (const style of styles()) {
      const sheet = withoutComments(read(`styles/${style}.css`))
      const rule = new RegExp(
        `^:where\\(\\.jn-button-group-orientation-${orientation}\\) \\{\\s*@apply ([^;]+);`,
        'm',
      ).exec(sheet)
      const expected = (rule?.[1] ?? '')
        .split(/\s+/)
        .filter(u => u.startsWith(prefix))
        .map(u => u.slice(prefix.length))
      const copy = new RegExp(`@variant style-${style} \\{\\s*@apply ([^;]+);`).exec(variants)
      if (!expected.length) {
        assert.equal(copy, null, `${style}'s sheet has no rule for the last part, nor the copy`)
        continue
      }
      assert.ok(copy, `a style-${style} block`)
      assert.deepStrictEqual(copy[1].split(/\s+/), expected, `the copy matches ${style}'s sheet`)
    }
  })
}
