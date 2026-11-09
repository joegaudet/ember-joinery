import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, rerender, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DocumentFileDrop, FileDrop, accepts, filesFrom } from '@ember-joinery/primitives/file-drop'
import {
  FileDropHarness,
  dragFilesAway,
  dragFilesOver,
  dropFiles,
  tab,
} from '@ember-joinery/test-support'

const video = new File(['video'], 'clip.webm', { type: 'video/webm' })
const movie = new File(['movie'], 'movie.MKV', { type: '' })
const notes = new File(['notes'], 'notes.txt', { type: 'text/plain' })

const names = (files: File[]) => files.map(file => file.name).join(', ')

/** A drag of text, not files: a real DragEvent, so `dataTransfer` is as a browser's. */
function dragText(target: Element, type: string): DragEvent {
  const dataTransfer = new DataTransfer()
  dataTransfer.setData('text/plain', 'hello')
  const event = new DragEvent(type, { bubbles: true, cancelable: true, dataTransfer })
  target.dispatchEvent(event)
  return event
}

module('Integration | primitives | file-drop', function (hooks) {
  setupRenderingTest(hooks)

  test('a label for a visually hidden file input, which keeps its tab stop and its name', async function (assert) {
    const noop = () => {}
    await render(
      <template>
        <FileDrop @name="videos" @accept="video/*" @multiple={{true}} @onFiles={{noop}}>
          Drop a video here
        </FileDrop>
      </template>,
    )
    const zone = new FileDropHarness('videos')
    assert.dom(zone.element).hasTagName('label').hasAttribute('for', zone.input.id)
    assert.strictEqual(zone.input.type, 'file')
    assert.strictEqual(zone.accept, 'video/*')
    assert.true(zone.isMultiple)
    assert.strictEqual(getComputedStyle(zone.input).position, 'absolute', 'visually hidden')
    assert.strictEqual(zone.input.offsetWidth, 1)
    assert.strictEqual(zone.text, 'Drop a video here')
    assert.strictEqual(zone.input.labels![0], zone.element, 'its text names the input')
    await tab()
    assert.true(zone.isFocused, 'Tab reaches its input')
    await a11yAudit()
  })

  test('isDragging stays on while the pointer crosses children', async function (assert) {
    const noop = () => {}
    await render(
      <template>
        <FileDrop @onFiles={{noop}} as |zone|>
          <span data-test-child>{{if zone.isDragging "dragging" "idle"}}</span>
        </FileDrop>
      </template>,
    )
    const zone = new FileDropHarness()
    const child = zone.element.querySelector('[data-test-child]')!
    assert.true(await zone.drag([video]), 'it allows the drop')
    await dragFilesOver(child, [video])
    await zone.leave()
    assert.true(zone.isDragging, 'still over the child')
    assert.dom(child).hasText('dragging')
    await dragFilesAway(child)
    assert.false(zone.isDragging)
    assert.dom(child).hasText('idle')
    await a11yAudit()
  })

  test('a drop gives the files that match @accept, only the first without @multiple', async function (assert) {
    const take = (files: File[]) => assert.step(names(files))
    await render(
      <template>
        <FileDrop @name="many" @accept="video/*,.mkv" @multiple={{true}} @onFiles={{take}}>
          Many
        </FileDrop>
        <FileDrop @name="one" @onFiles={{take}}>One</FileDrop>
      </template>,
    )
    assert.true(await new FileDropHarness('many').drop([video, notes, movie]))
    await new FileDropHarness('many').drop([notes])
    await new FileDropHarness('one').drop([video, movie])
    assert.verifySteps(['clip.webm, movie.MKV', 'clip.webm'], 'nothing for no match')
    assert.false(new FileDropHarness('many').isDragging, 'a drop ends the drag')
    await a11yAudit()
  })

  test('a drag of text is not a file drag', async function (assert) {
    const take = (files: File[]) => assert.step(names(files))
    await render(
      <template>
        <FileDrop @onFiles={{take}}>Zone</FileDrop>
      </template>,
    )
    const zone = new FileDropHarness()
    dragText(zone.element, 'dragenter')
    const over = dragText(zone.element, 'dragover')
    await settled()
    assert.false(zone.isDragging)
    assert.false(over.defaultPrevented, 'no drop of text')
    assert.verifySteps([])
    await a11yAudit()
  })

  test('a pick gives the files, and the same file can be picked again', async function (assert) {
    const take = (files: File[]) => assert.step(names(files))
    await render(
      <template>
        <FileDrop @accept=".mkv" @onFiles={{take}}>Zone</FileDrop>
      </template>,
    )
    const zone = new FileDropHarness()
    await zone.pick([movie])
    assert.strictEqual(zone.input.value, '', 'the input is cleared')
    await zone.pick([movie])
    assert.verifySteps(['movie.MKV', 'movie.MKV'])
    await a11yAudit()
  })

  test('@disabled takes no files', async function (assert) {
    class State {
      @tracked disabled = true
    }
    const state = new State()
    const take = (files: File[]) => assert.step(names(files))
    await render(
      <template>
        <FileDrop @disabled={{state.disabled}} @onFiles={{take}}>Zone</FileDrop>
      </template>,
    )
    const zone = new FileDropHarness()
    assert.true(zone.isDisabled)
    assert.dom(zone.element).hasAttribute('data-disabled')
    assert.false(await zone.drag([video]), 'it allows no drop')
    assert.false(zone.isDragging)
    assert.true(await zone.drop([video]), 'a drop is still kept from the tab')
    assert.verifySteps([])
    state.disabled = false
    await rerender()
    await zone.drop([video])
    assert.verifySteps(['clip.webm'])
    await a11yAudit()
  })

  test('accepts() and filesFrom() read an accept list as the file input does', function (assert) {
    assert.true(accepts(video, undefined))
    assert.true(accepts(video, 'video/*'))
    assert.true(accepts(movie, ' .mkv , image/png'), 'extensions match in any case')
    assert.false(accepts(notes, 'video/webm,.mkv'))
    assert.true(accepts(notes, 'text/plain'))
    assert.deepEqual(filesFrom(null, undefined, true), [])
  })

  module('DocumentFileDrop', function () {
    test('a drop anywhere on the page gives the files, and isDragging shows the drag', async function (assert) {
      const take = (files: File[]) => assert.step(names(files))
      await render(
        <template>
          <DocumentFileDrop @accept="video/*" @onFiles={{take}} as |page|>
            <p data-test-state>{{if page.isDragging "dragging" "idle"}}</p>
          </DocumentFileDrop>
        </template>,
      )
      assert.true(await dragFilesOver(document.body, [video]))
      assert.dom('[data-test-state]').hasText('dragging')
      await dragFilesAway(document.body)
      assert.dom('[data-test-state]').hasText('idle')
      assert.true(await dropFiles(document.body, [notes, video]), 'kept from the tab')
      assert.true(await dropFiles(document.body, [notes]), 'a drop that matches nothing too')
      assert.verifySteps(['clip.webm'])
      await a11yAudit()
    })

    test('a drop on a FileDrop goes only to the FileDrop', async function (assert) {
      const page = (files: File[]) => assert.step(`page ${names(files)}`)
      const zone = (files: File[]) => assert.step(`zone ${names(files)}`)
      await render(
        <template>
          <DocumentFileDrop @onFiles={{page}} />
          <FileDrop @onFiles={{zone}}>Zone</FileDrop>
        </template>,
      )
      await new FileDropHarness().drop([video])
      await dropFiles(document.body, [video])
      assert.verifySteps(['zone clip.webm', 'page clip.webm'])
      await a11yAudit()
    })

    test('it stops listening when it leaves the page', async function (assert) {
      class State {
        @tracked shown = true
      }
      const state = new State()
      const take = (files: File[]) => assert.step(names(files))
      await render(
        <template>
          {{#if state.shown}}
            <DocumentFileDrop @onFiles={{take}} />
          {{/if}}
        </template>,
      )
      state.shown = false
      await rerender()
      assert.false(await dropFiles(document.body, [video]))
      assert.verifySteps([])
      await a11yAudit()
    })
  })
})
