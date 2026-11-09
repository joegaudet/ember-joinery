import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { focus, render, settled } from '@ember/test-helpers'
import { array } from '@ember/helper'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Accordion } from '@ember-joinery/primitives/accordion'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { AccordionHarness, tab } from '@ember-joinery/test-support'

const ITEMS = [
  { value: 'shipping', title: 'Shipping', content: 'Standard, express and overnight.' },
  { value: 'returns', title: 'Returns', content: 'Within 30 days.' },
  { value: 'support', title: 'Support', content: 'Email, chat or phone.' },
]

module('Integration | primitives | accordion', function (hooks) {
  setupRenderingTest(hooks)

  test('each item is a heading with a trigger that controls its region', async function (assert) {
    await render(
      <template>
        <Accordion @type="single" @name="faq" as |acc|>
          {{#each ITEMS as |item|}}
            <acc.Item @value={{item.value}} as |i|>
              <i.Header as |h|><h.Trigger>{{item.title}}</h.Trigger></i.Header>
              <i.Content>{{item.content}}</i.Content>
            </acc.Item>
          {{/each}}
        </Accordion>
      </template>,
    )
    const faq = new AccordionHarness('faq')
    assert.deepEqual(faq.itemValues, ['shipping', 'returns', 'support'])
    assert.deepEqual(faq.titles, ['Shipping', 'Returns', 'Support'])
    assert.deepEqual(faq.openValues, [], 'nothing is open to start')
    assert.strictEqual(faq.orientation, 'vertical')

    const trigger = faq.trigger('shipping')
    const content = faq.content('shipping')
    assert.dom(faq.header('shipping')).hasTagName('h3').hasAttribute('data-state', 'closed')
    assert.dom(trigger).hasTagName('button').hasAttribute('type', 'button')
    assert.dom(trigger).hasAttribute('aria-expanded', 'false').hasAttribute('id')
    assert.dom(trigger).hasAttribute('aria-controls', content.id)
    assert.dom(trigger).hasAttribute('data-orientation', 'vertical')
    assert.dom(content).hasAttribute('role', 'region').hasAttribute('aria-labelledby', trigger.id)
    assert.dom(content).hasAttribute('hidden').hasText('')
    assert.dom(faq.item('shipping')).hasAttribute('data-state', 'closed')
    assert.dom(faq.item('shipping')).hasAttribute('data-orientation', 'vertical')
    assert.strictEqual(
      content.style.getPropertyValue('--radix-accordion-content-height'),
      'var(--radix-collapsible-content-height)',
      "the accordion's size variables read the collapsible's",
    )
    await a11yAudit()
  })

  test('single: opening an item closes the one open before, and the open one stays open', async function (assert) {
    const values: string[] = []
    const heard = (value: string) => values.push(value)
    await render(
      <template>
        <Accordion @type="single" @defaultValue="shipping" @onValueChange={{heard}} as |acc|>
          {{#each ITEMS as |item|}}
            <acc.Item @value={{item.value}} as |i|>
              <i.Header as |h|><h.Trigger>{{item.title}}</h.Trigger></i.Header>
              <i.Content>{{item.content}}</i.Content>
            </acc.Item>
          {{/each}}
        </Accordion>
      </template>,
    )
    const faq = new AccordionHarness()
    assert.deepEqual(faq.openValues, ['shipping'], '@defaultValue')
    assert.strictEqual(faq.text('shipping'), 'Standard, express and overnight.')
    assert.true(faq.isLocked('shipping'), 'the open trigger is aria-disabled: it cannot close it')

    await faq.toggle('shipping')
    assert.deepEqual(faq.openValues, ['shipping'], 'without @collapsible it stays open')

    await faq.toggle('returns')
    assert.deepEqual(faq.openValues, ['returns'])
    assert.false(faq.isShown('shipping'))
    assert.false(faq.isLocked('shipping'))
    assert.true(faq.isLocked('returns'))
    assert.deepEqual(values, ['returns'], '@onValueChange hears the new value')
    await a11yAudit()
  })

  test('single and @collapsible: the open item closes, leaving none', async function (assert) {
    const values: string[] = []
    const heard = (value: string) => values.push(value)
    await render(
      <template>
        <Accordion @type="single" @collapsible={{true}} @onValueChange={{heard}} as |acc|>
          {{#each ITEMS as |item|}}
            <acc.Item @value={{item.value}} as |i|>
              <i.Header as |h|><h.Trigger>{{item.title}}</h.Trigger></i.Header>
              <i.Content>{{item.content}}</i.Content>
            </acc.Item>
          {{/each}}
        </Accordion>
      </template>,
    )
    const faq = new AccordionHarness()
    await faq.open('support')
    assert.false(faq.isLocked('support'), 'it can close')
    await faq.close('support')
    assert.deepEqual(faq.openValues, [])
    assert.deepEqual(values, ['support', ''], "closed, the value is ''")
    await a11yAudit()
  })

  test('multiple: any number open, from an array', async function (assert) {
    const values: string[][] = []
    const heard = (value: string[]) => values.push(value)
    await render(
      <template>
        <Accordion
          @type="multiple"
          @defaultValue={{array "shipping"}}
          @onValueChange={{heard}}
          as |acc|
        >
          {{#each ITEMS as |item|}}
            <acc.Item @value={{item.value}} as |i|>
              <i.Header as |h|><h.Trigger>{{item.title}}</h.Trigger></i.Header>
              <i.Content>{{item.content}}</i.Content>
            </acc.Item>
          {{/each}}
        </Accordion>
      </template>,
    )
    const faq = new AccordionHarness()
    assert.deepEqual(faq.openValues, ['shipping'])
    await faq.open('support')
    assert.deepEqual(faq.openValues, ['shipping', 'support'])
    assert.false(faq.isLocked('shipping'), 'every item can close')
    await faq.close('shipping')
    assert.deepEqual(faq.openValues, ['support'])
    assert.deepEqual(values, [['shipping', 'support'], ['support']])
    await a11yAudit()
  })

  test('controlled: @value is the state, and @onValueChange asks to change it', async function (assert) {
    class State {
      @tracked single = 'returns'
      @tracked multiple: string[] = []
      asked: unknown[] = []
      setSingle = (value: string) => this.asked.push(value)
      setMultiple = (value: string[]) => {
        this.asked.push(value)
        this.multiple = value
      }
    }
    const state = new State()
    await render(
      <template>
        <Accordion
          @type="single"
          @name="single"
          @value={{state.single}}
          @onValueChange={{state.setSingle}}
          as |acc|
        >
          {{#each ITEMS as |item|}}
            <acc.Item @value={{item.value}} as |i|>
              <i.Header as |h|><h.Trigger>{{item.title}}</h.Trigger></i.Header>
              <i.Content>{{item.content}}</i.Content>
            </acc.Item>
          {{/each}}
        </Accordion>
        <Accordion
          @type="multiple"
          @name="multiple"
          @value={{state.multiple}}
          @onValueChange={{state.setMultiple}}
          as |acc|
        >
          {{#each ITEMS as |item|}}
            <acc.Item @value={{item.value}} as |i|>
              <i.Header as |h|><h.Trigger>{{item.title}}</h.Trigger></i.Header>
              <i.Content>{{item.content}}</i.Content>
            </acc.Item>
          {{/each}}
        </Accordion>
      </template>,
    )
    const single = new AccordionHarness('single')
    assert.deepEqual(single.openValues, ['returns'])
    await single.toggle('shipping')
    assert.deepEqual(state.asked, ['shipping'], 'it asks')
    assert.deepEqual(single.openValues, ['returns'], 'but follows @value')
    state.single = 'shipping'
    await settled()
    assert.deepEqual(single.openValues, ['shipping'])

    const multiple = new AccordionHarness('multiple')
    await multiple.toggle('support')
    await multiple.toggle('returns')
    assert.deepEqual(multiple.openValues, ['returns', 'support'])
    assert.deepEqual(state.multiple, ['support', 'returns'], 'in the order they opened')
    await a11yAudit()
  })

  test('disabled: an item, or the whole accordion, cannot be opened', async function (assert) {
    await render(
      <template>
        <Accordion @type="single" @collapsible={{true}} @name="item" as |acc|>
          {{#each ITEMS as |item|}}
            <acc.Item @value={{item.value}} @disabled={{if (eq item.value "returns") true}} as |i|>
              <i.Header as |h|><h.Trigger>{{item.title}}</h.Trigger></i.Header>
              <i.Content>{{item.content}}</i.Content>
            </acc.Item>
          {{/each}}
        </Accordion>
        <Accordion @type="multiple" @disabled={{true}} @name="all" as |acc|>
          <acc.Item @value="one" as |i|>
            <i.Header as |h|><h.Trigger>One</h.Trigger></i.Header>
            <i.Content>First.</i.Content>
          </acc.Item>
        </Accordion>
      </template>,
    )
    const faq = new AccordionHarness('item')
    assert.true(faq.isDisabled('returns'))
    assert.false(faq.isDisabled('shipping'))
    assert.dom(faq.item('returns')).hasAttribute('data-disabled', '')
    assert.dom(faq.header('returns')).hasAttribute('data-disabled', '')
    assert.dom(faq.content('returns')).hasAttribute('data-disabled', '')
    await faq.toggle('returns').catch(() => undefined)
    assert.deepEqual(faq.openValues, [])

    const all = new AccordionHarness('all')
    assert.true(all.isDisabled('one'), "the accordion's @disabled disables every item")
    await all.toggle('one').catch(() => undefined)
    assert.deepEqual(all.openValues, [])
    await a11yAudit()
  })

  test('keyboard: the arrows move between triggers and wrap, Home and End go to the ends, disabled ones are passed over', async function (assert) {
    await render(
      <template>
        <button id="before" type="button">Before</button>
        <Accordion @type="single" @collapsible={{true}} as |acc|>
          <acc.Item @value="one" as |i|>
            <i.Header as |h|><h.Trigger>One</h.Trigger></i.Header>
            <i.Content><a href="#one">Link</a></i.Content>
          </acc.Item>
          <acc.Item @value="two" @disabled={{true}} as |i|>
            <i.Header as |h|><h.Trigger>Two</h.Trigger></i.Header>
            <i.Content>Second.</i.Content>
          </acc.Item>
          <acc.Item @value="three" as |i|>
            <i.Header as |h|><h.Trigger>Three</h.Trigger></i.Header>
            <i.Content>Third.</i.Content>
          </acc.Item>
          <acc.Item @value="four" as |i|>
            <i.Header as |h|><h.Trigger>Four</h.Trigger></i.Header>
            <i.Content>Fourth.</i.Content>
          </acc.Item>
        </Accordion>
      </template>,
    )
    const faq = new AccordionHarness()
    await focus('#before')
    await tab()
    assert.strictEqual(faq.focused, 'one', 'every trigger is in the tab order')
    await tab()
    assert.strictEqual(faq.focused, 'three', 'but a disabled one')

    await faq.focus('one')
    assert.true(await faq.press('ArrowDown'), 'the accordion takes the key')
    assert.strictEqual(faq.focused, 'three', 'ArrowDown passes over the disabled item')
    await faq.press('ArrowDown')
    assert.strictEqual(faq.focused, 'four')
    await faq.press('ArrowDown')
    assert.strictEqual(faq.focused, 'one', 'and wraps round')
    await faq.press('ArrowUp')
    assert.strictEqual(faq.focused, 'four', 'ArrowUp wraps back')
    await faq.press('Home')
    assert.strictEqual(faq.focused, 'one')
    await faq.press('End')
    assert.strictEqual(faq.focused, 'four')
    await faq.press('ArrowRight')
    assert.strictEqual(faq.focused, 'four', 'left and right do nothing when vertical')

    await faq.toggle('one')
    await faq.focus('one')
    await tab()
    assert.dom('a[href="#one"]').isFocused('Tab goes into the open content')
    assert.false(await faq.press('ArrowDown'), 'a key from inside the content is left alone')
    await a11yAudit()
  })

  test('keyboard: horizontal, left and right move, and swap right to left', async function (assert) {
    await render(
      <template>
        <Accordion @type="single" @orientation="horizontal" @name="ltr" as |acc|>
          {{#each ITEMS as |item|}}
            <acc.Item @value={{item.value}} as |i|>
              <i.Header as |h|><h.Trigger>{{item.title}}</h.Trigger></i.Header>
              <i.Content>{{item.content}}</i.Content>
            </acc.Item>
          {{/each}}
        </Accordion>
        <DirectionProvider @dir="rtl">
          <Accordion @type="single" @orientation="horizontal" @name="rtl" as |acc|>
            {{#each ITEMS as |item|}}
              <acc.Item @value={{item.value}} as |i|>
                <i.Header as |h|><h.Trigger>{{item.title}}</h.Trigger></i.Header>
                <i.Content>{{item.content}}</i.Content>
              </acc.Item>
            {{/each}}
          </Accordion>
        </DirectionProvider>
        <Accordion @type="single" @orientation="horizontal" @dir="rtl" @name="dir" as |acc|>
          {{#each ITEMS as |item|}}
            <acc.Item @value={{item.value}} as |i|>
              <i.Header as |h|><h.Trigger>{{item.title}}</h.Trigger></i.Header>
              <i.Content>{{item.content}}</i.Content>
            </acc.Item>
          {{/each}}
        </Accordion>
      </template>,
    )
    const ltr = new AccordionHarness('ltr')
    assert.strictEqual(ltr.orientation, 'horizontal')
    await ltr.focus('shipping')
    await ltr.press('ArrowRight')
    assert.strictEqual(ltr.focused, 'returns')
    await ltr.press('ArrowLeft')
    assert.strictEqual(ltr.focused, 'shipping')
    await ltr.press('ArrowDown')
    assert.strictEqual(ltr.focused, 'shipping', 'up and down do nothing when horizontal')

    const rtl = new AccordionHarness('rtl')
    await rtl.focus('shipping')
    await rtl.press('ArrowLeft')
    assert.strictEqual(rtl.focused, 'returns', 'right to left, the left arrow moves on')
    await rtl.press('ArrowRight')
    assert.strictEqual(rtl.focused, 'shipping')

    const dir = new AccordionHarness('dir')
    await dir.focus('shipping')
    await dir.press('ArrowLeft')
    assert.strictEqual(dir.focused, 'returns', '@dir decides the same')
    await a11yAudit()
  })

  test("ember-primitives' shape: the header yields the trigger, the item yields isExpanded, and @as picks the heading level", async function (assert) {
    await render(
      <template>
        <Accordion @type="single" @collapsible={{true}} as |acc|>
          <acc.Item @value="one" as |item|>
            <item.Header @as="h2" as |header|>
              <header.Trigger>One {{if item.isExpanded "(open)"}}</header.Trigger>
            </item.Header>
            <item.Content>First.</item.Content>
          </acc.Item>
        </Accordion>
      </template>,
    )
    const faq = new AccordionHarness()
    assert.dom(faq.header('one')).hasTagName('h2')
    await faq.open('one')
    assert.strictEqual(faq.title('one'), 'One (open)')
    await a11yAudit()
  })

  test('the trigger modifier makes your own element the trigger, and the yields follow the state', async function (assert) {
    await render(
      <template>
        <Accordion @type="single" @collapsible={{true}} as |acc|>
          <acc.Item @value="one" as |item|>
            <h3><button class="mine" {{item.trigger}}>One</button></h3>
            <item.Content>First.</item.Content>
            <output>{{if item.isOpen "open" "closed"}}</output>
          </acc.Item>
          <acc.Item @value="two" as |item|>
            <item.Header as |h|><h.Trigger>Two</h.Trigger></item.Header>
            <item.Content>Second.</item.Content>
          </acc.Item>
          <p id="value">{{acc.value}}</p>
        </Accordion>
      </template>,
    )
    const faq = new AccordionHarness()
    assert.dom(faq.trigger('one')).hasClass('mine').hasAttribute('type', 'button')
    await faq.toggle('one')
    assert.true(faq.isOpen('one'))
    assert.dom('output').hasText('open')
    assert.dom('#value').hasText('one')

    await faq.focus('one')
    await faq.press('ArrowDown')
    assert.strictEqual(faq.focused, 'two', 'your own trigger takes part in the arrow keys')
    await a11yAudit()
  })

  test('nested accordions keep their keys to themselves', async function (assert) {
    await render(
      <template>
        <Accordion @type="single" @defaultValue="outer-one" @name="outer" as |acc|>
          <acc.Item @value="outer-one" as |i|>
            <i.Header as |h|><h.Trigger>Outer one</h.Trigger></i.Header>
            <i.Content>
              <Accordion @type="single" @name="inner" as |b|>
                <b.Item @value="inner-one" as |j|>
                  <j.Header as |h|><h.Trigger>Inner one</h.Trigger></j.Header>
                  <j.Content>Deep.</j.Content>
                </b.Item>
                <b.Item @value="inner-two" as |j|>
                  <j.Header as |h|><h.Trigger>Inner two</h.Trigger></j.Header>
                  <j.Content>Deeper.</j.Content>
                </b.Item>
              </Accordion>
            </i.Content>
          </acc.Item>
          <acc.Item @value="outer-two" as |i|>
            <i.Header as |h|><h.Trigger>Outer two</h.Trigger></i.Header>
            <i.Content>Second.</i.Content>
          </acc.Item>
        </Accordion>
      </template>,
    )
    const outer = new AccordionHarness('outer')
    const inner = outer.find(AccordionHarness, 'inner')
    assert.deepEqual(outer.itemValues, ['outer-one', 'outer-two'], 'its own items only')
    assert.deepEqual(inner.itemValues, ['inner-one', 'inner-two'])

    await inner.focus('inner-one')
    await inner.press('ArrowDown')
    assert.strictEqual(inner.focused, 'inner-two')
    await inner.press('ArrowDown')
    assert.strictEqual(inner.focused, 'inner-one', 'it wraps within the inner accordion')
    assert.strictEqual(outer.focused, null)
    await a11yAudit()
  })
})

function eq(a: unknown, b: unknown): boolean {
  return a === b
}
