import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Heading, getSectionHeadingLevel } from '@ember-joinery/primitives/heading'
import { Shadowed } from '@ember-joinery/primitives/shadowed'
import { Harness, HeadingHarness, ShadowedHarness } from '@ember-joinery/test-support'

/** Each `<Heading @name>` in the test, by name, with the level it chose. */
function levels(): Record<string, number> {
  return Object.fromEntries(
    HeadingHarness.findAll().map(heading => [
      heading.element.getAttribute('data-test-jn-name'),
      heading.level,
    ]),
  )
}

/** The level of the heading named `name` inside the first Shadowed. */
function levelInShadow(name: string): number {
  const heading = new ShadowedHarness().query(`[data-test-jn-name="${name}"]`)
  return Number(heading!.tagName.slice(1))
}

/** A text node at the end of what matches `selector` in `html`, as Heading renders one. */
function markerIn(html: string, selector: string): Text {
  const root = document.createElement('div')
  root.innerHTML = html
  const marker = document.createTextNode('')
  root.querySelector(selector)!.append(marker)
  return marker
}

class CardHarness extends Harness {
  static override component = 'card'
}

module('Integration | primitives | heading', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a section heading, one level below its section’s', async function (assert) {
    await render(
      <template>
        <Heading @name="a" class="title">one</Heading>
        <section>
          <Heading @name="b">two</Heading>
        </section>
      </template>,
    )
    assert.deepEqual(levels(), { a: 1, b: 2 })
    const a = new HeadingHarness('a')
    assert.dom(a.element).hasTagName('h1').hasClass('title')
    assert.strictEqual(a.text, 'one')
    await a11yAudit()
  })

  module('wrapped headings', function () {
    test('h1 wrapped in <a>', async function (assert) {
      await render(
        <template>
          <a href="/"><Heading @name="a">one</Heading></a>
          <section><Heading @name="b">two</Heading></section>
        </template>,
      )
      assert.deepEqual(levels(), { a: 1, b: 2 })
      await a11yAudit()
    })

    test('h2 wrapped in <a>', async function (assert) {
      await render(
        <template>
          <Heading @name="a">one</Heading>
          <section><a href="/"><Heading @name="b">two</Heading></a></section>
        </template>,
      )
      assert.deepEqual(levels(), { a: 1, b: 2 })
      await a11yAudit()
    })

    test('h1 wrapped in <header><div><a>, h2 wrapped in <a>', async function (assert) {
      await render(
        <template>
          <header>
            <div><a href="/"><Heading @name="a">one</Heading></a></div>
          </header>
          <section>
            <a href="/"><Heading @name="b">two</Heading></a>
            <section>
              <a href="/"><Heading @name="c">three</Heading></a>
            </section>
          </section>
        </template>,
      )
      assert.deepEqual(levels(), { a: 1, b: 2, c: 3 })
      await a11yAudit()
    })

    test('sections beside the heading’s own don’t count', async function (assert) {
      await render(
        <template>
          <header>
            <div>
              <a href="/"><Heading @name="a">one</Heading></a>
              <section>
                <a href="/"><Heading @name="d">two</Heading></a>
              </section>
            </div>
          </header>
          <section>
            <a href="/"><Heading @name="b">two</Heading></a>
            <Heading @name="f">two</Heading>
            <section>
              <a href="/"><Heading @name="c">three</Heading></a>
              <section>
                <a href="/"><Heading @name="e">four</Heading></a>
              </section>
            </section>
          </section>
        </template>,
      )
      assert.deepEqual(levels(), { a: 1, d: 2, b: 2, f: 2, c: 3, e: 4 })
      await a11yAudit()
    })
  })

  module('in a shadow root', function () {
    test('a section inside it', async function (assert) {
      await render(
        <template>
          <Heading @name="a">one</Heading>
          <Shadowed>
            <section><Heading @name="b">two</Heading></section>
          </Shadowed>
        </template>,
      )
      assert.deepEqual(levels(), { a: 1 })
      assert.strictEqual(levelInShadow('b'), 2)
      await a11yAudit()
    })

    test('a section around it', async function (assert) {
      await render(
        <template>
          <Heading @name="a">one</Heading>
          <section>
            <Shadowed><Heading @name="b">two</Heading></Shadowed>
          </section>
        </template>,
      )
      assert.strictEqual(levelInShadow('b'), 2)
      await a11yAudit()
    })
  })

  test('sections with no heading before it are passed through', async function (assert) {
    await render(
      <template>
        <section><Heading @name="a">one</Heading></section>
        <section>
          <section>
            <section><Heading @name="b">one</Heading></section>
          </section>
        </section>
      </template>,
    )
    assert.deepEqual(levels(), { a: 1, b: 1 })
    await a11yAudit()
  })

  test('headings written by hand count', async function (assert) {
    await render(
      <template>
        <h1>one</h1>
        <h2>two</h2>
        <section><Heading @name="a">three</Heading></section>
      </template>,
    )
    assert.deepEqual(levels(), { a: 3 }, 'below the nearest heading before it')
    await a11yAudit()
  })

  test('top level headings side by side are each an h1', async function (assert) {
    await render(
      <template>
        <h1>one</h1>
        <Heading @name="a">one</Heading>
        <Heading @name="b">one</Heading>
      </template>,
    )
    assert.deepEqual(levels(), { a: 1, b: 1 })
    await a11yAudit()
  })

  test('section, article, aside and nav start a section', async function (assert) {
    await render(
      <template>
        <Heading @name="a">one</Heading>
        <aside><Heading @name="b">two</Heading></aside>
        <nav aria-label="More"><Heading @name="g">two</Heading></nav>
        <article>
          <Heading @name="c">two</Heading>
          <section><Heading @name="d">three</Heading></section>
          <section><Heading @name="e">three</Heading></section>
          <article><Heading @name="f">three</Heading></article>
          <Heading @name="h">two</Heading>
        </article>
      </template>,
    )
    assert.deepEqual(levels(), { a: 1, b: 2, g: 2, c: 2, d: 3, e: 3, f: 3, h: 2 })
    await a11yAudit()
  })

  test('it stops at h6', async function (assert) {
    await render(
      <template>
        <h5>five</h5>
        <section>
          <h6>six</h6>
          <section><Heading @name="deep">deeper</Heading></section>
        </section>
      </template>,
    )
    assert.deepEqual(levels(), { deep: 6 })
    await a11yAudit()
  })

  test('it is a wrapper, and can be a part of the component around it', async function (assert) {
    await render(
      <template>
        <article data-test-jn="card" aria-label="Card">
          <Heading data-test-jn-part="title">
            Order
            <span data-test-jn-part="number">#42</span>
          </Heading>
        </article>
      </template>,
    )
    const card = new CardHarness()
    assert.dom(card.part('title')).hasText('Order #42')
    assert.dom(card.part('number')).hasText('#42', 'a part inside it is still the card’s')
    assert.strictEqual(card.find(HeadingHarness).level, 1)
    await a11yAudit()
  })

  module('getSectionHeadingLevel', function () {
    test('one below the nearest heading', function (assert) {
      const marker = markerIn('<h3>hello</h3><section></section>', 'section')
      assert.strictEqual(getSectionHeadingLevel(marker), 4)
    })

    test('sections without headings are transparent', function (assert) {
      const marker = markerIn(
        '<h2>hello</h2><section><section></section></section>',
        'section section',
      )
      assert.strictEqual(getSectionHeadingLevel(marker), 3)
    })

    test('headings in sibling sections are not context', function (assert) {
      const marker = markerIn(
        '<h2>hello</h2><section><h3>a sibling’s</h3></section><section></section>',
        'section + section',
      )
      assert.strictEqual(getSectionHeadingLevel(marker), 3)
    })

    test('no heading: 1, or startAt', function (assert) {
      assert.strictEqual(getSectionHeadingLevel(markerIn('<section></section>', 'section')), 1)
      assert.strictEqual(
        getSectionHeadingLevel(markerIn('<section></section>', 'section'), { startAt: 2 }),
        2,
      )
    })

    test('startAt doesn’t change a level the document sets', function (assert) {
      const marker = markerIn('<h3>hello</h3><section></section>', 'section')
      assert.strictEqual(getSectionHeadingLevel(marker, { startAt: 2 }), 4)
      assert.strictEqual(getSectionHeadingLevel(marker, { startAt: 5 }), 4)
    })
  })
})
