import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Progress } from '@ember-joinery/ember'
import { ProgressHarness } from '@ember-joinery/test-support'

/** The colour a token resolves to here, as the browser computes it. */
function background(name: string): string {
  const probe = document.createElement('span')
  probe.style.backgroundColor = `var(${name})`
  document.querySelector('#ember-testing')!.append(probe)
  const value = getComputedStyle(probe).backgroundColor
  probe.remove()
  return value
}

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

/**
 * How much of the track the indicator fills, from 0 to 1, and from which side, once its
 * transition (`transition-all`) has run.
 */
function fill(progress: ProgressHarness): { amount: number; from: 'left' | 'right' | 'none' } {
  for (const animation of progress.indicator.getAnimations()) animation.finish()
  const track = progress.element.getBoundingClientRect()
  const bar = progress.indicator.getBoundingClientRect()
  const left = Math.max(bar.left, track.left)
  const right = Math.min(bar.right, track.right)
  const amount = Math.max(0, right - left) / track.width
  if (amount === 0) return { amount, from: 'none' }
  return { amount, from: Math.abs(left - track.left) < 1 ? 'left' : 'right' }
}

const round = (value: number) => Math.round(value * 100) / 100

module('Integration | components | progress', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream anatomy, with the value in its ARIA', async function (assert) {
    await render(<template><Progress @value={{66}} aria-label="Upload" class="mine" /></template>)
    const progress = new ProgressHarness()
    assert
      .dom(progress.element)
      .hasTagName('div')
      .hasClass('jn-progress')
      .hasClass('mine')
      .hasAttribute('data-slot', 'progress')
      .hasAttribute('role', 'progressbar')
    assert
      .dom(progress.indicator)
      .hasClass('jn-progress-indicator')
      .hasAttribute('data-slot', 'progress-indicator')
      .hasAttribute('style', 'transform: translateX(-34%)', "upstream's transform")
      .hasAttribute('data-state', 'loading')
    // Upstream's leaves its value off the Radix root, which then always reads as indeterminate;
    // Joinery's announces it.
    assert.strictEqual(progress.value, 66)
    assert.strictEqual(progress.valueText, '66%')
    assert.strictEqual(progress.state, 'loading')
    assert.strictEqual(progress.label, 'Upload')
    await a11yAudit()
  })

  test('its style sheet draws a thin track and fills it, without Tailwind', async function (assert) {
    await render(
      <template>
        <div style="width: 300px">
          <Progress @value={{66}} aria-label="Upload" />
        </div>
      </template>,
    )
    const progress = new ProgressHarness()
    const track = getComputedStyle(progress.element)
    assert.strictEqual(track.height, '4px', 'h-1')
    assert.strictEqual(track.width, '300px', 'w-full')
    assert.strictEqual(track.display, 'flex')
    assert.strictEqual(track.position, 'relative')
    assert.strictEqual(
      track.overflowX,
      'hidden',
      'overflow-x-hidden: the rest of the bar is clipped',
    )
    assert.ok(px(track.borderTopLeftRadius) > 1e6, 'rounded-full: an infinite radius')
    assert.strictEqual(track.backgroundColor, background('--muted'), 'bg-muted')

    const bar = getComputedStyle(progress.indicator)
    assert.strictEqual(bar.backgroundColor, background('--primary'), 'bg-primary')
    assert.strictEqual(bar.height, '4px', 'size-full')
    assert.strictEqual(bar.width, '300px')
    assert.ok(bar.transitionProperty === 'all', 'transition-all')

    const { amount, from } = fill(progress)
    assert.strictEqual(round(amount), 0.66, 'it fills two thirds')
    assert.strictEqual(from, 'left')
    await a11yAudit()
  })

  test('it follows its value, and @max scales it', async function (assert) {
    class State {
      @tracked value: number | null = 13
    }
    const state = new State()
    await render(
      <template>
        <Progress @name="upload" @value={{state.value}} aria-label="Upload" />
        <Progress @name="files" @value={{3}} @max={{12}} aria-label="Files" />
      </template>,
    )
    const upload = new ProgressHarness('upload')
    assert.dom(upload.indicator).hasAttribute('style', 'transform: translateX(-87%)')

    state.value = 66
    await settled()
    assert.strictEqual(upload.value, 66)
    assert.dom(upload.indicator).hasAttribute('style', 'transform: translateX(-34%)')

    state.value = null
    await settled()
    assert.true(upload.isIndeterminate)
    assert
      .dom(upload.indicator)
      .hasAttribute('style', 'transform: translateX(-100%)', 'it shows empty')
    assert.strictEqual(fill(upload).from, 'none')

    const files = new ProgressHarness('files')
    assert.strictEqual(files.valueText, '25%')
    assert
      .dom(files.indicator)
      .hasAttribute('style', 'transform: translateX(-75%)', 'a quarter of the way')
    assert.strictEqual(round(fill(files).amount), 0.25)
    await a11yAudit()
  })

  test('it is complete at its max, and full', async function (assert) {
    await render(<template><Progress @value={{100}} aria-label="Done" /></template>)
    const progress = new ProgressHarness()
    assert.true(progress.isComplete)
    assert.strictEqual(progress.state, 'complete')
    assert.strictEqual(round(fill(progress).amount), 1)
    await a11yAudit()
  })

  test('RTL: as upstream’s, it fills from the left; rotated, it mirrors', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Progress @name="plain" @value={{25}} aria-label="تقدم الرفع" />
          <Progress @name="mirrored" @value={{25}} aria-label="تقدم الرفع" style="rotate: 180deg" />
        </DirectionProvider>
      </template>,
    )
    // Upstream's right-to-left copy of the component moves the bar the same way (its transform
    // isn't a class its build can mirror), and its example adds rtl:rotate-180.
    const plain = fill(new ProgressHarness('plain'))
    assert.strictEqual(round(plain.amount), 0.25)
    assert.strictEqual(plain.from, 'left')
    const mirrored = fill(new ProgressHarness('mirrored'))
    assert.strictEqual(round(mirrored.amount), 0.25)
    assert.strictEqual(mirrored.from, 'right')
    await a11yAudit()
  })
})
