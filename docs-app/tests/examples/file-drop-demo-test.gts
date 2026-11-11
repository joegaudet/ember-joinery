import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FileDropHarness } from '@ember-joinery/test-support'
import FileDropDemo from 'docs-app/examples/file-drop-demo'

const cat = new File(['cat'], 'cat.png', { type: 'image/png' })
const dog = new File(['dog'], 'dog.jpg', { type: 'image/jpeg' })
const notes = new File(['notes'], 'notes.txt', { type: 'text/plain' })

module('Example | file-drop-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('drop or pick images, and see their names', async function (assert) {
    await render(<template><FileDropDemo /></template>)
    const zone = new FileDropHarness()

    assert.strictEqual(zone.text, 'Drag images here, or click to choose')
    assert.strictEqual(zone.accept, 'image/*')
    assert.true(zone.isMultiple)
    assert.dom(zone.element.parentElement!).containsText('Nothing picked yet.')

    await zone.drag([cat])
    assert.strictEqual(zone.text, 'Drop to upload')
    await zone.drop([cat, notes, dog])
    assert.dom(zone.element.parentElement!).containsText('Picked: cat.png, dog.jpg')

    await zone.pick([dog])
    assert.dom(zone.element.parentElement!).containsText('Picked: dog.jpg')
    await a11yAudit()
  })
})
