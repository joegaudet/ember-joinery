import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Plus } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Avatar, AvatarGroup, Icon, type AvatarSize } from '@ember-joinery/ember'
import { AvatarGroupHarness, AvatarHarness, IconHarness } from '@ember-joinery/test-support'

const SIZES: AvatarSize[] = ['default', 'sm', 'lg']

// A 1×1 grey PNG, so an image loads without the network.
const IMAGE =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR4nGNgAAAAAgABSK+kcQAAAABJRU5ErkJggg=='
// Not an image: it fails at once, so the fallback shows.
const BROKEN = 'data:image/png;base64,AAAA'

/**
 * The audit, but for the contrast of the fallback's and the count's own text: upstream draws
 * them `--muted-foreground` on `--muted`, 4.34:1 in the default theme, under the 4.5:1 WCAG AA
 * asks of their 14px text (the Avatar page's Accessibility notes say how an app can darken it).
 * Everything around them is audited.
 */
const BUT_THE_INITIALS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="avatar-fallback"]'], ['[data-slot="avatar-group-count"]']],
}

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

module('Integration | components | avatar', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and data attributes on every part', async function (assert) {
    await render(
      <template>
        <Avatar @name="loaded" as |a|>
          <a.Image @src={{IMAGE}} alt="@shadcn" />
          <a.Fallback>CN</a.Fallback>
          <a.Badge />
        </Avatar>
        <Avatar @name="broken" as |a|>
          <a.Image @src={{BROKEN}} alt="@shadcn" />
          <a.Fallback>CN</a.Fallback>
        </Avatar>
      </template>,
    )
    const loaded = new AvatarHarness('loaded')
    assert
      .dom(loaded.element)
      .hasTagName('span', "Radix's root, a span")
      .hasClass('jn-avatar')
      .hasClass('group/avatar', 'the marker its parts look for')
      .hasAttribute('data-slot', 'avatar')
      .hasAttribute('data-size', 'default')
      .hasAttribute('data-test-jn', 'avatar')
    assert
      .dom(loaded.image)
      .hasTagName('img')
      .hasClass('jn-avatar-image')
      .hasAttribute('data-slot', 'avatar-image')
      .hasAttribute('src', IMAGE)
    assert
      .dom(loaded.badge)
      .hasTagName('span')
      .hasClass('jn-avatar-badge')
      .hasAttribute('data-slot', 'avatar-badge')
    assert.strictEqual(loaded.fallback, null, 'the fallback goes once the image loads')

    const broken = new AvatarHarness('broken')
    assert.strictEqual(broken.image, null)
    assert
      .dom(broken.fallback)
      .hasTagName('span')
      .hasClass('jn-avatar-fallback')
      .hasAttribute('data-slot', 'avatar-fallback')
      .hasText('CN')
    await a11yAudit(BUT_THE_INITIALS)
  })

  test('every size renders its data attribute, and the style sheet sizes it', async function (assert) {
    await render(
      <template>
        {{#each SIZES as |size|}}
          <Avatar @size={{size}} @name={{size}} as |a|>
            <a.Image @src={{BROKEN}} alt="@shadcn" />
            <a.Fallback>CN</a.Fallback>
          </Avatar>
        {{/each}}
      </template>,
    )
    const expected = { default: 32, sm: 24, lg: 40 }
    for (const size of SIZES) {
      const avatar = new AvatarHarness(size)
      assert.strictEqual(avatar.size, size)
      const style = getComputedStyle(avatar.element)
      assert.strictEqual(px(style.width), expected[size], `${size}: size-${expected[size] / 4}`)
      assert.strictEqual(px(style.height), expected[size])
    }
    const fontSize = (size: AvatarSize) =>
      getComputedStyle(new AvatarHarness(size).fallback!).fontSize
    assert.strictEqual(fontSize('default'), '14px', 'text-sm')
    assert.strictEqual(fontSize('sm'), '12px', 'text-xs in a small avatar')
    await a11yAudit(BUT_THE_INITIALS)
  })

  test('its style sheet makes it round, with the image filling it and a muted fallback', async function (assert) {
    await render(
      <template>
        <Avatar @name="image" as |a|>
          <a.Image @src={{IMAGE}} alt="@shadcn" />
          <a.Fallback>CN</a.Fallback>
        </Avatar>
        <Avatar @name="fallback" as |a|>
          <a.Fallback>CN</a.Fallback>
        </Avatar>
      </template>,
    )
    const image = new AvatarHarness('image')
    const root = getComputedStyle(image.element)
    assert.strictEqual(root.display, 'flex')
    assert.strictEqual(root.position, 'relative')
    assert.ok(px(root.borderTopLeftRadius) >= 16, 'rounded-full')
    assert.strictEqual(root.flexShrink, '0')
    const ring = getComputedStyle(image.element, '::after')
    assert.strictEqual(ring.position, 'absolute', 'a border drawn over the image')
    assert.strictEqual(ring.borderTopWidth, '1px')
    assert.strictEqual(ring.mixBlendMode, 'darken')

    const img = getComputedStyle(image.image!)
    assert.strictEqual(img.width, '32px', 'size-full')
    assert.strictEqual(img.objectFit, 'cover')
    assert.strictEqual(img.aspectRatio, '1 / 1')

    const fallback = new AvatarHarness('fallback')
    const initials = getComputedStyle(fallback.fallback!)
    assert.strictEqual(initials.display, 'flex')
    assert.strictEqual(initials.justifyContent, 'center')
    assert.strictEqual(initials.width, '32px')
    assert.notStrictEqual(
      initials.backgroundColor,
      'rgba(0, 0, 0, 0)',
      'bg-muted behind the initials',
    )
    assert.strictEqual(fallback.status, 'idle', 'no image: idle, and the fallback shows')
    await a11yAudit(BUT_THE_INITIALS)
  })

  test('a badge sits on the bottom end corner, sized by the avatar, and hides its icon when small', async function (assert) {
    await render(
      <template>
        {{#each SIZES as |size|}}
          <Avatar @size={{size}} @name={{size}} as |a|>
            <a.Image @src={{IMAGE}} alt="@shadcn" />
            <a.Badge><Icon @icon={{Plus}} /></a.Badge>
          </Avatar>
        {{/each}}
        <Avatar @name="dot" as |a|>
          <a.Image @src={{IMAGE}} alt="@shadcn" />
          <span {{a.badge}} class="mine"></span>
        </Avatar>
      </template>,
    )
    const expected = { default: 10, sm: 8, lg: 12 }
    for (const size of SIZES) {
      const avatar = new AvatarHarness(size)
      const badge = avatar.badge!
      assert.strictEqual(px(getComputedStyle(badge).width), expected[size], `${size} badge`)
      const box = avatar.element.getBoundingClientRect()
      const corner = badge.getBoundingClientRect()
      assert.strictEqual(corner.right, box.right, 'on the right, left to right')
      assert.strictEqual(corner.bottom, box.bottom, 'at the bottom')
    }
    const icon = (size: AvatarSize) =>
      getComputedStyle(new AvatarHarness(size).badge!.firstElementChild!)
    assert.strictEqual(icon('sm').display, 'none', "a small avatar's badge hides its icon")
    assert.strictEqual(icon('default').width, '8px', 'size-2')
    assert.strictEqual(icon('lg').width, '8px')

    const dot = new AvatarHarness('dot')
    assert.dom(dot.badge).hasClass('jn-avatar-badge').hasClass('mine')
    assert.true(dot.hasBadge, 'the modifier makes your own element the badge')
    await a11yAudit()
  })

  test('a group overlaps its avatars, rings them, and ends in a count sized like them', async function (assert) {
    await render(
      <template>
        <AvatarGroup @name="team" as |g|>
          <Avatar as |a|><a.Image @src={{IMAGE}} alt="@shadcn" /></Avatar>
          <Avatar as |a|><a.Image @src={{IMAGE}} alt="@maxleiter" /></Avatar>
          <g.Count>+3</g.Count>
        </AvatarGroup>
        <AvatarGroup @name="large" as |g|>
          <Avatar @size="lg" as |a|><a.Image @src={{IMAGE}} alt="@shadcn" /></Avatar>
          <g.Count><Icon @icon={{Plus}} /></g.Count>
        </AvatarGroup>
      </template>,
    )
    const team = new AvatarGroupHarness('team')
    assert
      .dom(team.element)
      .hasTagName('div')
      .hasClass('jn-avatar-group')
      .hasClass('group/avatar-group')
      .hasAttribute('data-slot', 'avatar-group')
    assert.strictEqual(team.avatars.length, 2)
    assert.strictEqual(team.count, '+3')
    assert
      .dom(team.countElement)
      .hasClass('jn-avatar-group-count')
      .hasAttribute('data-slot', 'avatar-group-count')

    const [first, second] = team.avatars
    assert.strictEqual(
      getComputedStyle(first!.element).marginInlineEnd,
      '-8px',
      '-space-x-2: each overlaps the next by 8px',
    )
    const a = first!.element.getBoundingClientRect()
    const b = second!.element.getBoundingClientRect()
    assert.ok(b.left < a.right && b.left > a.left, 'the second starts inside the first')
    assert.notStrictEqual(
      getComputedStyle(first!.element).boxShadow,
      'none',
      'ring-2 ring-background',
    )
    assert.strictEqual(getComputedStyle(team.countElement!).width, '32px', 'like its avatars')

    const large = new AvatarGroupHarness('large')
    assert.strictEqual(getComputedStyle(large.countElement!).width, '40px', 'beside lg avatars')
    assert.strictEqual(large.count, '', 'an icon, no text')
    assert.strictEqual(
      getComputedStyle(large.countElement!.querySelector('svg')!).width,
      '20px',
      'the icon grows with them',
    )
    await a11yAudit(BUT_THE_INITIALS)
  })

  test('RTL: the badge moves to the left, and the group overlaps the other way', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Avatar @name="rtl" as |a|>
            <a.Image @src={{IMAGE}} alt="@shadcn" />
            <a.Badge />
          </Avatar>
          <AvatarGroup @name="group" as |g|>
            <Avatar as |a|><a.Image @src={{IMAGE}} alt="@shadcn" /></Avatar>
            <Avatar as |a|><a.Image @src={{IMAGE}} alt="@evilrabbit" /></Avatar>
            <g.Count>+٣</g.Count>
          </AvatarGroup>
        </DirectionProvider>
      </template>,
    )
    const avatar = new AvatarHarness('rtl')
    const box = avatar.element.getBoundingClientRect()
    assert.strictEqual(avatar.badge!.getBoundingClientRect().left, box.left, 'end-0: the left')

    const [first, second] = new AvatarGroupHarness('group').avatars
    const a = first!.element.getBoundingClientRect()
    const b = second!.element.getBoundingClientRect()
    assert.ok(b.right > a.left && b.right < a.right, 'the second overlaps the first from the left')
    assert.strictEqual(
      px(getComputedStyle(first!.element).marginLeft),
      -8,
      'its margin on the left',
    )
    await a11yAudit(BUT_THE_INITIALS)
  })

  test('it takes attributes and classes, @as, and @src on the avatar', async function (assert) {
    await render(
      <template>
        <Avatar @name="mine" @as="div" @src={{IMAGE}} class="grayscale" title="Ada" as |a|>
          <a.Image class="mine" alt="Ada Lovelace" />
          <a.Fallback @as="div">AL</a.Fallback>
        </Avatar>
      </template>,
    )
    const avatar = new AvatarHarness('mine')
    assert
      .dom(avatar.element)
      .hasTagName('div')
      .hasClass('grayscale')
      .hasClass('jn-avatar')
      .hasAttribute('title', 'Ada')
    assert.dom(avatar.image).hasClass('mine').hasClass('jn-avatar-image')
    assert.strictEqual(avatar.label, 'Ada Lovelace')
    assert.true(avatar.isLoaded)
    await a11yAudit()
  })

  test('the harness reads the status, label, fallback and badge', async function (assert) {
    await render(
      <template>
        <Avatar @name="loaded" as |a|>
          <a.Image @src={{IMAGE}} alt="@evilrabbit" />
          <a.Fallback>ER</a.Fallback>
          <a.Badge />
        </Avatar>
        <Avatar @name="broken" @size="sm" as |a|>
          <a.Image @src={{BROKEN}} alt="@evilrabbit" />
          <a.Fallback> ER </a.Fallback>
        </Avatar>
        <Avatar @name="icon" as |a|>
          <a.Fallback><Icon @icon={{Plus}} @label="Add someone" /></a.Fallback>
        </Avatar>
      </template>,
    )
    const loaded = new AvatarHarness('loaded')
    assert.strictEqual(loaded.status, 'loaded')
    assert.true(loaded.isLoaded)
    assert.false(loaded.isLoading)
    assert.strictEqual(loaded.label, '@evilrabbit')
    assert.strictEqual(loaded.src, IMAGE)
    assert.strictEqual(loaded.fallbackText, '')
    assert.true(loaded.hasBadge)

    const broken = new AvatarHarness('broken')
    assert.strictEqual(broken.status, 'error')
    assert.true(broken.isError)
    assert.strictEqual(broken.fallbackText, 'ER', 'whitespace trimmed')
    assert.strictEqual(broken.label, 'ER')
    assert.strictEqual(broken.src, null)
    assert.strictEqual(broken.size, 'sm')
    assert.false(broken.hasBadge)

    const icon = new AvatarHarness('icon')
    assert.strictEqual(icon.find(IconHarness).label, 'Add someone')
    assert.throws(() => new AvatarHarness('missing').element, /no avatar "missing" found/)
    await a11yAudit(BUT_THE_INITIALS)
  })
})
