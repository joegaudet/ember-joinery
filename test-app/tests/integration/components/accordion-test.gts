import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, rerender, settled } from '@ember/test-helpers'
import { array } from '@ember/helper'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ChevronDown, ChevronUp, Minus, Plus } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Accordion } from '@ember-joinery/ember'
import { AccordionHarness, IconHarness } from '@ember-joinery/test-support'

const MORE = [
  { value: 'billing', title: 'How does billing work?', content: 'Monthly or annually.' },
  { value: 'security', title: 'Is my data secure?', content: 'Encrypted at rest.' },
  { value: 'integrations', title: 'What integrations do you support?', content: 'Slack and more.' },
]

const ITEMS = [
  { value: 'shipping', title: 'What are your shipping options?', content: 'Standard and express.' },
  { value: 'returns', title: 'What is your return policy?', content: 'Within 30 days.' },
  { value: 'support', title: 'How can I contact support?', content: 'Email, chat or phone.' },
]

/** The paths an icon draws, to tell which icon an `<svg>` is. */
function drawn(svg: Element | null | undefined): string {
  return [...(svg?.querySelectorAll('path') ?? [])].map(p => p.getAttribute('d')).join(' ')
}

/** The paths a lucide icon draws. */
function paths(icon: unknown): string {
  const elements = (icon as [string, object, [string, { d?: string }][]])[2]
  return elements
    .filter(([tag]) => tag === 'path')
    .map(([, attributes]) => attributes.d)
    .join(' ')
}

/** Resolves on the next animation frame, after which content that opens animates. */
const nextFrame = () => new Promise(resolve => requestAnimationFrame(resolve))

/** Waits for the element's animations to finish. */
async function animated(element: Element): Promise<void> {
  await Promise.all(element.getAnimations().map(animation => animation.finished))
}

