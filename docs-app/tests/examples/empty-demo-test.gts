import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, EmptyHarness, IconHarness } from '@ember-joinery/test-support'
import EmptyDemo from 'docs-app/examples/empty-demo'

module('Example | empty-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('an empty state with an icon, two actions and a link', async function (assert) {
    await render(<template><EmptyDemo /></template>)
    const empty = new EmptyHarness()
    assert.strictEqual(empty.title, 'No Projects Yet')
    assert.strictEqual(
      empty.description,
      "You haven't created any projects yet. Get started by creating your first project.",
    )
    assert.strictEqual(empty.mediaVariant, 'icon')
    assert.true(empty.find(IconHarness).isDecorative)

    const [create, imported, learn] = empty.findAll(ButtonHarness)
    assert.strictEqual(create!.label, 'Create Project')
    assert.strictEqual(imported!.label, 'Import Project')
    assert.strictEqual(imported!.variant, 'outline')
    assert.ok(
      create!.element.getBoundingClientRect().left < imported!.element.getBoundingClientRect().left,
      'flex-row: the actions side by side',
    )
    assert.dom(learn!.element).hasTagName('a').hasAttribute('href', '#')
    assert.strictEqual(learn!.label, 'Learn More')
    assert.strictEqual(learn!.variant, 'link')
    assert.strictEqual(learn!.size, 'sm')
    await a11yAudit()
  })
})
