import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { styles } from '../packages/ember/build-css.mjs'
import { repoRoot } from './upstream.mjs'

const read = file => readFileSync(join(repoRoot, 'packages/ember/src', file), 'utf8')
const withoutComments = css => css.replace(/\/\*[\s\S]*?\*\//g, '')

/** The block input-group.css restates `align`'s rule in, through an overlay's root. */
function restated(css, align) {
  const start = css.indexOf(`:where(.jn-input-group-addon-align-${align}):has(`)
  assert.ok(start >= 0, `input-group.css restates the ${align} addon's rule`)
  const end = css.indexOf('\n}\n', start)
  return css.slice(start, end)
}

for (const align of ['inline-start', 'inline-end']) {
  test(`input-group.css restates each sheet's ${align} addon margin for a button through an overlay's root`, () => {
    const block = restated(read('components/input-group.css'), align)
    const button = 'has-[>button]:'
    for (const style of styles()) {
      const sheet = withoutComments(read(`styles/${style}.css`))
      const rule = new RegExp(
        `^:where\\(\\.jn-input-group-addon-align-${align}\\) \\{\\s*@apply ([^;]+);`,
        'm',
      ).exec(sheet)
      const expected = (rule?.[1] ?? '')
        .split(/\s+/)
        .filter(utility => utility.startsWith(button))
        .map(utility => utility.slice(button.length))
      const copy = new RegExp(`@variant style-${style} \\{\\s*@apply ([^;]+);`).exec(block)
      if (expected.length === 0) {
        assert.equal(copy, null, `${style}'s sheet has no ${align} rule for a button, nor the copy`)
        continue
      }
      assert.ok(copy, `input-group.css has a style-${style} block for ${align}`)
      assert.deepStrictEqual(copy[1].split(/\s+/), expected, `the copy matches ${style}'s sheet`)
    }
  })
}

for (const align of ['inline-start', 'inline-end']) {
  test(`input-group.css restates each sheet's input padding beside an ${align} addon through an overlay's root`, () => {
    const css = withoutComments(read('components/input-group.css'))
    const start = css.search(
      new RegExp(`:where\\(\\.jn-input-group\\):has\\([^{]*\\[data-align='${align}'\\]`),
    )
    assert.ok(start >= 0, `input-group.css restates the input's padding beside an ${align} addon`)
    const block = css.slice(start, css.indexOf('\n}\n', start))
    const prefix = `has-[>[data-align=${align}]]:[&>input]:`
    for (const style of styles()) {
      const sheet = withoutComments(read(`styles/${style}.css`))
      const rule = /^:where\(\.jn-input-group\) \{\s*@apply ([^;]+);/m.exec(sheet)
      const expected = (rule?.[1] ?? '')
        .split(/\s+/)
        .filter(utility => utility.startsWith(prefix))
        .map(utility => utility.slice(prefix.length))
      const copy = new RegExp(`@variant style-${style} \\{\\s*@apply ([^;]+);`).exec(block)
      if (expected.length === 0) {
        assert.equal(copy, null, `${style}'s sheet has no ${align} padding rule, nor the copy`)
        continue
      }
      assert.ok(copy, `input-group.css has a style-${style} block for ${align}`)
      assert.deepStrictEqual(copy[1].split(/\s+/), expected, `the copy matches ${style}'s sheet`)
    }
  })
}
