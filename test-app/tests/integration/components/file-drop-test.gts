import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Upload } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { DocumentFileDrop, FileDrop, Icon } from '@ember-joinery/ember'
import {
  DocumentFileDropHarness,
  FileDropHarness,
  IconHarness,
  dropFiles,
  tab,
} from '@ember-joinery/test-support'

/** A colour as the browser resolves it, for comparing with a token. */
function resolved(color: string): string {
  const probe = document.createElement('span')
  probe.style.color = color
  document.querySelector('#ember-testing')!.append(probe)
  const value = getComputedStyle(probe).color
  probe.remove()
  return value
}

/** Waits for the zone's colour transitions (`transition-colors`) to end. */
async function transitioned(element: Element): Promise<void> {
  await Promise.all(element.getAnimations().map(animation => animation.finished))
}

const photo = new File(['photo'], 'photo.png', { type: 'image/png' })
const names = (files: File[]) => files.map(file => file.name).join(', ')

module('Integration | components | file-drop', function (hooks) {
  setupRenderingTest(hooks)

  test('a dashed drop zone, which turns --primary while files are dragged over it', async function (assert) {
    const take = (files: File[]) => assert.step(names(files))
    await render(
      <template>
        <FileDrop @name="photos" @accept="image/*" @onFiles={{take}} as |zone|>
          {{if zone.isDragging "Drop to upload" "Drag a photo here, or click to choose"}}
        </FileDrop>
      </template>,
    )
    const zone = new FileDropHarness('photos')
    assert
      .dom(zone.element)
      .hasTagName('label')
      .hasClass('jn-file-drop')
      .hasAttribute('data-slot', 'file-drop')
    const idle = getComputedStyle(zone.element)
    assert.strictEqual(idle.borderTopStyle, 'dashed')
    assert.strictEqual(idle.borderTopWidth, '1px')
    assert.strictEqual(idle.borderTopColor, resolved('var(--input)'))
    assert.strictEqual(idle.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(idle.paddingTop, '24px', 'p-6')
    assert.strictEqual(idle.color, resolved('var(--muted-foreground)'))
    assert.strictEqual(idle.cursor, 'pointer')
    assert.strictEqual(zone.text, 'Drag a photo here, or click to choose')

    await zone.drag([photo])
    assert.true(zone.isDragging)
    assert.strictEqual(zone.text, 'Drop to upload')
    await transitioned(zone.element)
    assert.strictEqual(getComputedStyle(zone.element).borderTopColor, resolved('var(--primary)'))
    await zone.drop([photo])
    assert.false(zone.isDragging)
    assert.verifySteps(['photo.png'])
    await a11yAudit()
  })

  test('Tab reaches its input, which shows the ring on the zone; a disabled zone dims', async function (assert) {
    const noop = () => {}
    await render(
      <template>
        <FileDrop @name="on" @onFiles={{noop}}>Choose a file</FileDrop>
        <FileDrop @name="off" @disabled={{true}} @onFiles={{noop}}>Choose a file</FileDrop>
      </template>,
    )
    const on = new FileDropHarness('on')
    await tab()
    assert.true(on.isFocused)
    await transitioned(on.element)
    const focused = getComputedStyle(on.element)
    assert.notStrictEqual(focused.boxShadow, 'none', 'has-[:focus-visible]:ring-3')
    assert.strictEqual(focused.borderTopColor, resolved('var(--ring)'))
    const off = new FileDropHarness('off')
    assert.true(off.isDisabled)
    assert.strictEqual(getComputedStyle(off.element).opacity, '0.5')
    await a11yAudit()
  })

  test('RTL: the zone and the overlay keep their content centred, right to left', async function (assert) {
    const noop = () => {}
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div style="width: 320px">
            <FileDrop @onFiles={{noop}}>
              <Icon @icon={{Upload}} />
              اسحب صورة إلى هنا، أو انقر للاختيار
            </FileDrop>
          </div>
          <DocumentFileDrop @onFiles={{noop}}>
            <Icon @icon={{Upload}} />
            أفلت الملفات في أي مكان
          </DocumentFileDrop>
        </DirectionProvider>
      </template>,
    )
    const zone = new FileDropHarness()
    assert.strictEqual(getComputedStyle(zone.element).direction, 'rtl')
    const box = zone.element.getBoundingClientRect()
    const icon = zone.find(IconHarness).element.getBoundingClientRect()
    assert.true(
      Math.abs(icon.left + icon.width / 2 - (box.left + box.width / 2)) < 1,
      'the icon is centred',
    )
    assert.true(zone.element.scrollWidth <= zone.element.clientWidth, 'nothing overflows it')
    const input = zone.input.getBoundingClientRect()
    assert.true(input.left >= box.left && input.right <= box.right, 'its input stays inside it')

    const overlay = new DocumentFileDropHarness()
    await overlay.drag([photo])
    assert.true(overlay.isShown)
    assert.strictEqual(overlay.text, 'أفلت الملفات في أي مكان')
    const cover = getComputedStyle(overlay.element)
    assert.strictEqual(cover.position, 'fixed')
    assert.deepEqual(
      [cover.left, cover.right, cover.top, cover.bottom],
      ['0px', '0px', '0px', '0px'],
      'inset-0 covers the page from either side',
    )
    assert.strictEqual(cover.justifyContent, 'center', 'its content centred')
    await a11yAudit()
    await overlay.leave()
  })

  test('DocumentFileDrop covers the page while files are dragged over it', async function (assert) {
    const page = (files: File[]) => assert.step(`page ${names(files)}`)
    const zone = (files: File[]) => assert.step(`zone ${names(files)}`)
    await render(
      <template>
        <DocumentFileDrop @onFiles={{page}} />
        <DocumentFileDrop @name="custom" @accept="image/*" @onFiles={{page}}>
          <span>Drop your photos</span>
        </DocumentFileDrop>
        <FileDrop @onFiles={{zone}}>Zone</FileDrop>
      </template>,
    )
    const overlay = new DocumentFileDropHarness()
    assert.false(overlay.isShown)
    await overlay.drag([photo])
    assert.true(overlay.isShown)
    assert.strictEqual(overlay.text, 'Drop files anywhere')
    assert.strictEqual(new DocumentFileDropHarness('custom').text, 'Drop your photos')
    const style = getComputedStyle(overlay.element)
    assert.strictEqual(style.position, 'fixed')
    assert.strictEqual(style.pointerEvents, 'none', 'the pointer goes through to the page')
    await a11yAudit()

    await overlay.leave()
    assert.false(overlay.isShown)
    await new FileDropHarness().drop([photo])
    assert.true(await dropFiles(document.body, [photo]))
    assert.verifySteps(
      ['zone photo.png', 'page photo.png'],
      'the first DocumentFileDrop takes a page drop, and the next leaves it',
    )
    await a11yAudit()
  })
})
