import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { isElement, isNewable, isString, type Newable } from '@ember-joinery/primitives/narrowing'

class Point {
  x = 0
}

module('Integration | primitives | narrowing', function (hooks) {
  setupRenderingTest(hooks)

  test('isString', async function (assert) {
    assert.true(isString(''))
    assert.true(isString('text'))
    assert.false(isString(1))
    assert.false(isString(undefined))
    assert.false(isString(new String('boxed')), 'a String object is not a string')
    await a11yAudit()
  })

  test('isElement, in templates too', async function (assert) {
    assert.true(isElement(document.createElement('div')))
    assert.true(isElement(document.createElementNS('http://www.w3.org/2000/svg', 'svg')))
    assert.false(isElement(document.createTextNode('text')))
    assert.false(isElement({ nodeType: 1 }), 'something shaped a little like one is not')
    assert.false(isElement(null))

    const frame = document.createElement('iframe')
    document.body.append(frame)
    const foreign = frame.contentDocument!.createElement('p')
    assert.true(isElement(foreign), "another window's element counts")
    frame.remove()

    const element = document.createElement('span')
    await render(<template>{{if (isElement element) "an element" "not one"}}</template>)
    assert.dom().hasText('an element')
    await a11yAudit()
  })

  test('isNewable tells a class from a function', async function (assert) {
    assert.true(isNewable(Point))
    assert.false(
      isNewable(() => new Point()),
      'an arrow function',
    )
    assert.false(isNewable(Point.prototype), 'an object')
    assert.false(isNewable(undefined))

    const make = (definition: Newable<Point> | (() => Point)) =>
      isNewable<Point>(definition) ? new definition() : definition()
    assert.strictEqual(make(Point).x, 0)
    assert.strictEqual(make(() => Object.assign(new Point(), { x: 3 })).x, 3)
    await a11yAudit()
  })
})
