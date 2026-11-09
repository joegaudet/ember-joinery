import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  Progress,
  defaultProgressLabel,
  progressState,
  resolveProgress,
} from '@ember-joinery/primitives/progress'
import { ProgressHarness } from '@ember-joinery/test-support'

function withLabel(value: number, max: number): string {
  return `${value} of ${max} files`
}

module('Integration | primitives | progress', function (hooks) {
  setupRenderingTest(hooks)

  test('it is a progressbar with its value in ARIA and data attributes, and no styles', async function (assert) {
    await render(
      <template>
        <Progress @value={{30}} aria-label="Upload" class="mine" as |p|>
          <p.Indicator class="bar" />
        </Progress>
      </template>,
    )
    const progress = new ProgressHarness()
    assert
      .dom(progress.element)
      .hasTagName('div')
      .hasClass('mine')
      .hasAttribute('role', 'progressbar')
      .hasAttribute('aria-valuemin', '0')
      .hasAttribute('aria-valuemax', '100')
      .hasAttribute('aria-valuenow', '30')
      .hasAttribute('aria-valuetext', '30%')
      .hasAttribute('data-state', 'loading')
      .hasAttribute('data-value', '30')
      .hasAttribute('data-max', '100')
      .hasAttribute('data-min', '0')
      .hasAttribute('data-percent', '30')
      .doesNotHaveAttribute('data-slot', 'no styles, so no slot')
    assert
      .dom(progress.indicator)
      .hasClass('bar')
      .hasAttribute('data-state', 'loading')
      .hasAttribute('data-value', '30')
      .hasAttribute('data-max', '100')
      .hasAttribute('data-percent', '30')
    assert.strictEqual(progress.value, 30)
    assert.strictEqual(progress.max, 100)
    assert.strictEqual(progress.min, 0)
    assert.strictEqual(progress.valueText, '30%')
    assert.strictEqual(progress.state, 'loading')
    assert.strictEqual(progress.percent, 30)
    assert.strictEqual(progress.label, 'Upload')
    await a11yAudit()
  })

  test('without a value it is indeterminate, as Radix: no aria-valuenow or valuetext', async function (assert) {
    await render(
      <template>
        <Progress aria-label="Loading" as |p|><p.Indicator /></Progress>
      </template>,
    )
    const progress = new ProgressHarness()
    assert
      .dom(progress.element)
      .doesNotHaveAttribute('aria-valuenow')
      .doesNotHaveAttribute('aria-valuetext')
      .doesNotHaveAttribute('data-value')
      .doesNotHaveAttribute('data-percent')
      .hasAttribute('data-state', 'indeterminate')
    assert.dom(progress.indicator).hasAttribute('data-state', 'indeterminate')
    assert.true(progress.isIndeterminate)
    assert.false(progress.isComplete)
    assert.strictEqual(progress.value, null)
    assert.strictEqual(progress.percent, null)
    await a11yAudit()
  })

  test('at its max it is complete; @max scales the percent', async function (assert) {
    await render(
      <template>
        <Progress @name="done" @value={{100}} aria-label="Done" />
        <Progress @name="files" @value={{3}} @max={{12}} aria-label="Files" as |p|>
          <p.Indicator />
        </Progress>
      </template>,
    )
    const done = new ProgressHarness('done')
    assert.strictEqual(done.state, 'complete')
    assert.true(done.isComplete)

    const files = new ProgressHarness('files')
    assert.strictEqual(files.max, 12)
    assert.strictEqual(files.value, 3)
    assert.strictEqual(files.valueText, '25%')
    assert.strictEqual(files.percent, 25)
    assert.dom(files.indicator).hasAttribute('data-max', '12')
    await a11yAudit()
  })

  test('out-of-range values clamp, as ember-primitives; an invalid @max is 100', async function (assert) {
    await render(
      <template>
        <Progress @name="over" @value={{150}} aria-label="Over" />
        <Progress @name="under" @value={{-5}} aria-label="Under" />
        <Progress @name="nan" @value={{NaN}} aria-label="Not a number" />
        <Progress @name="max" @value={{50}} @max={{0}} aria-label="No max" />
      </template>,
    )
    assert.strictEqual(new ProgressHarness('over').value, 100)
    assert.strictEqual(new ProgressHarness('over').state, 'complete')
    assert.strictEqual(new ProgressHarness('under').value, 0)
    assert.strictEqual(new ProgressHarness('nan').value, 0)
    assert.strictEqual(new ProgressHarness('max').max, 100)
    assert.strictEqual(new ProgressHarness('max').value, 50)
    await a11yAudit()
  })

  test('it yields its value, percent and decimal, and @getValueLabel names the value', async function (assert) {
    await render(
      <template>
        <Progress @value={{1}} @max={{3}} @getValueLabel={{withLabel}} aria-label="Files" as |p|>
          <p.Indicator />
          <output data-percent={{p.percent}} data-decimal={{p.decimal}}>{{p.value}}/{{p.max}}
            {{p.state}}</output>
        </Progress>
      </template>,
    )
    const progress = new ProgressHarness()
    assert.strictEqual(progress.valueText, '1 of 3 files')
    // Not named `output`: a binding by that name would make the template's <output> a call to it.
    const yielded = progress.element.querySelector('output')!
    assert.dom(yielded).hasText('1/3 loading')
    assert.strictEqual(yielded.getAttribute('data-percent'), '33.33', 'rounded to two places')
    assert.strictEqual(Number(yielded.getAttribute('data-decimal')).toFixed(4), '0.3333')
    await a11yAudit()
  })

  test('it follows its value', async function (assert) {
    class State {
      @tracked value: number | undefined = 10
    }
    const state = new State()
    await render(
      <template>
        <Progress @value={{state.value}} aria-label="Upload" as |p|><p.Indicator /></Progress>
      </template>,
    )
    const progress = new ProgressHarness()
    assert.strictEqual(progress.value, 10)

    state.value = 90
    await settled()
    assert.strictEqual(progress.value, 90)
    assert.strictEqual(progress.valueText, '90%')
    assert.dom(progress.indicator).hasAttribute('data-value', '90')

    state.value = undefined
    await settled()
    assert.true(progress.isIndeterminate)
    await a11yAudit()
  })

  test('the harness reads its name from aria-labelledby, as assistive technology does', async function (assert) {
    await render(
      <template>
        <span id="caption">Upload</span>
        <span id="detail">progress</span>
        <Progress @name="labelled" @value={{5}} aria-labelledby="caption detail" />
      </template>,
    )
    assert.strictEqual(new ProgressHarness('labelled').label, 'Upload progress')
    assert.throws(() => new ProgressHarness('missing').element, /no progress "missing" found/)
    await a11yAudit()
  })

  test('its functions, for an element of your own', function (assert) {
    assert.deepEqual(resolveProgress(40, undefined), {
      value: 40,
      max: 100,
      percent: 40,
      decimal: 0.4,
      state: 'loading',
    })
    assert.deepEqual(resolveProgress(undefined, 10), {
      value: null,
      max: 10,
      percent: 0,
      decimal: 0,
      state: 'indeterminate',
    })
    assert.strictEqual(progressState(10, 10), 'complete')
    assert.strictEqual(progressState(null, 10), 'indeterminate')
    assert.strictEqual(defaultProgressLabel(1, 3), '33%')
  })
})
