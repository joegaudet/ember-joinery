import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { LinkTo } from '@ember/routing'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BookOpenCheck, GitBranch, Search } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Button,
  Icon,
  Marker,
  MarkerContent,
  MarkerIcon,
  Spinner,
  asMarker,
  markerAttributes,
  markerClasses,
  type MarkerVariant,
} from '@ember-joinery/ember'
import { ButtonHarness, MarkerHarness, SpinnerHarness, tab } from '@ember-joinery/test-support'

const VARIANTS: MarkerVariant[] = ['default', 'separator', 'border']

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

module('Integration | components | marker', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and data attributes on every part', async function (assert) {
    await render(
      <template>
        <Marker @name="branch" as |m|>
          <m.Icon><Icon @icon={{GitBranch}} /></m.Icon>
          <m.Content>Switched to a new branch</m.Content>
        </Marker>
      </template>,
    )
    const marker = new MarkerHarness('branch')
    assert
      .dom(marker.element)
      .hasTagName('div')
      .hasClass('jn-marker')
      .hasClass('group/marker', 'the marker its content looks for')
      .hasClass('jn-marker-variant-default')
      .hasAttribute('data-slot', 'marker')
      .hasAttribute('data-variant', 'default', "upstream's default")
      .doesNotHaveAttribute('role', 'presentational unless you give it a role')
    assert
      .dom(marker.icon)
      .hasTagName('span')
      .hasClass('jn-marker-icon')
      .hasAttribute('data-slot', 'marker-icon')
      .hasAttribute('aria-hidden', 'true', 'decoration: the content carries the meaning')
    assert
      .dom(marker.content)
      .hasTagName('span')
      .hasClass('jn-marker-content')
      .hasAttribute('data-slot', 'marker-content')
    assert.strictEqual(marker.text, 'Switched to a new branch')
    assert.strictEqual(marker.label, 'Switched to a new branch')
    assert.strictEqual(marker.variant, 'default')
    assert.true(marker.hasIcon)
    assert.false(marker.isStatus)
    assert.strictEqual(marker.role, null)
    await a11yAudit()
  })

  test('the style sheet styles it: a muted row, its icon at 16px', async function (assert) {
    await render(
      <template>
        <Marker @name="files" as |m|>
          <m.Icon><Icon @icon={{Search}} /></m.Icon>
          <m.Content>Explored 4 files</m.Content>
        </Marker>
        <p data-test-text>Body text</p>
      </template>,
    )
    const marker = new MarkerHarness('files')
    const style = getComputedStyle(marker.element)
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.alignItems, 'center')
    assert.strictEqual(style.columnGap, '8px', 'gap-2')
    assert.strictEqual(style.fontSize, '14px', 'text-sm')
    assert.strictEqual(px(style.minHeight), 16, 'min-h-4')
    assert.strictEqual(style.textAlign, 'start')
    assert.strictEqual(style.position, 'relative')
    assert.notStrictEqual(
      style.color,
      getComputedStyle(document.querySelector('[data-test-text]')!).color,
      'text-muted-foreground',
    )
    const icon = getComputedStyle(marker.icon)
    assert.strictEqual(px(icon.width), 16, 'size-4')
    assert.strictEqual(icon.flexShrink, '0')
    assert.strictEqual(getComputedStyle(marker.icon.querySelector('svg')!).width, '16px')
    assert.strictEqual(getComputedStyle(marker.content).overflowWrap, 'break-word')
    await a11yAudit()
  })

  test('every variant renders its classes, and the style sheet draws its lines', async function (assert) {
    await render(
      <template>
        <div style="width: 384px">
          {{#each VARIANTS as |variant|}}
            <Marker @variant={{variant}} @name={{variant}} as |m|>
              <m.Content>A {{variant}} marker</m.Content>
            </Marker>
          {{/each}}
        </div>
      </template>,
    )
    for (const variant of VARIANTS) {
      const marker = new MarkerHarness(variant)
      assert.strictEqual(marker.variant, variant)
      assert.dom(marker.element).hasClass(`jn-marker-variant-${variant}`)
    }
    const separator = new MarkerHarness('separator')
    for (const pseudo of ['::before', '::after']) {
      const line = getComputedStyle(separator.element, pseudo)
      assert.strictEqual(line.height, '1px', `${pseudo}: h-px`)
      assert.strictEqual(line.flexGrow, '1', `${pseudo}: flex-1`)
      assert.notStrictEqual(line.backgroundColor, 'rgba(0, 0, 0, 0)', `${pseudo}: bg-border`)
    }
    assert.strictEqual(getComputedStyle(separator.element, '::before').marginInlineEnd, '4px')
    assert.strictEqual(getComputedStyle(separator.element, '::after').marginInlineStart, '4px')
    const label = getComputedStyle(separator.content)
    assert.strictEqual(label.flexGrow, '0', 'group-data-[variant=separator]/marker:flex-none')
    assert.strictEqual(label.textAlign, 'center')
    const box = separator.element.getBoundingClientRect()
    const text = separator.content.getBoundingClientRect()
    assert.ok(
      Math.abs(text.left - box.left - (box.right - text.right)) <= 1,
      'the label in the middle',
    )

    const border = getComputedStyle(new MarkerHarness('border').element)
    assert.strictEqual(border.borderBottomWidth, '1px', 'border-b')
    assert.strictEqual(border.paddingBottom, '8px', 'pb-2')
    assert.strictEqual(
      getComputedStyle(new MarkerHarness('default').element).borderBottomWidth,
      '0px',
    )
    assert.strictEqual(
      getComputedStyle(new MarkerHarness('default').element, '::before').content,
      'none',
      'no lines on a default marker',
    )
    await a11yAudit()
  })

  test('a status marker: your role, with a spinner in its icon', async function (assert) {
    await render(
      <template>
        <Marker role="status" @name="thinking" as |m|>
          <m.Icon><Spinner /></m.Icon>
          <m.Content>Compacting conversation</m.Content>
        </Marker>
      </template>,
    )
    const marker = new MarkerHarness('thinking')
    assert.true(marker.isStatus)
    assert.strictEqual(marker.role, 'status')
    assert.strictEqual(marker.text, 'Compacting conversation')
    assert.strictEqual(marker.find(SpinnerHarness).label, 'Loading')
    assert.strictEqual(
      getComputedStyle(marker.icon.querySelector('svg')!).width,
      '16px',
      'the spinner keeps its own size: its jn-size-4 marker leaves it alone',
    )
    await a11yAudit()
  })

  test('@as="a" makes it a link, underlined, in the tab order', async function (assert) {
    await render(
      <template>
        <Button @name="before">Before</Button>
        <Marker @as="a" href="#links-and-buttons" @name="pull" as |m|>
          <m.Icon><Icon @icon={{GitBranch}} /></m.Icon>
          <m.Content>View the pull request</m.Content>
        </Marker>
      </template>,
    )
    const marker = new MarkerHarness('pull')
    assert.dom(marker.element).hasTagName('a').hasAttribute('href', '#links-and-buttons')
    assert.true(marker.isLink)
    assert.strictEqual(marker.href, '#links-and-buttons')
    const style = getComputedStyle(marker.element)
    assert.strictEqual(style.textDecorationLine, 'underline', '[a]:underline')
    assert.strictEqual(style.textUnderlineOffset, '3px', '[a]:underline-offset-3')

    await new ButtonHarness('before').focus()
    await tab()
    assert.true(marker.isFocused, 'Tab reaches it')
    await a11yAudit()
  })

  test('@as="button": a native button, which Enter and Space press', async function (assert) {
    let clicks = 0
    const revert = () => clicks++
    await render(
      <template>
        <Marker @as="button" type="button" @name="revert" {{on "click" revert}} as |m|>
          <m.Icon><Icon @icon={{GitBranch}} /></m.Icon>
          <m.Content>Revert this change</m.Content>
        </Marker>
      </template>,
    )
    const marker = new MarkerHarness('revert')
    assert.true(marker.isButton)
    assert.false(marker.isLink)
    assert.strictEqual(marker.href, null)
    assert.strictEqual(marker.element.tabIndex, 0, 'in the tab order')
    assert.strictEqual(
      getComputedStyle(marker.element).width,
      getComputedStyle(marker.element.parentElement!).width,
      'w-full',
    )
    await marker.focus()
    assert.true(marker.isFocused)
    await marker.click()
    assert.strictEqual(clicks, 1)
    await a11yAudit()
  })

  test('the asMarker modifier makes any element a marker, and follows its arguments', async function (assert) {
    class State {
      @tracked variant: MarkerVariant = 'default'
    }
    const state = new State()
    ;(this.owner as unknown as { setupRouter(): void }).setupRouter()
    await render(
      <template>
        <LinkTo @route="index" class="mine" {{asMarker variant=state.variant name="home"}}>
          <MarkerIcon><Icon @icon={{BookOpenCheck}} /></MarkerIcon>
          <MarkerContent>Open the docs</MarkerContent>
        </LinkTo>
      </template>,
    )
    const home = new MarkerHarness('home')
    assert.dom(home.element).hasTagName('a').hasAttribute('href', '/').hasClass('mine')
    assert.dom(home.element).hasClass('jn-marker').hasClass('jn-marker-variant-default')
    assert.strictEqual(home.text, 'Open the docs', 'the parts it exports work inside it')
    assert.true(home.hasIcon)
    assert.dom(home.icon).hasAttribute('aria-hidden', 'true')
    assert.strictEqual(getComputedStyle(home.element).display, 'flex')

    state.variant = 'border'
    await settled()
    assert.strictEqual(home.variant, 'border', 'the attributes follow')
    assert.dom(home.element).hasClass('jn-marker-variant-border')
    await a11yAudit()
  })

  test('the component and the modifier render the same classes and attributes', async function (assert) {
    await render(
      <template>
        {{#each VARIANTS as |variant|}}
          <Marker @variant={{variant}} @name="x" data-case="component" />
          <div data-case="modifier" {{asMarker variant=variant name="x"}}></div>
        {{/each}}
        <span {{asMarker}} data-case="bare"></span>
      </template>,
    )
    const components = [...document.querySelectorAll('[data-case="component"]')]
    const modifiers = [...document.querySelectorAll('[data-case="modifier"]')]
    assert.strictEqual(components.length, VARIANTS.length)
    components.forEach((component, index) => {
      assert.deepEqual(rendering(component), rendering(modifiers[index]!), `${index}: the same`)
    })
    assert.deepEqual(rendering(components[0]!).classes, markerClasses().split(' ').sort())
    for (const [name, value] of Object.entries(markerAttributes({ name: 'x' }))) {
      assert.strictEqual(components[0]!.getAttribute(name), value ?? null, name)
    }
    assert
      .dom('[data-case="bare"]')
      .hasAttribute('data-variant', 'default')
      .doesNotHaveAttribute('data-test-jn-name')
    await a11yAudit()
  })

  test('parts take @as, and their modifiers make your own element the part', async function (assert) {
    await render(
      <template>
        <Marker @name="own" class="flex-col" as |m|>
          <i {{m.icon}}><Icon @icon={{BookOpenCheck}} /></i>
          <m.Content @as="strong">Syncing completed</m.Content>
        </Marker>
      </template>,
    )
    const own = new MarkerHarness('own')
    assert
      .dom(own.icon)
      .hasTagName('i')
      .hasClass('jn-marker-icon')
      .hasAttribute('aria-hidden', 'true')
      .hasAttribute('data-slot', 'marker-icon')
    assert.dom(own.content).hasTagName('strong').hasClass('jn-marker-content')
    assert.dom(own.element).hasClass('flex-col', 'your class adds to its own')
    await a11yAudit()
  })

  test('RTL: the icon comes first on the right, and a separator keeps its label centred', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div style="width: 384px">
            <Marker @name="rtl" as |m|>
              <m.Icon><Icon @icon={{GitBranch}} /></m.Icon>
              <m.Content>تم التبديل إلى فرع جديد</m.Content>
            </Marker>
            <Marker @variant="separator" @name="rtl-separator" as |m|>
              <m.Content>اليوم</m.Content>
            </Marker>
          </div>
        </DirectionProvider>
      </template>,
    )
    const marker = new MarkerHarness('rtl')
    assert.ok(
      marker.icon.getBoundingClientRect().left > marker.content.getBoundingClientRect().left,
      'the icon on the right, the content to its left',
    )
    assert.strictEqual(
      Math.round(marker.icon.getBoundingClientRect().right),
      Math.round(marker.element.getBoundingClientRect().right),
      'text-start: from the right',
    )
    const separator = new MarkerHarness('rtl-separator')
    assert.strictEqual(
      getComputedStyle(separator.element, '::before').marginRight,
      '0px',
      'me-1 is on the left in RTL',
    )
    assert.strictEqual(getComputedStyle(separator.element, '::before').marginLeft, '4px')
    await a11yAudit()
  })

  test('the harness throws for a missing part, and reads an aria-label as its name', async function (assert) {
    await render(
      <template>
        {{! A div without a role can't be named, so an icon-only marker takes one that can. }}
        <Marker role="img" aria-label="Synced" @name="synced" as |m|>
          <m.Icon><Icon @icon={{BookOpenCheck}} /></m.Icon>
        </Marker>
        <Marker @name="plain" as |m|><m.Content>Plain</m.Content></Marker>
      </template>,
    )
    const synced = new MarkerHarness('synced')
    assert.strictEqual(synced.label, 'Synced')
    assert.strictEqual(synced.text, '')
    assert.throws(() => synced.content, /no "content" part found in marker "synced"/)
    const plain = new MarkerHarness('plain')
    assert.false(plain.hasIcon)
    assert.throws(() => plain.icon, /no "icon" part found/)
    await a11yAudit()
  })
})
