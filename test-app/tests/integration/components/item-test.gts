import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { LinkTo } from '@ember/routing'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Inbox } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Button,
  Icon,
  Item,
  ItemContent,
  ItemGroup,
  ItemMedia,
  ItemTitle,
  asItem,
  itemAttributes,
  itemClasses,
  type ItemSize,
  type ItemVariant,
} from '@ember-joinery/ember'
import { ButtonHarness, ItemGroupHarness, ItemHarness, tab } from '@ember-joinery/test-support'

const VARIANTS: ItemVariant[] = ['default', 'outline', 'muted']
const SIZES: ItemSize[] = ['default', 'sm', 'xs']

// A 1×1 grey PNG, so an image renders without the network.
const IMAGE =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR4nGNgAAAAAgABSK+kcQAAAABJRU5ErkJggg=='

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

/** An element's classes and attributes (but the test's own `data-case`), to compare two. */
function rendering(element: Element): { classes: string[]; attributes: Record<string, string> } {
  const attributes: Record<string, string> = {}
  for (const { name, value } of element.attributes) {
    if (name !== 'class' && name !== 'data-case') attributes[name] = value
  }
  return { classes: [...element.classList].sort(), attributes }
}

module('Integration | components | item', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and data attributes on every part', async function (assert) {
    await render(
      <template>
        <Item as |i|>
          <i.Header>Header</i.Header>
          <i.Media @variant="icon"><Icon @icon={{Inbox}} /></i.Media>
          <i.Content>
            <i.Title>Title</i.Title>
            <i.Description>Description</i.Description>
          </i.Content>
          <i.Actions><Button>Action</Button></i.Actions>
          <i.Footer>Footer</i.Footer>
        </Item>
      </template>,
    )
    const item = new ItemHarness()
    assert
      .dom(item.element)
      .hasTagName('div')
      .hasClass('jn-item')
      .hasClass('group/item', 'the marker its parts look for')
      .hasClass('jn-item-variant-default')
      .hasClass('jn-item-size-default')
      .hasAttribute('data-slot', 'item')
      .hasAttribute('data-variant', 'default')
      .hasAttribute('data-size', 'default')
    assert
      .dom(item.media)
      .hasClass('jn-item-media')
      .hasClass('jn-item-media-variant-icon')
      .hasAttribute('data-slot', 'item-media')
      .hasAttribute('data-variant', 'icon')
    assert.dom(item.content).hasClass('jn-item-content').hasAttribute('data-slot', 'item-content')
    assert.dom(item.part('title')).hasClass('jn-item-title').hasAttribute('data-slot', 'item-title')
    assert
      .dom(item.part('description'))
      .hasTagName('p', "upstream's description is a p")
      .hasClass('jn-item-description')
      .hasAttribute('data-slot', 'item-description')
    assert.dom(item.actions).hasClass('jn-item-actions').hasAttribute('data-slot', 'item-actions')
    assert.dom(item.header).hasClass('jn-item-header').hasAttribute('data-slot', 'item-header')
    assert.dom(item.footer).hasClass('jn-item-footer').hasAttribute('data-slot', 'item-footer')
    assert.strictEqual(item.title, 'Title')
    assert.strictEqual(item.description, 'Description')
    assert.strictEqual(item.mediaVariant, 'icon')
    assert.strictEqual(item.find(ButtonHarness).label, 'Action')
    await a11yAudit()
  })

  test('every variant and size renders its classes, and the style sheet styles each', async function (assert) {
    await render(
      <template>
        {{#each VARIANTS as |variant|}}
          <Item @variant={{variant}} @name={{variant}} as |i|>
            <i.Content><i.Title>{{variant}}</i.Title></i.Content>
          </Item>
        {{/each}}
        {{#each SIZES as |size|}}
          <Item @size={{size}} @name="size-{{size}}" as |i|>
            <i.Media @variant="icon"><Icon @icon={{Inbox}} /></i.Media>
            <i.Content>
              <i.Title>{{size}}</i.Title>
              <i.Description>Description</i.Description>
            </i.Content>
          </Item>
        {{/each}}
      </template>,
    )
    for (const variant of VARIANTS) {
      const item = new ItemHarness(variant)
      assert.strictEqual(item.variant, variant)
      assert.dom(item.element).hasClass(`jn-item-variant-${variant}`)
    }
    const style = (name: string) => getComputedStyle(new ItemHarness(name).element)
    assert.strictEqual(style('default').borderTopWidth, '1px', 'a border, transparent')
    assert.strictEqual(style('default').borderTopColor, 'rgba(0, 0, 0, 0)')
    assert.notStrictEqual(style('outline').borderTopColor, 'rgba(0, 0, 0, 0)', 'border-border')
    assert.notStrictEqual(style('muted').backgroundColor, 'rgba(0, 0, 0, 0)', 'bg-muted/50')
    assert.strictEqual(style('default').borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(style('default').display, 'flex')
    assert.strictEqual(style('default').flexWrap, 'wrap')

    for (const size of SIZES) {
      const item = new ItemHarness(`size-${size}`)
      assert.strictEqual(item.size, size)
      assert.dom(item.element).hasClass(`jn-item-size-${size}`)
    }
    assert.strictEqual(style('size-default').paddingLeft, '12px', 'px-3')
    assert.strictEqual(style('size-default').paddingTop, '10px', 'py-2.5')
    assert.strictEqual(style('size-sm').paddingTop, '10px')
    assert.strictEqual(style('size-xs').paddingLeft, '10px', 'px-2.5')
    assert.strictEqual(style('size-xs').paddingTop, '8px', 'py-2')
    assert.strictEqual(style('size-default').columnGap, '10px', 'gap-2.5')
    assert.strictEqual(style('size-xs').columnGap, '8px', 'gap-2')

    const xs = new ItemHarness('size-xs')
    assert.strictEqual(getComputedStyle(xs.part('description')).fontSize, '12px', 'text-xs')
    assert.strictEqual(getComputedStyle(xs.content).rowGap, '0px', 'gap-0 in xs')
    const normal = new ItemHarness('size-default')
    assert.strictEqual(getComputedStyle(normal.part('description')).fontSize, '14px')
    assert.strictEqual(getComputedStyle(normal.content).rowGap, '4px', 'gap-1')
    assert.strictEqual(getComputedStyle(normal.part('title')).fontWeight, '500', 'font-medium')
    await a11yAudit()
  })

  test('media: an icon at 16px, an image cropped to its size, and aligned with a description', async function (assert) {
    await render(
      <template>
        {{#each SIZES as |size|}}
          <Item @size={{size}} @name={{size}} as |i|>
            <i.Media @variant="image"><img src={{IMAGE}} alt="Cover" /></i.Media>
            <i.Content><i.Title>{{size}}</i.Title></i.Content>
          </Item>
        {{/each}}
        <Item @name="icon" as |i|>
          <i.Media @variant="icon"><Icon @icon={{Inbox}} /></i.Media>
          <i.Content>
            <i.Title>Inbox</i.Title>
            <i.Description>Two lines of text</i.Description>
          </i.Content>
        </Item>
      </template>,
    )
    const expected = { default: 40, sm: 32, xs: 24 }
    for (const size of SIZES) {
      const media = new ItemHarness(size).media
      assert.strictEqual(px(getComputedStyle(media).width), expected[size], `${size}: the image`)
      const img = getComputedStyle(media.querySelector('img')!)
      assert.strictEqual(img.objectFit, 'cover')
      assert.strictEqual(px(img.width), expected[size], 'size-full')
    }
    const icon = new ItemHarness('icon')
    assert.strictEqual(icon.mediaVariant, 'icon')
    assert.strictEqual(getComputedStyle(icon.media.querySelector('svg')!).width, '16px', 'size-4')
    assert.strictEqual(
      getComputedStyle(icon.media).alignSelf,
      'flex-start',
      'beside a description, it sits at the top',
    )
    await a11yAudit()
  })

  test('@as="a" makes it a link, in the tab order, with the link styles', async function (assert) {
    await render(
      <template>
        <Button @name="before">Before</Button>
        <Item @as="a" href="#dashboard" @variant="outline" @name="link" as |i|>
          <i.Content><i.Title>Dashboard</i.Title></i.Content>
        </Item>
      </template>,
    )
    const item = new ItemHarness('link')
    assert.dom(item.element).hasTagName('a').hasAttribute('href', '#dashboard')
    assert.true(item.isLink)
    assert.strictEqual(item.href, '#dashboard')
    const style = getComputedStyle(item.element)
    assert.strictEqual(style.textDecorationLine, 'none', 'no underline')
    assert.ok(style.transitionProperty.includes('color'), '[a]:transition-colors')

    await new ButtonHarness('before').focus()
    await tab()
    assert.true(item.isFocused, 'Tab reaches it')
    await a11yAudit()
  })

  test('the asItem modifier makes any element an item, and follows its arguments', async function (assert) {
    class State {
      @tracked variant: ItemVariant = 'default'
    }
    const state = new State()
    ;(this.owner as unknown as { setupRouter(): void }).setupRouter()
    await render(
      <template>
        <LinkTo @route="index" class="mine" {{asItem variant=state.variant size="sm" name="home"}}>
          <ItemMedia @variant="icon"><Icon @icon={{Inbox}} /></ItemMedia>
          <ItemContent><ItemTitle>Home</ItemTitle></ItemContent>
        </LinkTo>
      </template>,
    )
    const home = new ItemHarness('home')
    assert.dom(home.element).hasTagName('a').hasAttribute('href', '/').hasClass('mine')
    assert.dom(home.element).hasClass('jn-item').hasClass('jn-item-size-sm')
    assert.strictEqual(home.title, 'Home', 'the parts it exports work inside it')
    assert.strictEqual(home.mediaVariant, 'icon')
    assert.strictEqual(getComputedStyle(home.element).display, 'flex')

    state.variant = 'outline'
    await settled()
    assert.strictEqual(home.variant, 'outline', 'the attributes follow')
    assert.dom(home.element).hasClass('jn-item-variant-outline')
    await a11yAudit()
  })

  test('the component and the modifier render the same classes and attributes', async function (assert) {
    const cases = VARIANTS.flatMap(variant => SIZES.map(size => ({ variant, size })))
    await render(
      <template>
        {{#each cases as |c|}}
          <Item @variant={{c.variant}} @size={{c.size}} @name="x" data-case="component" />
          <div data-case="modifier" {{asItem variant=c.variant size=c.size name="x"}}></div>
        {{/each}}
      </template>,
    )
    const components = [...document.querySelectorAll('[data-case="component"]')]
    const modifiers = [...document.querySelectorAll('[data-case="modifier"]')]
    assert.strictEqual(components.length, cases.length)
    components.forEach((component, index) => {
      assert.deepEqual(rendering(component), rendering(modifiers[index]!), `${index}: the same`)
    })
    assert.deepEqual(
      [...components[0]!.classList].sort(),
      itemClasses({ variant: 'default', size: 'default' }).split(' ').sort(),
    )
    for (const [name, value] of Object.entries(itemAttributes({ name: 'x' }))) {
      assert.strictEqual(components[0]!.getAttribute(name), value ?? null, name)
    }
    await a11yAudit()
  })

  test('a group is a list with a gap, and its separator is a decorative line', async function (assert) {
    await render(
      <template>
        <ItemGroup @name="people" as |g|>
          <Item role="listitem" @variant="outline" as |i|>
            <i.Content><i.Title>shadcn</i.Title></i.Content>
          </Item>
          <g.Separator />
          <Item role="listitem" @variant="outline" as |i|>
            <i.Content><i.Title>maxleiter</i.Title></i.Content>
          </Item>
          <Item role="listitem" @variant="outline" as |i|>
            <i.Content><i.Title>evilrabbit</i.Title></i.Content>
          </Item>
        </ItemGroup>
        {{! A group of another role: a list may hold only its items, so its separators stay decorative. }}
        <ItemGroup @name="small" role="group" aria-label="Small" as |g|>
          <Item @size="sm" as |i|><i.Content>One</i.Content></Item>
          <g.Separator @decorative={{false}} />
          <Item @size="sm" as |i|><i.Content>Two</i.Content></Item>
        </ItemGroup>
      </template>,
    )
    const people = new ItemGroupHarness('people')
    assert
      .dom(people.element)
      .hasAttribute('role', 'list')
      .hasClass('jn-item-group')
      .hasClass('group/item-group')
      .hasAttribute('data-slot', 'item-group')
    assert.deepEqual(
      people.items.map(item => item.title),
      ['shadcn', 'maxleiter', 'evilrabbit'],
    )
    const group = getComputedStyle(people.element)
    assert.strictEqual(group.flexDirection, 'column')
    assert.strictEqual(group.rowGap, '16px', 'gap-4')

    const [line] = people.separators
    assert
      .dom(line)
      .hasClass('jn-item-separator')
      .hasAttribute('data-slot', 'item-separator')
      .hasAttribute('role', 'none', 'decorative, as upstream')
      .hasAttribute('data-orientation', 'horizontal')
      .doesNotHaveAttribute('aria-orientation')
    const separator = getComputedStyle(line!)
    assert.strictEqual(separator.height, '1px', 'h-px')
    assert.strictEqual(separator.marginTop, '8px', 'my-2')
    assert.notStrictEqual(separator.backgroundColor, 'rgba(0, 0, 0, 0)', 'bg-border')

    const small = new ItemGroupHarness('small')
    assert.strictEqual(getComputedStyle(small.element).rowGap, '10px', 'gap-2.5 with sm items')
    assert.dom(small.element).hasAttribute('role', 'group', 'your role wins')
    assert.dom(small.separators[0]).hasAttribute('role', 'separator')
    await a11yAudit()
  })

  test('RTL: media and actions swap sides, and the description starts on the right', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Item @variant="outline" @name="rtl" as |i|>
            <i.Media @variant="icon"><Icon @icon={{Inbox}} /></i.Media>
            <i.Content>
              <i.Title>عنصر أساسي</i.Title>
              <i.Description>عنصر بسيط يحتوي على عنوان ووصف.</i.Description>
            </i.Content>
            <i.Actions><Button @size="sm">إجراء</Button></i.Actions>
          </Item>
        </DirectionProvider>
      </template>,
    )
    const item = new ItemHarness('rtl')
    const media = item.media.getBoundingClientRect()
    const actions = item.actions.getBoundingClientRect()
    assert.ok(media.left > actions.left, 'the media on the right, the actions on the left')
    assert.strictEqual(
      getComputedStyle(item.part('description')).textAlign,
      'start',
      'text-start, which is the right',
    )
    await a11yAudit()
  })

  test('the harness reads its text, parts and link, and throws for a missing part', async function (assert) {
    await render(
      <template>
        <Item @name="song" as |i|>
          <i.Content>
            <i.Title>Digital Rain</i.Title>
            <i.Description>Cyber Symphony</i.Description>
          </i.Content>
          <i.Content><i.Description>3:30</i.Description></i.Content>
        </Item>
      </template>,
    )
    const song = new ItemHarness('song')
    assert.strictEqual(song.text, 'Digital Rain Cyber Symphony 3:30')
    assert.deepEqual(song.descriptions, ['Cyber Symphony', '3:30'])
    assert.strictEqual(song.mediaVariant, null)
    assert.false(song.isLink)
    assert.strictEqual(song.href, null)
    assert.throws(() => song.media, /no "media" part found in item "song"/)
    const [, second] = song.parts('content')
    assert.strictEqual(getComputedStyle(second!).flexGrow, '0', 'a second content keeps its width')
    await a11yAudit()
  })
})
