import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, focus, render, rerender, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Collapsible } from '@ember-joinery/primitives/collapsible'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { CollapsibleHarness, tab, tabOrder } from '@ember-joinery/test-support'

/** An exit animation keyed off data-state, as shadcn's styles key theirs. */
const Animations = <template>
  <style>
    @keyframes test-collapse {
      from {
        height: var(--radix-collapsible-content-height);
      }
      to {
        height: 0;
      }
    }
    .collapsing {
      overflow: hidden;
    }
    .collapsing[data-state="closed"] {
      animation: test-collapse 150ms;
    }
  </style>
</template>

const wait = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

module('Integration | primitives | collapsible', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a trigger that controls its content, closed to start', async function (assert) {
    await render(
      <template>
        <Collapsible @name="faq" as |c|>
          <c.Trigger>Can I use this in my project?</c.Trigger>
          <c.Content>Yes. Free to use for personal and commercial projects.</c.Content>
        </Collapsible>
      </template>,
    )
    const faq = new CollapsibleHarness('faq')

    assert.dom(faq.element).hasTagName('div').hasAttribute('data-state', 'closed')
    assert.dom(faq.element).doesNotHaveAttribute('data-disabled')
    assert.dom(faq.trigger).hasTagName('button').hasAttribute('type', 'button')
    assert
      .dom(faq.trigger)
      .hasAttribute('aria-expanded', 'false')
      .hasAttribute('data-state', 'closed')
    assert.false(faq.isOpen)
    assert.false(faq.isShown)
    assert.false(faq.isDisabled)
    assert.strictEqual(faq.label, 'Can I use this in my project?')

    const content = faq.content!
    assert.ok(content, "the content's element is there while closed, as Radix's")
    assert.true(faq.controlsContent, "the trigger's aria-controls names it")
    assert.dom(content).hasAttribute('hidden').hasAttribute('data-state', 'closed').hasText('')
    assert.strictEqual(faq.text, '', 'and empty')
    await a11yAudit()
  })

  test('uncontrolled: the trigger opens and closes it, and @defaultOpen starts it open', async function (assert) {
    const changes: boolean[] = []
    const heard = (open: boolean) => changes.push(open)
    await render(
      <template>
        <Collapsible @name="closed" @onOpenChange={{heard}} as |c|>
          <c.Trigger>Details</c.Trigger>
          <c.Content><p>The details.</p></c.Content>
        </Collapsible>
        <Collapsible @name="open" @defaultOpen={{true}} as |c|>
          <c.Trigger>More</c.Trigger>
          <c.Content>More details.</c.Content>
        </Collapsible>
      </template>,
    )
    const closed = new CollapsibleHarness('closed')
    await closed.toggle()
    assert.true(closed.isOpen)
    assert.true(closed.isShown)
    assert.strictEqual(closed.text, 'The details.')
    assert.dom(closed.element).hasAttribute('data-state', 'open')
    assert.dom(closed.content).hasAttribute('data-state', 'open').doesNotHaveAttribute('hidden')

    await closed.close()
    assert.false(closed.isOpen)
    assert.false(closed.isShown)
    assert.dom(closed.content).hasAttribute('hidden').hasText('')
    assert.deepEqual(changes, [true, false], '@onOpenChange hears each change')

    const open = new CollapsibleHarness('open')
    assert.true(open.isOpen, '@defaultOpen')
    assert.strictEqual(open.text, 'More details.')
    await open.toggle()
    assert.false(open.isOpen)
    await a11yAudit()
  })

  test('controlled: @open is the state, and @onOpenChange asks to change it', async function (assert) {
    class State {
      @tracked open = false
      asked: boolean[] = []
      onOpenChange = (open: boolean) => this.asked.push(open)
    }
    const state = new State()
    await render(
      <template>
        <Collapsible @open={{state.open}} @onOpenChange={{state.onOpenChange}} as |c|>
          <c.Trigger>Details</c.Trigger>
          <c.Content>The details.</c.Content>
        </Collapsible>
      </template>,
    )
    const details = new CollapsibleHarness()
    await details.toggle()
    assert.deepEqual(state.asked, [true], 'it asks to open')
    assert.false(details.isOpen, 'but stays as the caller has it')

    state.open = true
    await settled()
    assert.true(details.isOpen, 'and follows @open')
    assert.strictEqual(details.text, 'The details.')

    await details.toggle()
    assert.deepEqual(state.asked, [true, false])
    assert.true(details.isOpen)
    await a11yAudit()
  })

  test('@disabled: the trigger is disabled, every part says so, and clicks do nothing', async function (assert) {
    await render(
      <template>
        <Collapsible @disabled={{true}} as |c|>
          <c.Trigger>Details</c.Trigger>
          <c.Content>The details.</c.Content>
        </Collapsible>
      </template>,
    )
    const details = new CollapsibleHarness()
    assert.true(details.isDisabled)
    assert.dom(details.trigger).hasAttribute('disabled').hasAttribute('data-disabled', '')
    assert.dom(details.element).hasAttribute('data-disabled', '')
    assert.dom(details.content).hasAttribute('data-disabled', '')

    await details.toggle().catch(() => undefined)
    assert.false(details.isOpen)
    await a11yAudit()
  })

  test('the trigger modifier makes your own element the trigger', async function (assert) {
    await render(
      <template>
        <form>
          <Collapsible @name="button" as |c|>
            <button class="mine" {{c.trigger}}>Toggle</button>
            <c.Content>Shown.</c.Content>
          </Collapsible>
          <Collapsible @name="submit" as |c|>
            <button type="submit" {{c.trigger}}>Send</button>
            <c.Content>Sent.</c.Content>
          </Collapsible>
        </form>
      </template>,
    )
    const mine = new CollapsibleHarness('button')
    assert.dom(mine.trigger).hasClass('mine').hasAttribute('aria-expanded', 'false')
    assert.dom(mine.trigger).hasAttribute('type', 'button', 'a button without a type never submits')
    assert.true(mine.controlsContent)
    await mine.toggle()
    assert.true(mine.isOpen)
    assert.strictEqual(mine.text, 'Shown.')

    const submit = new CollapsibleHarness('submit')
    assert.dom(submit.trigger).hasAttribute('type', 'submit', 'its own type stays')
    await a11yAudit()
  })

  test('@as renders other tags, and attributes go on each part', async function (assert) {
    await render(
      <template>
        <Collapsible @as="section" class="root" aria-label="Order" as |c|>
          <c.Trigger class="trigger">Order #4189</c.Trigger>
          <c.Content @as="ul" class="content"><li>Shipped</li></c.Content>
        </Collapsible>
      </template>,
    )
    const order = new CollapsibleHarness()
    assert.dom(order.element).hasTagName('section').hasClass('root')
    assert.dom(order.trigger).hasClass('trigger')
    assert.dom(order.content).hasTagName('ul').hasClass('content')
    await order.open()
    assert.strictEqual(order.text, 'Shipped')
    await a11yAudit()
  })

  test('keyboard: the trigger is a native button in the tab order; closed content is not', async function (assert) {
    await render(
      <template>
        <button id="before" type="button">Before</button>
        <Collapsible as |c|>
          <c.Trigger>Details</c.Trigger>
          <c.Content><a href="#more">More</a></c.Content>
        </Collapsible>
      </template>,
    )
    const details = new CollapsibleHarness()
    assert.ok(
      details.trigger instanceof HTMLButtonElement,
      'a native <button>: the browser opens it on Enter and Space (APG Disclosure)',
    )
    await focus('#before')
    await tab()
    assert.dom(details.trigger).isFocused('Tab reaches the trigger')
    assert.false(
      tabOrder().some(element => element.getAttribute('href') === '#more'),
      'nothing inside the closed content takes focus',
    )

    await details.toggle()
    assert.dom(details.trigger).isFocused('focus stays on the trigger')
    await tab()
    assert.dom('a[href="#more"]').isFocused('Tab goes on into the open content')
    await a11yAudit()
  })

  test('it stays shown through its exit animation, measured for it, and is hidden after', async function (assert) {
    await render(
      <template>
        <Animations />
        <Collapsible as |c|>
          <c.Trigger>Details</c.Trigger>
          <c.Content class="collapsing"><div style="height: 40px">The details.</div></c.Content>
        </Collapsible>
      </template>,
    )
    const details = new CollapsibleHarness()
    const content = details.content!
    const height = () => content.style.getPropertyValue('--radix-collapsible-content-height')
    assert.strictEqual(height(), '', 'nothing to measure while closed')

    await details.open()
    assert.strictEqual(height(), '40px', 'opened, it is measured into the height variable')
    assert.ok(
      content.style.getPropertyValue('--radix-collapsible-content-width'),
      'and its width into --radix-collapsible-content-width',
    )
    await wait(40)

    // A native click, which runs at once: the harness's (test-helpers') would also wait for
    // the exit animation, and this looks while it runs.
    details.trigger.click()
    await rerender()
    assert.false(details.isOpen, 'the trigger says closed at once')
    assert.true(details.isShown, 'while the content animates out')
    assert.strictEqual(content.textContent!.trim(), 'The details.', 'with its content')
    assert.strictEqual(height(), '40px', 'measured again as it closes, for the animation')

    await settled()
    assert.false(details.isShown, 'hidden once the animation ends')
    assert.dom(content).hasAttribute('hidden').hasText('')
    await a11yAudit()
  })

  test('content open from the start neither animates in nor is measured until it changes', async function (assert) {
    await render(
      <template>
        <style>
          @keyframes test-grow {
            from {
              height: 0;
            }
            to {
              height: 40px;
            }
          }
          .growing[data-state="open"] {
            animation: test-grow 150ms;
          }
        </style>
        <Collapsible @defaultOpen={{true}} as |c|>
          <c.Trigger>Details</c.Trigger>
          <c.Content class="growing"><div style="height: 40px">The details.</div></c.Content>
        </Collapsible>
      </template>,
    )
    const details = new CollapsibleHarness()
    const content = details.content!
    assert.true(details.isShown)
    assert.strictEqual(content.style.animationName, 'none', 'its animation is held off')
    assert.strictEqual(content.getAnimations().length, 0, 'so nothing animates in')
    assert.strictEqual(
      content.style.getPropertyValue('--radix-collapsible-content-height'),
      '',
      'and it is not measured yet, as in Radix',
    )

    await new Promise(resolve => requestAnimationFrame(resolve))
    await details.close()
    assert.strictEqual(
      content.style.getPropertyValue('--radix-collapsible-content-height'),
      '40px',
      'closing, after the first frame, measures it',
    )
    assert.strictEqual(content.style.animationName, '', 'and gives its animation back')
    await a11yAudit()
  })

  test('@forceMount keeps the content rendered and shown, for animating it yourself', async function (assert) {
    await render(
      <template>
        <Collapsible as |c|>
          <c.Trigger>Details</c.Trigger>
          <c.Content @forceMount={{true}}>Always here.</c.Content>
        </Collapsible>
      </template>,
    )
    const details = new CollapsibleHarness()
    assert.false(details.isOpen)
    assert.dom(details.content).doesNotHaveAttribute('hidden').hasText('Always here.')
    assert.dom(details.content).hasAttribute('data-state', 'closed', 'its data-state still follows')
    await details.toggle()
    assert.dom(details.content).hasAttribute('data-state', 'open')
    await a11yAudit()
  })

  test('RTL: it works the same inside a right-to-left provider', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Collapsible as |c|>
            <c.Trigger>تفاصيل</c.Trigger>
            <c.Content>التفاصيل.</c.Content>
          </Collapsible>
        </DirectionProvider>
      </template>,
    )
    const details = new CollapsibleHarness()
    assert.strictEqual(getComputedStyle(details.element).direction, 'rtl')
    await details.open()
    assert.strictEqual(details.text, 'التفاصيل.')
    await a11yAudit()
  })

  test('the yield gives isOpen and toggle, and nested collapsibles are each their own', async function (assert) {
    await render(
      <template>
        <Collapsible @name="outer" as |outer|>
          <outer.Trigger>Outer {{if outer.isOpen "open" "closed"}}</outer.Trigger>
          <button id="toggle" type="button" {{on "click" outer.toggle}}>Toggle</button>
          <outer.Content>
            <Collapsible @name="inner" as |inner|>
              <inner.Trigger>Inner</inner.Trigger>
              <inner.Content>Deep.</inner.Content>
            </Collapsible>
          </outer.Content>
        </Collapsible>
      </template>,
    )
    const outer = new CollapsibleHarness('outer')
    assert.strictEqual(outer.label, 'Outer closed')
    await click('#toggle')
    assert.strictEqual(outer.label, 'Outer open')

    const inner = outer.find(CollapsibleHarness, 'inner')
    assert.false(inner.isOpen)
    await inner.open()
    assert.strictEqual(inner.text, 'Deep.')
    assert.strictEqual(outer.trigger.textContent!.trim(), 'Outer open', 'its own trigger')
    await a11yAudit()
  })
})
