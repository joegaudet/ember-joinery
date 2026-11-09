import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Shadowed } from '@ember-joinery/primitives/shadowed'
import { Zoetrope } from '@ember-joinery/primitives/zoetrope'
import {
  ShadowedHarness,
  findInFirstShadow,
  findInShadow,
  findShadow,
  hasShadowRoot,
} from '@ember-joinery/test-support'

class Include {
  @tracked on = true
}

class Counter {
  @tracked count = 0
  increment = () => (this.count += 1)
}

module('Integration | primitives | shadowed', function (hooks) {
  setupRenderingTest(hooks)

  test('its content renders in a shadow root', async function (assert) {
    await render(
      <template>
        out of shadow
        <Shadowed @name="preview" class="preview">
          <p class="note">in shadow</p>
        </Shadowed>
      </template>,
    )
    const preview = new ShadowedHarness('preview')
    assert.dom().hasText('out of shadow')
    assert.dom().doesNotContainText('in shadow', 'the light DOM doesn’t have it')
    assert.dom(preview.element).hasClass('preview', 'the attributes go on the outer element')
    assert.strictEqual(preview.shadowRoot.mode, 'open')
    assert.strictEqual(preview.text, 'in shadow')
    assert.dom(preview.query('p.note')).hasText('in shadow')
    assert.strictEqual(preview.queryAll('p').length, 1)
    await a11yAudit()
  })

  test('the app’s styles don’t reach it', async function (assert) {
    await render(
      <template>
        <style>
          p.skewed {
            transform: skew(5deg, 5deg);
          }
        </style>
        <p class="skewed" id="outside">affected by the global styles</p>
        <Shadowed>
          <p class="skewed">not affected</p>
        </Shadowed>
      </template>,
    )
    const preview = new ShadowedHarness()
    assert.notStrictEqual(getComputedStyle(document.querySelector('#outside')!).transform, 'none')
    assert.strictEqual(getComputedStyle(preview.query('p')!).transform, 'none')
    await a11yAudit()
  })

  test('@includeStyles brings the page’s style sheets in', async function (assert) {
    const style = document.createElement('style')
    style.textContent = '.from-head { color: rgb(255, 0, 0); }'
    document.head.append(style)
    try {
      await render(
        <template>
          <Shadowed @name="with" @includeStyles={{true}}>
            <p class="from-head">styled</p>
          </Shadowed>
          <Shadowed @name="without">
            <p class="from-head">unstyled</p>
          </Shadowed>
        </template>,
      )
      const withStyles = new ShadowedHarness('with')
      const without = new ShadowedHarness('without')
      assert.strictEqual(getComputedStyle(withStyles.query('p')!).color, 'rgb(255, 0, 0)')
      assert.notStrictEqual(getComputedStyle(without.query('p')!).color, 'rgb(255, 0, 0)')
      assert.true(withStyles.styleSheetCount > without.styleSheetCount)
      assert.ok(withStyles.query('style'), 'the copies are in the content’s element')
      assert.strictEqual(withStyles.text, 'styled', 'their CSS isn’t text')
      await a11yAudit()
    } finally {
      style.remove()
    }
  })

  test('@includeStyles turned off takes the page’s sheets out again, and leaves its own', async function (assert) {
    const sheet = new CSSStyleSheet()
    sheet.replaceSync('.adopted { color: rgb(0, 128, 0); }')
    document.adoptedStyleSheets = [...document.adoptedStyleSheets, sheet]
    const state = new Include()
    try {
      await render(
        <template>
          <Shadowed @includeStyles={{state.on}}>
            <p class="adopted">adopted</p>
            <Zoetrope aria-label="Cards">
              <:content><a href="/cards/1">Card</a></:content>
            </Zoetrope>
          </Shadowed>
        </template>,
      )
      const preview = new ShadowedHarness()
      const color = () => getComputedStyle(preview.query('p')!).color
      const track = () => getComputedStyle(preview.query('[data-jn-zoetrope-scroller]')!)
      assert.strictEqual(color(), 'rgb(0, 128, 0)', 'the page’s adopted sheet applies')
      assert.true(preview.shadowRoot.adoptedStyleSheets.includes(sheet))

      state.on = false
      await settled()
      assert.notStrictEqual(color(), 'rgb(0, 128, 0)', 'not any more')
      assert.false(preview.shadowRoot.adoptedStyleSheets.includes(sheet))
      assert.strictEqual(preview.query('style'), null, 'nor the copies')
      assert.strictEqual(track().display, 'flex', 'the Zoetrope’s own rules stay')

      state.on = true
      await settled()
      assert.strictEqual(color(), 'rgb(0, 128, 0)', 'and back')
      await a11yAudit()
    } finally {
      document.adoptedStyleSheets = document.adoptedStyleSheets.filter(other => other !== sheet)
    }
  })

  test('the content is still the component’s: its state and actions', async function (assert) {
    const counter = new Counter()
    await render(
      <template>
        <Shadowed>
          <button type="button" {{on "click" counter.increment}}>Clicked {{counter.count}}</button>
        </Shadowed>
      </template>,
    )
    const preview = new ShadowedHarness()
    await click(preview.query('button')!)
    assert.strictEqual(preview.text, 'Clicked 1')
    counter.count = 5
    await settled()
    assert.strictEqual(preview.text, 'Clicked 5')
    await a11yAudit()
  })

  test('a layout primitive inside it gets its rules there', async function (assert) {
    await render(
      <template>
        <Shadowed>
          <Zoetrope aria-label="Cards">
            <:content><a href="/cards/1">Card</a></:content>
          </Zoetrope>
        </Shadowed>
      </template>,
    )
    const track = new ShadowedHarness().query('[data-jn-zoetrope-scroller]')!
    assert.strictEqual(getComputedStyle(track).display, 'flex', 'adopted by the shadow root')
    await a11yAudit()
  })

  test('the shadow DOM helpers', async function (assert) {
    await render(
      <template>
        <div id="plain"></div>
        <Shadowed id="first"><h2>First</h2></Shadowed>
        <Shadowed id="second"><h2>Second</h2></Shadowed>
      </template>,
    )
    const host = findShadow()!
    assert.true(hasShadowRoot(host))
    assert.false(hasShadowRoot(document.querySelector('#plain')!))
    assert.dom(findInFirstShadow('h2')).hasText('First')
    assert.dom(findInShadow(findShadow('#second')!, 'h2')).hasText('Second')
    assert.strictEqual(findInShadow('#plain', 'h2'), null, 'no shadow root: nothing')
    await a11yAudit()
  })
})
