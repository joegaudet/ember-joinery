import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ItemGroupHarness } from '@ember-joinery/test-support'
import ItemImage from 'docs-app/examples/item-image'

module('Example | item-image', function (hooks) {
  setupRenderingTest(hooks)

  test('songs, each a link with its cover, artist and length', async function (assert) {
    await render(<template><ItemImage /></template>)
    const group = new ItemGroupHarness()
    const songs = group.items
    assert.deepEqual(
      songs.map(song => song.title),
      [
        'Midnight City Lights - Electric Nights',
        'Coffee Shop Conversations - Urban Stories',
        'Digital Rain - Binary Beats',
      ],
    )
    assert.deepEqual(songs[0]!.descriptions, ['Neon Dreams', '3:45'])
    for (const song of songs) {
      assert.true(song.isLink)
      assert.dom(song.element.parentElement).hasAttribute('role', 'listitem', 'each in a list item')
      assert.strictEqual(song.mediaVariant, 'image')
      assert.strictEqual(getComputedStyle(song.media).width, '40px', 'the image media is size-10')
      assert.dom('img', song.media).hasAttribute('alt', song.title.split(' - ')[0]!)
    }
    assert.strictEqual(getComputedStyle(group.element).rowGap, '16px', 'gap-4')
    await a11yAudit()
  })
})
