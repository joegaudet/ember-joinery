import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { styles } from '../packages/ember/build-css.mjs'
import { repoRoot } from './upstream.mjs'

const read = file => readFileSync(join(repoRoot, 'packages/ember/src', file), 'utf8')
const withoutComments = css => css.replace(/\/\*[\s\S]*?\*\//g, '')

/** The utilities a sheet's rule for `selector` applies. */
function utilities(css, selector) {
  const rule = new RegExp(`^${selector.replace(/[().]/g, '\\$&')} \\{\\s*@apply ([^;]+);`, 'm')
  return (rule.exec(withoutComments(css))?.[1] ?? '').split(/\s+/).filter(Boolean)
}

test("formwright.css restates every sheet's gap for a FieldSet's checkboxes or radios, through the control's wrapper", () => {
  const css = withoutComments(read('components/formwright.css'))
  const block = /:where\(\.jn-field-set\):has\([^{]*\{\s*@apply ([^;]+);/.exec(css)
  assert.ok(block, 'formwright.css has the FieldSet rule')
  const copy = block[1].split(/\s+/)
  for (const style of styles()) {
    const sheet = utilities(read(`styles/${style}.css`), ':where(.jn-field-set)')
    for (const slot of ['checkbox-group', 'radio-group']) {
      const prefix = `has-[>[data-slot=${slot}]]:`
      const expected = sheet.filter(u => u.startsWith(prefix)).map(u => u.slice(prefix.length))
      assert.deepStrictEqual(copy, expected, `${style}'s ${slot} gap is the copy's`)
    }
  }
})

test("formwright.css restates field.css's child widths and checkbox nudge one level down", () => {
  const field = withoutComments(read('components/field.css'))
  const ours = withoutComments(read('components/formwright.css'))
  for (const utility of ['*:w-full', '@md/field-group:*:w-auto', '[&>.sr-only]:w-auto']) {
    assert.ok(field.includes(utility), `field.css still has ${utility}`)
  }
  assert.ok(
    field.includes('has-[>[data-slot=field-content]]:[&>[role=checkbox],[role=radio]]:mt-px'),
    'field.css still nudges a checkbox beside a FieldContent',
  )
  for (const restated of [
    '@apply w-full;',
    '@apply w-auto;',
    '@apply @md/field-group:w-auto;',
    '@apply mt-px;',
  ]) {
    assert.ok(ours.includes(restated), `formwright.css restates ${restated}`)
  }
})
