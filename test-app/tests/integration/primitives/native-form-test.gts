import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  NativeForm,
  dataFromEvent,
  type NativeFormData,
  type NativeFormEventType,
} from '@ember-joinery/primitives/native-form'
import { Checkbox } from '@ember-joinery/ember'
import { CheckboxHarness, NativeFormHarness } from '@ember-joinery/test-support'

module('Integration | primitives | native-form', function (hooks) {
  setupRenderingTest(hooks)

  test('each input hands over the whole form’s data; a submit too, without a page load', async function (assert) {
    const calls: Array<[NativeFormData, NativeFormEventType, string]> = []
    const record = (data: NativeFormData, type: NativeFormEventType, event: Event) =>
      calls.push([data, type, event.type])
    await render(
      <template>
        <NativeForm @name="profile" @onChange={{record}}>
          <label>First Name <input name="firstName" value="Gwen" /></label>
          <fieldset>
            <legend>Travel to a universe</legend>
            <label>65 <input name="universe" type="radio" value="65" /></label>
            <label>616 <input name="universe" type="radio" value="616" /></label>
          </fieldset>
          <button type="submit">Save</button>
        </NativeForm>
      </template>,
    )
    const profile = new NativeFormHarness('profile')
    assert.dom(profile.form).hasTagName('form').hasAttribute('data-test-jn', 'native-form')
    await profile.fillIn('firstName', 'Miles')
    assert.deepEqual(calls.at(-1), [{ firstName: 'Miles', universe: null }, 'input', 'input'])
    await profile.choose('universe', '616')
    assert.deepEqual(calls.at(-1)![0], { firstName: 'Miles', universe: '616' })
    assert.deepEqual(profile.entries, { firstName: 'Miles', universe: '616' })

    await profile.submit()
    const [data, type, eventType] = calls.at(-1)!
    assert.deepEqual(data, { firstName: 'Miles', universe: '616' })
    assert.strictEqual(type, 'submit')
    assert.strictEqual(eventType, 'submit')
    assert.notOk(window.location.search.includes('firstName'), 'the page did not load')
    await a11yAudit()
  })

  test('numbers, checkboxes, several values and selects come out as dataFromEvent reads them', async function (assert) {
    let latest: NativeFormData = {}
    const record = (data: NativeFormData) => (latest = data)
    await render(
      <template>
        <NativeForm @onChange={{record}}>
          <label>Age <input name="age" type="number" value="30" /></label>
          <label>Subscribe <input name="subscribe" type="checkbox" /></label>
          <label>Red <input name="colours" type="checkbox" value="red" /></label>
          <label>Blue <input name="colours" type="checkbox" value="blue" /></label>
          <label>Size
            <select name="size">
              <option value="s">Small</option>
              <option value="m">Medium</option>
            </select>
          </label>
          <button type="submit">Save</button>
        </NativeForm>
      </template>,
    )
    const form = new NativeFormHarness()
    await form.toggle('subscribe')
    await form.toggle('colours', 'blue')
    await form.select('size', 'm')
    assert.deepEqual(latest, { age: 30, subscribe: true, colours: ['blue'], size: 'm' })
    await a11yAudit()
  })

  test('Joinery’s button controls take part through their hidden inputs', async function (assert) {
    let latest: NativeFormData = {}
    const record = (data: NativeFormData) => (latest = data)
    await render(
      <template>
        <NativeForm @onChange={{record}}>
          <Checkbox name="terms" id="terms" />
          <label for="terms">Accept terms</label>
        </NativeForm>
      </template>,
    )
    await new CheckboxHarness().check()
    assert.deepEqual(latest, { terms: 'on' })
    await a11yAudit()
  })

  test('dataFromEvent() reads a form of your own', async function (assert) {
    let latest: NativeFormData = {}
    const save = (event: SubmitEvent) => {
      event.preventDefault()
      latest = dataFromEvent(event)
    }
    await render(
      <template>
        <form data-test-own {{on "submit" save}}>
          <label>Name <input name="name" value="Ada" /></label>
          <button type="submit">Save</button>
        </form>
      </template>,
    )
    await click('[data-test-own] button')
    assert.deepEqual(latest, { name: 'Ada' })
    await a11yAudit()
  })

  test('keyboard: Enter in a field submits the form, as the browser does; not in a textarea', async function (assert) {
    const calls: Array<[NativeFormData, NativeFormEventType]> = []
    const record = (data: NativeFormData, type: NativeFormEventType) => calls.push([data, type])
    await render(
      <template>
        <NativeForm @name="search" @onChange={{record}}>
          <label>Query <input name="query" type="search" value="ember" /></label>
          <label>Notes <textarea name="notes"></textarea></label>
          <button type="submit" name="intent" value="search">Search</button>
        </NativeForm>
        <NativeForm @name="lone" @onChange={{record}}>
          <label>Code <input name="code" value="1234" /></label>
        </NativeForm>
        <NativeForm @name="held" @onChange={{record}}>
          <label>Name <input name="name" value="Ada" /></label>
          <button type="submit" disabled>Save</button>
        </NativeForm>
      </template>,
    )
    const search = new NativeFormHarness('search')
    await search.pressEnter('query')
    assert.deepEqual(
      calls.at(-1),
      [{ query: 'ember', notes: '', intent: 'search' }, 'submit'],
      'its default button submits it, and is the submitter',
    )
    const before = calls.length
    await search.pressEnter('notes')
    assert.strictEqual(calls.length, before, 'Enter in a textarea is a new line, not a submit')

    await new NativeFormHarness('lone').pressEnter('code')
    assert.deepEqual(calls.at(-1), [{ code: '1234' }, 'submit'], 'a lone field submits alone')

    const count = calls.length
    await new NativeFormHarness('held').pressEnter('name')
    assert.strictEqual(calls.length, count, 'a disabled default button holds the form back')
    assert.notOk(window.location.search.includes('query'), 'the page did not load')
    await a11yAudit()
  })

  test('RTL: a form right to left hands over its fields as written', async function (assert) {
    let latest: NativeFormData = {}
    let type: NativeFormEventType | undefined
    const record = (data: NativeFormData, eventType: NativeFormEventType) => {
      latest = data
      type = eventType
    }
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <NativeForm @name="profile" @onChange={{record}}>
            <label>الاسم <input name="الاسم" value="أحمد" /></label>
            <label>العمر <input name="age" type="number" value="30" /></label>
            <button type="submit">حفظ</button>
          </NativeForm>
        </DirectionProvider>
      </template>,
    )
    const profile = new NativeFormHarness('profile')
    assert.strictEqual(getComputedStyle(profile.form).direction, 'rtl')
    await profile.fillIn('الاسم', 'سارة')
    assert.deepEqual(latest, { الاسم: 'سارة', age: 30 })
    assert.strictEqual(type, 'input')
    await profile.pressEnter('age')
    assert.deepEqual(latest, { الاسم: 'سارة', age: 30 })
    assert.strictEqual(type, 'submit', 'Enter submits right to left too')
    await a11yAudit()
  })

  test('the harness fails clearly for a control it has not got', async function (assert) {
    const noop = () => {}
    await render(<template><NativeForm @onChange={{noop}} /></template>)
    assert.throws(() => new NativeFormHarness().controls('missing'), /no control named "missing"/)
    await a11yAudit()
  })
})
