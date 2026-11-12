import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { click, find, findAll, visit, waitFor, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'

const moduleOf = (id: string) => `[data-test-api-module="${id}"]`
const exportOf = (name: string) => `[data-test-api-export="${name}"]`

/** Opens a module of the page's reference, and waits for its docs to render. */
async function open(id: string, expected: string) {
  await click(`${moduleOf(id)} > summary`)
  await waitFor(`${moduleOf(id)} ${expected}`, { timeout: 20000 })
}

/**
 * The Reference pages are generated from each package's type declarations (Kolay's TypeDoc
 * JSON, refined by api-docs.mjs): every public module, and opened, each export's docs.
 */
module('Acceptance | API reference', function (hooks) {
  setupApplicationTest(hooks)

  test("a component's arguments, blocks and element, and its doc comment", async function (assert) {
    await visit('/reference/ember.md')
    await waitFor('[data-test-api-module]', { timeout: 20000 })
    assert.dom('[data-test-api-count]').includesText('modules')
    assert.dom(moduleOf('components/button')).doesNotHaveAttribute('open', 'modules start closed')
    assert.dom(`${moduleOf('components/button')} ${exportOf('Button')}`).doesNotExist('and empty')
    assert.dom(`${moduleOf('components/button')} summary`).includesText('Button, asButton')

    await open('components/button', `${exportOf('Button')} .typedoc__component-signature__arg`)
    const button = find(`${moduleOf('components/button')} ${exportOf('Button')}`)!
    assert.dom('[data-test-api-kind]', button).hasText('component')
    const args = [
      ...button.querySelectorAll('.typedoc__component-signature__arg .typedoc__name'),
    ].map(arg => arg.textContent?.trim())
    assert.deepEqual(
      [...args].sort(),
      ['@as', '@name', '@size', '@variant'],
      'the intersection of ButtonOptions and its own @as, merged',
    )
    await waitUntil(() => button.querySelector('.typedoc-rendered-comment pre'), { timeout: 10000 })
    assert
      .dom('.typedoc-rendered-comment pre', button)
      .includesText('<Button @variant="outline"', "the comment's example, as code")
    assert
      .dom(`${moduleOf('components/button')} pre.api-import`)
      .hasText("import { Button, asButton, buttonAttributes } from '@ember-joinery/ember'")
    assert.dom(exportOf('asButton')).exists().includesText('PartModifier')
    await a11yAudit()
  })

  test("a harness's own members, and the harness it extends", async function (assert) {
    await visit('/reference/test-support.md')
    await waitFor('[data-test-api-module]', { timeout: 20000 })
    await open('button', `${exportOf('ButtonHarness')} .typedoc__declaration-children`)
    const harness = find(exportOf('ButtonHarness'))!
    assert.dom('.api-extends', harness).hasText('extends Harness')
    const members = [
      ...harness.querySelectorAll(
        '.typedoc__declaration-children > li > .typedoc__declaration > .typedoc__declaration-name',
      ),
    ].map(name => name.textContent?.trim())
    assert.true(members.includes('label') && members.includes('click'), 'its own members')
    assert.false(members.includes('part'), "not the base Harness's")
    assert.dom(harness).includesText('Its accessible name', "a getter's comment")
    await a11yAudit()
  })

  test('an add-on: its components, and its harness from /test-support', async function (assert) {
    await visit('/reference/carousel.md')
    await waitFor('[data-test-api-module]', { timeout: 20000 })
    assert.deepEqual(
      findAll('[data-test-api-module]').map(module => module.getAttribute('data-test-api-module')),
      ['components/carousel', 'embla', 'messages', 'test-support'],
    )
    await open('test-support', `${exportOf('CarouselHarness')} .typedoc__declaration`)
    assert
      .dom(`${moduleOf('test-support')} pre.api-import`)
      .hasText("import { CarouselHarness } from '@ember-joinery/carousel/test-support'")
    await a11yAudit()
  })
})
