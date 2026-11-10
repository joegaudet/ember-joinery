import { module, test } from 'qunit'
import { visit } from '@ember/test-helpers'
import { setupApplicationTest } from 'ember-qunit'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import * as ember from '@ember-joinery/ember'
import * as testSupport from '@ember-joinery/test-support'
import { ButtonHarness, IconHarness } from '@ember-joinery/test-support'
import { CarouselHarness } from '@ember-joinery/carousel/test-support'
import { DataTableHarness } from '@ember-joinery/data-table/test-support'
import { CodeBlockHarness, setupClipboard } from '@ember-joinery/code-block/test-support'
import { FileUploadHarness } from '@ember-joinery/file-upload/test-support'

/** Every cascade layer the page's style sheets declare, in order. */
function declaredLayers() {
  const layers = []
  const walk = rules => {
    for (const rule of rules) {
      if (rule instanceof CSSLayerStatementRule) layers.push(...rule.nameList)
      else if (rule instanceof CSSLayerBlockRule) {
        layers.push(rule.name)
        walk(rule.cssRules)
      }
    }
  }
  for (const sheet of document.styleSheets) {
    // Cross-origin sheets (a font service, say) can't be read; Joinery's never are.
    let rules
    try {
      rules = sheet.cssRules
    } catch {
      continue
    }
    walk(rules)
  }
  return layers
}

module('Acceptance | smoke', function (hooks) {
  setupApplicationTest(hooks)

  test('Joinery loads in a Vite (Embroider) app', async function (assert) {
    await visit('/')

    assert.dom('h1').hasText('Joinery in a Vite app')
    assert.strictEqual(typeof ember, 'object', '@ember-joinery/ember imports')
    assert.strictEqual(typeof testSupport, 'object', '@ember-joinery/test-support imports')
    assert.true(declaredLayers().includes('joinery'), 'joinery.css is loaded')

    await a11yAudit()
  })

  test('a Joinery Button renders and works here, styled by joinery.css', async function (assert) {
    await visit('/')
    const save = new ButtonHarness('save')
    assert.dom(save.element).hasTagName('button').hasClass('jn-button')
    assert.strictEqual(save.variant, 'outline')
    assert.strictEqual(getComputedStyle(save.element).height, '32px', "Nova's h-8")
    assert.strictEqual(
      getComputedStyle(save.element).borderTopLeftRadius,
      '10px',
      "tokens.css's --radius",
    )
    let clicked = false
    save.element.addEventListener('click', () => (clicked = true), { once: true })
    await save.click()
    assert.true(clicked)

    const up = new ButtonHarness('up')
    assert.strictEqual(up.label, 'Back to top')
    assert.true(up.find(IconHarness).isDecorative, 'its lucide icon')
    assert.strictEqual(up.find(IconHarness).element.namespaceURI, 'http://www.w3.org/2000/svg')
    await a11yAudit()
  })

  module('an add-on', function (hooks) {
    const clipboard = setupClipboard(hooks)

    test('a Code Block from @ember-joinery/code-block, highlighted by Shiki loaded on demand', async function (assert) {
      await visit('/')
      const block = new CodeBlockHarness('install')
      assert.strictEqual(block.title, 'Terminal')
      assert.strictEqual(block.code, 'pnpm add @ember-joinery/code-block')
      assert.true(block.isHighlighted, "Shiki and the bash grammar loaded through the app's build")
      assert.strictEqual(
        getComputedStyle(block.element).borderTopLeftRadius,
        '10px',
        "joinery.css styles the add-on's parts",
      )
      await block.copy()
      assert.strictEqual(clipboard.text, 'pnpm add @ember-joinery/code-block')
      await a11yAudit()
    })
  })

  test('a Joinery Carousel, on Embla, moves between its slides here', async function (assert) {
    await visit('/')
    const carousel = new CarouselHarness('slides')
    assert.strictEqual(
      getComputedStyle(carousel.content).overflow,
      'hidden',
      'joinery.css styles it',
    )
    assert.deepEqual(carousel.slideTexts, ['One', 'Two', 'Three'])
    assert.deepEqual(carousel.slidesInView, [0])
    await carousel.scrollNext()
    assert.deepEqual(carousel.slidesInView, [1], 'Embla moved it')
    await carousel.press('ArrowRight')
    assert.deepEqual(carousel.slidesInView, [2])
    assert.false(carousel.canScrollNext)
    await a11yAudit()
  })

  test('a Joinery FileUpload, on ember-file-upload, takes and lists files here', async function (assert) {
    await visit('/')
    const attachments = new FileUploadHarness('attachments')
    assert.strictEqual(
      getComputedStyle(attachments.dropzone).borderTopStyle,
      'dashed',
      'joinery.css styles it',
    )
    await attachments.select(new File(['%PDF'], 'cv.pdf', { type: 'application/pdf' }))
    await attachments.drop(new File(['…'], 'notes.txt', { type: 'text/plain' }))
    assert.deepEqual(
      attachments.files,
      ['cv.pdf', 'notes.txt'],
      "ember-file-upload's queue took them",
    )
    await attachments.remove('cv.pdf')
    assert.deepEqual(attachments.files, ['notes.txt'])
    await a11yAudit()
  })

  test('a Joinery data table, on TanStack Table, sorts its rows here', async function (assert) {
    await visit('/')
    const fruit = new DataTableHarness('fruit')
    assert.deepEqual(fruit.column('name'), ['Cherry', 'Apple', 'Banana'])
    assert.true(fruit.table.element.classList.contains('jn-table'), "it is Joinery's Table")
    await fruit.sort('name')
    assert.strictEqual(fruit.sortOf('name'), 'ascending', 'aria-sort says so')
    assert.deepEqual(fruit.column('name'), ['Apple', 'Banana', 'Cherry'], 'table-core sorted it')
    await fruit.sort('name')
    assert.deepEqual(fruit.column('name'), ['Cherry', 'Banana', 'Apple'])
    await a11yAudit()
  })
})
