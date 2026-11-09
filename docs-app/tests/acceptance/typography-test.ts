import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { find, visit, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'

/** The value `--border` resolves to on an element, as a colour the browser computes. */
function borderColour(within: Element): string {
  const probe = document.createElement('span')
  probe.style.color = 'var(--border)'
  within.append(probe)
  const colour = getComputedStyle(probe).color
  probe.remove()
  return colour
}

/**
 * Typography's examples are bare elements styled with utilities, which on ui.shadcn.com sit on
 * Tailwind's preflight. The guide gives them, and only them, the share of it they rely on
 * (examples.css), in the frame and on the parity route alike.
 */
module('Acceptance | typography examples', function (hooks) {
  setupApplicationTest(hooks)

  test('on the parity route, they start from the reset a Tailwind app gives them', async function (assert) {
    await visit('/parity/typography-list')
    const list = getComputedStyle(find('[data-parity] ul')!)
    assert.strictEqual(list.paddingLeft, '0px', "no browser indent, only the class's")
    assert.strictEqual(list.marginLeft, '24px', 'ml-6')
    assert.strictEqual(list.listStyleType, 'disc', 'list-disc puts the bullets back')

    await visit('/parity/typography-h2')
    const stage = find('[data-parity]')!
    const heading = getComputedStyle(find('[data-parity] h2')!)
    assert.strictEqual(heading.marginBottom, '0px', 'no browser margin')
    assert.strictEqual(heading.borderBottomWidth, '1px', 'border-b')
    assert.strictEqual(heading.borderBottomColor, borderColour(stage), 'in --border')

    await visit('/parity/typography-table')
    assert.strictEqual(getComputedStyle(find('[data-parity] table')!).borderCollapse, 'collapse')
    assert.strictEqual(
      getComputedStyle(find('[data-parity] th')!).borderTopColor,
      borderColour(find('[data-parity]')!),
    )
    await a11yAudit({ rules: { region: { enabled: false } } })
  })

  test('other examples get no reset: Joinery parts bring their own', async function (assert) {
    await visit('/parity/alert-demo')
    const probe = document.createElement('p')
    find('[data-parity]')!.append(probe)
    assert.notStrictEqual(getComputedStyle(probe).marginTop, '0px', 'a bare <p> keeps its margin')
    probe.remove()
    await a11yAudit({ rules: { region: { enabled: false } } })
  })

  test("in the guide's frame, the stage names its example", async function (assert) {
    await visit('/components/typography.md')
    await waitUntil(() => find('[data-example="typography-list"] ul'))
    const list = getComputedStyle(find('[data-example="typography-list"] ul')!)
    assert.strictEqual(list.paddingLeft, '0px')
    assert.strictEqual(list.marginLeft, '24px')
    assert
      .dom('[data-example="typography-h1"] h1')
      .hasText('Taxing Laughter: The Joke Tax Chronicles')
    // The specimens are real headings, so the h4 follows its section's h2 (see pages-test.ts).
    await a11yAudit({ rules: { 'heading-order': { enabled: false } } })
  })
})
