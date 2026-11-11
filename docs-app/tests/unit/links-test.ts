import { module, test } from 'qunit'
import { routablePath } from 'docs-app/links'

const ROOT = '/ember-joinery/guide/'
const HERE = 'https://joegaudet.com/ember-joinery/guide/getting-started/introduction.md'

module('Unit | routablePath', function () {
  test('a link inside the guide becomes an app-relative path', function (assert) {
    assert.strictEqual(
      routablePath('/ember-joinery/guide/components/index.md', HERE, ROOT),
      '/components/index.md',
    )
    assert.strictEqual(
      routablePath('installation.md', HERE, ROOT),
      '/getting-started/installation.md',
    )
    assert.strictEqual(
      routablePath(
        '/ember-joinery/guide/getting-started/installation.md#tailwind-apps',
        HERE,
        ROOT,
      ),
      '/getting-started/installation.md#tailwind-apps',
    )
    assert.strictEqual(routablePath('/ember-joinery/guide', HERE, ROOT), '/')
  })

  test('the browser follows links out of the guide', function (assert) {
    assert.strictEqual(routablePath('/ember-joinery/', HERE, ROOT), undefined, 'the project site')
    assert.strictEqual(routablePath('/ember-joinery/demo/', HERE, ROOT), undefined, 'the demo')
    assert.strictEqual(routablePath('/real-enums/', HERE, ROOT), undefined)
    assert.strictEqual(routablePath('https://ui.shadcn.com/', HERE, ROOT), undefined)
  })

  test('a jump to a heading on this page is left to the browser', function (assert) {
    assert.strictEqual(routablePath('#live-examples', HERE, ROOT), undefined)
  })

  test('served from the root, every same-origin path is the guide', function (assert) {
    const here = 'http://localhost:4200/getting-started/introduction.md'
    assert.strictEqual(routablePath('/components/index.md', here, '/'), '/components/index.md')
    assert.strictEqual(routablePath('http://example.com/', here, '/'), undefined)
  })
})
