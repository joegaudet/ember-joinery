import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { focus, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ChevronsUpDown } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, Collapsible, FieldGroup, Icon } from '@ember-joinery/ember'
import { ButtonHarness, CollapsibleHarness, tab } from '@ember-joinery/test-support'

module('Integration | components | collapsible', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's slots, and no styles of its own", async function (assert) {
    await render(
      <template>
        <Collapsible @name="faq" as |c|>
          <c.Trigger>Can I use this in my project?</c.Trigger>
          <c.Content>Yes. Free to use for personal and commercial projects.</c.Content>
        </Collapsible>
      </template>,
    )
    const faq = new CollapsibleHarness('faq')
    assert
      .dom(faq.element)
      .hasAttribute('data-slot', 'collapsible')
      .hasAttribute('data-state', 'closed')
    assert.dom(faq.trigger).hasTagName('button').hasAttribute('data-slot', 'collapsible-trigger')
    assert.dom(faq.trigger).hasAttribute('type', 'button').hasAttribute('aria-expanded', 'false')
    assert.dom(faq.content).hasAttribute('data-slot', 'collapsible-content').hasAttribute('hidden')
    assert.true(faq.controlsContent)
    // Before 7.1, Ember gives the root `ember-view` too; rendering() leaves that out.
    assert.deepEqual(rendering(faq.element).classes, [], 'upstream gives it no classes')

    await faq.open()
    assert.strictEqual(faq.text, 'Yes. Free to use for personal and commercial projects.')
    assert.dom(faq.element).hasAttribute('data-state', 'open')
    const styles = getComputedStyle(faq.content!)
    assert.strictEqual(styles.display, 'block')
    assert.strictEqual(
      styles.paddingTop,
      '0px',
      "it adds no spacing: the caller's classes lay it out",
    )
    await a11yAudit()
  })

  test('closed content stays hidden whatever display it is given, as under preflight', async function (assert) {
    // Upstream's examples lay the content out with classes (`flex`, `p-2.5`), which Tailwind's
    // preflight keeps from showing a `hidden` element; Joinery's base does the same for its parts.
    await render(
      <template>
        <Collapsible @name="details" as |c|>
          <c.Trigger>Product details</c.Trigger>
          <c.Content style="display: flex; padding: 10px">More about it.</c.Content>
        </Collapsible>
      </template>,
    )
    const details = new CollapsibleHarness('details')
    assert.dom(details.content).hasAttribute('hidden')
    assert.strictEqual(getComputedStyle(details.content!).display, 'none')
    assert.strictEqual(details.content!.offsetHeight, 0, 'it takes no space')
    assert.false(details.isShown)

    await details.open()
    assert.true(details.isShown)
    assert.strictEqual(getComputedStyle(details.content!).display, 'flex', 'the given display')

    await details.close()
    assert.false(details.isShown, 'hidden again')
    await a11yAudit()
  })

  test('a Button becomes the trigger with the yielded modifier, as upstream asChild', async function (assert) {
    await render(
      <template>
        <form>
          <Collapsible @name="order" as |c|>
            <h4>Order #4189</h4>
            <Button @variant="ghost" @size="icon" @name="toggle" {{c.trigger}}>
              <Icon @icon={{ChevronsUpDown}} />
              <span class="sr-only">Toggle details</span>
            </Button>
            <c.Content>
              <p>Shipping address</p>
            </c.Content>
          </Collapsible>
        </form>
      </template>,
    )
    const order = new CollapsibleHarness('order')
    const toggle = new ButtonHarness('toggle')
    assert.strictEqual(order.trigger, toggle.element, 'the Button is the trigger')
    assert.strictEqual(toggle.variant, 'ghost', 'and still a ghost button')
    assert
      .dom(toggle.element)
      .hasClass('jn-button')
      .hasAttribute('data-slot', 'collapsible-trigger', "upstream's Slot puts its data-slot on it")
      .hasAttribute('type', 'button', 'so it never submits the form')
      .hasAttribute('aria-expanded', 'false')
    assert.strictEqual(toggle.label, 'Toggle details')

    await toggle.click()
    assert.true(order.isOpen)
    assert.strictEqual(order.text, 'Shipping address')
    assert.dom(toggle.element).hasAttribute('data-state', 'open')
    await a11yAudit()
  })

  test('controlled and uncontrolled, and disabled', async function (assert) {
    class State {
      @tracked open = false
      setOpen = (open: boolean) => (this.open = open)
    }
    const state = new State()
    await render(
      <template>
        <Collapsible @open={{state.open}} @onOpenChange={{state.setOpen}} @name="controlled" as |c|>
          <c.Trigger>Controlled</c.Trigger>
          <c.Content>Controlled content.</c.Content>
        </Collapsible>
        <Collapsible @defaultOpen={{true}} @name="uncontrolled" as |c|>
          <c.Trigger>Uncontrolled</c.Trigger>
          <c.Content>Uncontrolled content.</c.Content>
        </Collapsible>
        <Collapsible @disabled={{true}} @name="disabled" as |c|>
          <c.Trigger>Disabled</c.Trigger>
          <c.Content>Disabled content.</c.Content>
        </Collapsible>
      </template>,
    )
    const controlled = new CollapsibleHarness('controlled')
    await controlled.open()
    assert.true(state.open, '@onOpenChange heard it')
    assert.true(controlled.isOpen)
    state.open = false
    await settled()
    assert.false(controlled.isOpen, 'it follows @open')

    const uncontrolled = new CollapsibleHarness('uncontrolled')
    assert.true(uncontrolled.isOpen, '@defaultOpen')
    await uncontrolled.close()
    assert.false(uncontrolled.isShown)

    const disabled = new CollapsibleHarness('disabled')
    assert.true(disabled.isDisabled)
    assert.dom(disabled.element).hasAttribute('data-disabled', '')
    await disabled.toggle().catch(() => undefined)
    assert.false(disabled.isOpen)
    await a11yAudit()
  })

  test('keyboard: Tab reaches the trigger, and the open content after it', async function (assert) {
    await render(
      <template>
        <button id="before" type="button">Before</button>
        <Collapsible @defaultOpen={{true}} as |c|>
          <c.Trigger>Details</c.Trigger>
          <c.Content><a href="#more">More</a></c.Content>
        </Collapsible>
      </template>,
    )
    const details = new CollapsibleHarness()
    await focus('#before')
    await tab()
    assert.dom(details.trigger).isFocused()
    await tab()
    assert.dom('a[href="#more"]').isFocused()
    await details.close()
    assert.dom(details.trigger).isFocused('closing moves focus nowhere else')
    await a11yAudit()
  })

  test('the harness finds content inside another component through aria-controls', async function (assert) {
    // Upstream's settings panel puts its CollapsibleContent inside a FieldGroup, whose root is
    // the content's nearest component root, so the part lookup alone can't reach it.
    await render(
      <template>
        <Collapsible @name="settings" as |c|>
          <FieldGroup>
            <c.Content>Two more radii</c.Content>
          </FieldGroup>
          <c.Trigger>More</c.Trigger>
        </Collapsible>
      </template>,
    )
    const settings = new CollapsibleHarness('settings')
    assert.dom(settings.content).hasAttribute('data-slot', 'collapsible-content')
    assert.true(settings.controlsContent)
    assert.false(settings.isShown)
    assert.strictEqual(settings.text, '')

    await settings.open()
    assert.true(settings.isShown)
    assert.strictEqual(settings.text, 'Two more radii')
    await a11yAudit()
  })

  test('RTL: it lays out right to left inside a provider', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Collapsible class="flex" as |c|>
            <span id="title">الطلب #4189</span>
            <c.Trigger id="trigger">تبديل</c.Trigger>
            <c.Content>عنوان الشحن</c.Content>
          </Collapsible>
        </DirectionProvider>
      </template>,
    )
    const details = new CollapsibleHarness()
    const title = document.getElementById('title')!.getBoundingClientRect()
    const trigger = details.trigger.getBoundingClientRect()
    assert.ok(trigger.left < title.left, 'the second item sits to the left of the first')
    await details.open()
    assert.strictEqual(details.text, 'عنوان الشحن')
    await a11yAudit()
  })
})