module('Integration | components | accordion', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's slots and classes on every part", async function (assert) {
    await render(
      <template>
        <Accordion @type="single" @collapsible={{true}} @defaultValue="shipping" as |accordion|>
          {{#each ITEMS as |item|}}
            <accordion.Item @value={{item.value}} as |i|>
              <i.Trigger>{{item.title}}</i.Trigger>
              <i.Content>{{item.content}}</i.Content>
            </accordion.Item>
          {{/each}}
        </Accordion>
      </template>,
    )
    const faq = new AccordionHarness()
    assert
      .dom(faq.element)
      .hasClass('jn-accordion')
      .hasAttribute('data-slot', 'accordion')
      .hasAttribute('data-orientation', 'vertical')
    assert
      .dom(faq.item('shipping'))
      .hasClass('jn-accordion-item')
      .hasAttribute('data-slot', 'accordion-item')
      .hasAttribute('data-state', 'open')
    assert.dom(faq.header('shipping')).hasTagName('h3').hasClass('jn-accordion-header')
    assert
      .dom(faq.trigger('shipping'))
      .hasTagName('button')
      .hasClass('jn-accordion-trigger')
      .hasClass('group/accordion-trigger')
      .hasAttribute('data-slot', 'accordion-trigger')
      .hasAttribute('aria-expanded', 'true')
    const icons = faq.trigger('shipping').querySelectorAll('[data-slot="accordion-trigger-icon"]')
    assert.strictEqual(icons.length, 2, 'two icons, as upstream: down while closed, up while open')
    assert.dom(icons[0]).hasClass('jn-accordion-trigger-icon')
    assert.dom(icons[1]).hasClass('jn-accordion-trigger-icon')
    assert.strictEqual(drawn(icons[0]), paths(ChevronDown), "lucide's chevron-down")
    assert.strictEqual(drawn(icons[1]), paths(ChevronUp), 'and chevron-up')

    const content = faq.content('shipping')
    assert
      .dom(content)
      .hasClass('jn-accordion-content')
      .hasAttribute('data-slot', 'accordion-content')
      .hasAttribute('role', 'region')
    assert.dom(content.firstElementChild).hasClass('jn-accordion-content-inner')
    assert.deepEqual(
      faq.titles,
      ITEMS.map(item => item.title),
    )
    assert.strictEqual(faq.text('shipping'), 'Standard and express.')
    await a11yAudit()
  })

  test('its style sheet lays it out and styles it, without Tailwind', async function (assert) {
    await render(
      <template>
        <Accordion @type="single" @defaultValue="shipping" as |accordion|>
          {{#each ITEMS as |item|}}
            <accordion.Item @value={{item.value}} @disabled={{isReturns item.value}} as |i|>
              <i.Trigger>{{item.title}}</i.Trigger>
              <i.Content>{{item.content}}</i.Content>
            </accordion.Item>
          {{/each}}
        </Accordion>
      </template>,
    )
    const faq = new AccordionHarness()
    const style = (element: Element) => getComputedStyle(element)

    assert.strictEqual(style(faq.element).display, 'flex', 'flex flex-col')
    assert.strictEqual(style(faq.element).flexDirection, 'column')
    assert.strictEqual(style(faq.item('shipping')).borderBottomWidth, '1px', 'not-last:border-b')
    assert.strictEqual(style(faq.item('support')).borderBottomWidth, '0px', 'but the last')
    assert.strictEqual(style(faq.header('shipping')).display, 'flex')
    assert.strictEqual(style(faq.header('shipping')).marginTop, '0px', 'a heading with no margin')

    const trigger = faq.trigger('shipping')
    assert.strictEqual(style(trigger).fontSize, '14px', 'text-sm')
    assert.strictEqual(style(trigger).fontWeight, '500', 'font-medium')
    assert.strictEqual(style(trigger).paddingTop, '10px', 'py-2.5')
    assert.strictEqual(style(trigger).textAlign, 'start')
    assert.strictEqual(style(trigger).flexGrow, '1', 'flex-1')
    assert.strictEqual(style(trigger).borderTopLeftRadius, '10px', 'rounded-lg')

    const [down, up] = [...trigger.querySelectorAll('svg')]
    assert.strictEqual(style(down!).width, '16px', 'the icons are size-4')
    assert.strictEqual(style(down!).display, 'none', 'open, the down chevron is hidden')
    assert.notStrictEqual(style(up!).display, 'none', 'and the up chevron shows')
    const closed = faq.trigger('support').querySelectorAll('svg')
    assert.notStrictEqual(style(closed[0]!).display, 'none', 'closed, the down chevron shows')
    assert.strictEqual(style(closed[1]!).display, 'none', 'and the up chevron is hidden')
    assert.ok(Number.parseFloat(style(up!).marginLeft) > 0, 'ms-auto pushes it to the end')
    assert.strictEqual(style(up!).marginRight, '0px')

    const content = faq.content('shipping')
    assert.strictEqual(style(content).overflow, 'hidden')
    assert.strictEqual(style(content).fontSize, '14px')
    const inner = content.firstElementChild!
    assert.strictEqual(style(inner).paddingBottom, '10px', 'pb-2.5')
    assert.strictEqual(style(inner).height, `${inner.getBoundingClientRect().height * 2}px`)

    assert.strictEqual(style(faq.trigger('returns')).opacity, '0.5', 'disabled:opacity-50')
    await a11yAudit()
  })

  test('it animates open and shut from the measured height', async function (assert) {
    await render(
      <template>
        <Accordion @type="single" @collapsible={{true}} as |accordion|>
          {{#each ITEMS as |item|}}
            <accordion.Item @value={{item.value}} as |i|>
              <i.Trigger>{{item.title}}</i.Trigger>
              <i.Content>{{item.content}}</i.Content>
            </accordion.Item>
          {{/each}}
        </Accordion>
      </template>,
    )
    const faq = new AccordionHarness()
    await nextFrame()
    await faq.open('returns')
    const content = faq.content('returns')
    assert.strictEqual(
      getComputedStyle(content).animationName,
      'accordion-down',
      'data-open:animate-accordion-down',
    )
    const height = content.style.getPropertyValue('--radix-collapsible-content-height')
    assert.ok(height.endsWith('px'), `measured: ${height}`)
    assert.strictEqual(
      getComputedStyle(content.firstElementChild!).height,
      height,
      'the inner box takes the measured height, as upstream',
    )
    await animated(content)

    faq.trigger('returns').click()
    await rerender()
    assert.strictEqual(getComputedStyle(content).animationName, 'accordion-up')
    assert.true(faq.isShown('returns'), 'shown while it animates shut')
    await settled()
    assert.false(faq.isShown('returns'), 'and hidden after')
    await a11yAudit()
  })

  test('uncontrolled and controlled, single and multiple', async function (assert) {
    class State {
      @tracked value = 'integrations'
      setValue = (value: string) => (this.value = value)
    }
    const state = new State()
    await render(
      <template>
        <Accordion @type="multiple" @defaultValue={{array "shipping"}} @name="multiple" as |a|>
          {{#each ITEMS as |item|}}
            <a.Item @value={{item.value}} as |i|>
              <i.Trigger>{{item.title}}</i.Trigger>
              <i.Content>{{item.content}}</i.Content>
            </a.Item>
          {{/each}}
        </Accordion>
        <Accordion
          @type="single"
          @value={{state.value}}
          @onValueChange={{state.setValue}}
          @name="controlled"
          as |a|
        >
          {{#each MORE as |item|}}
            <a.Item @value={{item.value}} as |i|>
              <i.Trigger>{{item.title}}</i.Trigger>
              <i.Content>{{item.content}}</i.Content>
            </a.Item>
          {{/each}}
        </Accordion>
      </template>,
    )
    const multiple = new AccordionHarness('multiple')
    await multiple.open('returns')
    assert.deepEqual(multiple.openValues, ['shipping', 'returns'])

    const controlled = new AccordionHarness('controlled')
    assert.deepEqual(controlled.openValues, ['integrations'])
    await controlled.toggle('billing')
    assert.strictEqual(state.value, 'billing')
    assert.deepEqual(controlled.openValues, ['billing'])
    state.value = 'security'
    await settled()
    assert.deepEqual(controlled.openValues, ['security'], 'it follows @value')
    await a11yAudit()
  })

  test('keyboard: the arrows, Home and End move between the triggers', async function (assert) {
    await render(
      <template>
        <Accordion @type="single" @collapsible={{true}} as |a|>
          {{#each ITEMS as |item|}}
            <a.Item @value={{item.value}} as |i|>
              <i.Trigger>{{item.title}}</i.Trigger>
              <i.Content>{{item.content}}</i.Content>
            </a.Item>
          {{/each}}
        </Accordion>
      </template>,
    )
    const faq = new AccordionHarness()
    await faq.focus('shipping')
    await faq.press('ArrowDown')
    assert.strictEqual(faq.focused, 'returns')
    await faq.press('End')
    assert.strictEqual(faq.focused, 'support')
    await faq.press('ArrowDown')
    assert.strictEqual(faq.focused, 'shipping', 'it wraps')
    await faq.press('ArrowUp')
    assert.strictEqual(faq.focused, 'support')
    await faq.press('Home')
    assert.strictEqual(faq.focused, 'shipping')
    await a11yAudit()
  })

  test('RTL: the text starts on the right and the chevron sits at the left', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Accordion @type="single" @defaultValue="item-1" as |a|>
            <a.Item @value="item-1" as |i|>
              <i.Trigger>كيف يمكنني إعادة تعيين كلمة المرور؟</i.Trigger>
              <i.Content>انقر على نسيت كلمة المرور.</i.Content>
            </a.Item>
          </Accordion>
        </DirectionProvider>
      </template>,
    )
    const faq = new AccordionHarness()
    const trigger = faq.trigger('item-1')
    assert.strictEqual(getComputedStyle(trigger).direction, 'rtl')
    const icon = [...trigger.querySelectorAll('svg')].find(
      svg => getComputedStyle(svg).display !== 'none',
    )!
    const box = trigger.getBoundingClientRect()
    assert.ok(
      icon.getBoundingClientRect().left < box.left + box.width / 2,
      'the chevron is at the left, the inline end',
    )
    assert.ok(Number.parseFloat(getComputedStyle(icon).marginRight) > 0, 'ms-auto is margin-right')
    assert.strictEqual(getComputedStyle(icon).marginLeft, '0px')
    await a11yAudit()
  })

  test('arguments: icons, the heading, @as, class, and the trigger modifier', async function (assert) {
    await render(
      <template>
        <Accordion @type="single" @collapsible={{true}} @as="section" class="mine" as |a|>
          <a.Item @value="one" class="item" as |i|>
            <i.Trigger @icon={{Plus}} @openIcon={{Minus}} @headingAs="h2" class="trigger">
              One
            </i.Trigger>
            <i.Content class="inner">First.</i.Content>
          </a.Item>
          <a.Item @value="two" as |i|>
            <h3 class="flex"><button type="button" {{i.trigger}}>Two</button></h3>
            <i.Content>Second.</i.Content>
          </a.Item>
        </Accordion>
      </template>,
    )
    const faq = new AccordionHarness()
    assert.dom(faq.element).hasTagName('section').hasClass('mine').hasClass('jn-accordion')
    assert.dom(faq.item('one')).hasClass('item').hasClass('jn-accordion-item')
    assert.dom(faq.header('one')).hasTagName('h2')
    assert.dom(faq.trigger('one')).hasClass('trigger').hasClass('jn-accordion-trigger')
    const icons = faq.trigger('one').querySelectorAll('svg')
    assert.strictEqual(drawn(icons[0]), paths(Plus), '@icon')
    assert.strictEqual(drawn(icons[1]), paths(Minus), '@openIcon')
    assert.true(new IconHarness({ within: faq.trigger('one') }).isDecorative)

    await faq.open('one')
    const inner = faq.content('one').firstElementChild
    assert.dom(inner).hasClass('inner', "class goes on the inner element, as upstream's className")
    assert.dom(faq.content('one')).doesNotHaveClass('inner')

    const own = faq.trigger('two')
    assert
      .dom(own)
      .hasClass('jn-accordion-trigger')
      .hasClass('group/accordion-trigger')
      .hasAttribute('data-slot', 'accordion-trigger')
    await faq.toggle('two')
    assert.true(faq.isOpen('two'))
    assert.false(faq.isOpen('one'), 'single: the other closed')
    assert.strictEqual(faq.text('two'), 'Second.')
    await a11yAudit()
  })
})

function isReturns(value: string): boolean {
  return value === 'returns'
}
