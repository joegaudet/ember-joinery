import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { getSettledState, render, settled, waitUntil } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Avatar, ImageLoader, type ImageLoadingStatus } from '@ember-joinery/primitives/avatar'
import { AvatarHarness } from '@ember-joinery/test-support'

// A 1×1 grey PNG, so an image loads without the network.
const IMAGE =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR4nGNgAAAAAgABSK+kcQAAAABJRU5ErkJggg=='
// Not an image: it fails at once, without the network.
const BROKEN = 'data:image/png;base64,AAAA'

/**
 * A stand-in for the browser's `Image`, so a test decides when an image loads or fails: the
 * loader never hears from it until the test calls `load()` or `fail()`.
 */
class PendingImage extends EventTarget {
  static made: PendingImage[] = []
  src = ''
  complete = false
  naturalWidth = 0
  crossOrigin: string | null = null
  referrerPolicy = ''
  constructor() {
    super()
    PendingImage.made.push(this)
  }
  load(): void {
    this.complete = true
    this.naturalWidth = 1
    this.dispatchEvent(new Event('load'))
  }
  fail(): void {
    this.complete = true
    this.dispatchEvent(new Event('error'))
  }
}

module('Integration | primitives | avatar', function (hooks) {
  setupRenderingTest(hooks)

  let RealImage: typeof Image
  hooks.beforeEach(function () {
    RealImage = window.Image
    PendingImage.made = []
  })
  hooks.afterEach(function () {
    window.Image = RealImage
  })
  /** Swaps in `PendingImage` for the rest of the test. */
  const holdImages = () => {
    window.Image = PendingImage as unknown as typeof Image
  }

  test("the image renders once it has loaded, and the fallback doesn't", async function (assert) {
    await render(
      <template>
        <Avatar @name="loaded" as |a|>
          <a.Image @src={{IMAGE}} alt="Ada" />
          <a.Fallback>AL</a.Fallback>
        </Avatar>
      </template>,
    )
    const avatar = new AvatarHarness('loaded')
    assert.dom(avatar.element).hasTagName('span').hasNoAttribute('data-loading')
    assert.dom(avatar.element).hasNoAttribute('data-error')
    assert.dom(avatar.image).hasTagName('img').hasAttribute('src', IMAGE).hasAttribute('alt', 'Ada')
    assert.strictEqual(avatar.fallback, null, 'no fallback once the image shows')
    assert.strictEqual(avatar.status, 'loaded')
    assert.strictEqual(avatar.label, 'Ada')
    assert.strictEqual(avatar.size, null, 'the headless avatar has no size')
    await a11yAudit()
  })

  test('a broken image leaves the fallback, and marks the avatar data-error', async function (assert) {
    await render(
      <template>
        <Avatar @name="broken" as |a|>
          <a.Image @src={{BROKEN}} alt="Ada" />
          <a.Fallback>AL</a.Fallback>
        </Avatar>
      </template>,
    )
    const avatar = new AvatarHarness('broken')
    assert.strictEqual(avatar.image, null)
    assert.dom(avatar.fallback).hasTagName('span').hasText('AL')
    assert.dom(avatar.element).hasAttribute('data-error')
    assert.true(avatar.isError)
    assert.strictEqual(avatar.label, 'AL', 'the fallback names it')
    await a11yAudit()
  })

  test("ember-primitives' way: @src on the avatar, and its state yielded", async function (assert) {
    await render(
      <template>
        <Avatar @src={{IMAGE}} @name="root" as |a|>
          <a.Image alt="Ada" />
          <a.Fallback>AL</a.Fallback>
          <span data-status>{{a.status}} {{if a.isLoaded "loaded"}}</span>
        </Avatar>
        <Avatar @src={{BROKEN}} @name="root-broken" as |a|>
          <a.Image alt="Ada" />
          <a.Fallback>AL</a.Fallback>
          <span data-status>{{a.status}} {{if a.isError "error"}}</span>
        </Avatar>
      </template>,
    )
    const loaded = new AvatarHarness('root')
    assert.dom(loaded.image).hasAttribute('src', IMAGE)
    assert.dom('[data-status]', loaded.element).hasText('loaded loaded')

    const broken = new AvatarHarness('root-broken')
    assert.strictEqual(broken.image, null)
    assert.strictEqual(broken.fallbackText, 'AL')
    assert.dom('[data-status]', broken.element).hasText('error error')
    await a11yAudit()
  })

  test('while the image loads, the fallback shows and the avatar is data-loading', async function (assert) {
    holdImages()
    const statuses: ImageLoadingStatus[] = []
    const record = (status: ImageLoadingStatus) => statuses.push(status)
    const rendered = render(
      <template>
        <Avatar @name="pending" as |a|>
          <a.Image
            @src={{IMAGE}}
            @crossOrigin="anonymous"
            @referrerPolicy="no-referrer"
            @onLoadingStatusChange={{record}}
            alt="Ada"
          />
          <a.Fallback>AL</a.Fallback>
          <span data-status>{{a.status}}</span>
        </Avatar>
      </template>,
    )
    await waitUntil(() => statuses.length > 0)
    const avatar = new AvatarHarness('pending')
    assert.true(avatar.isLoading)
    assert.dom(avatar.element).hasAttribute('data-loading')
    assert.strictEqual(avatar.fallbackText, 'AL', 'the fallback shows while it loads')
    assert.strictEqual(avatar.image, null, 'no <img> until it has loaded')
    assert.dom('[data-status]', avatar.element).hasText('loading')
    assert.true(getSettledState().hasPendingWaiters, 'tests wait for the image')

    const [image] = PendingImage.made
    assert.strictEqual(PendingImage.made.length, 1, 'one image loads')
    assert.strictEqual(image!.src, IMAGE)
    assert.strictEqual(image!.crossOrigin, 'anonymous', 'fetched as the <img> will be')
    assert.strictEqual(image!.referrerPolicy, 'no-referrer')

    image!.load()
    await rendered
    assert.true(avatar.isLoaded)
    assert.dom(avatar.element).hasNoAttribute('data-loading')
    assert
      .dom(avatar.image)
      .hasAttribute('crossorigin', 'anonymous')
      .hasAttribute('referrerpolicy', 'no-referrer')
    assert.strictEqual(avatar.fallback, null)
    assert.deepEqual(statuses, ['loading', 'loaded'], '@onLoadingStatusChange heard each')
    await a11yAudit()
  })

  test('a new @src loads the new image, and a failure brings the fallback back', async function (assert) {
    class State {
      @tracked src = IMAGE
    }
    const state = new State()
    await render(
      <template>
        <Avatar @name="change" as |a|>
          <a.Image @src={{state.src}} alt="Ada" />
          <a.Fallback>AL</a.Fallback>
        </Avatar>
      </template>,
    )
    const avatar = new AvatarHarness('change')
    assert.true(avatar.isLoaded)

    state.src = BROKEN
    await settled()
    assert.true(avatar.isError)
    assert.strictEqual(avatar.fallbackText, 'AL')

    state.src = `${IMAGE}#again`
    await settled()
    assert.true(avatar.isLoaded)
    assert.strictEqual(avatar.src, `${IMAGE}#again`)
    await a11yAudit()
  })

  test('@delayMs holds the fallback back, so a fast connection never sees it', async function (assert) {
    holdImages()
    const rendered = render(
      <template>
        <Avatar @name="delayed" as |a|>
          <a.Image @src={{IMAGE}} alt="Ada" />
          <a.Fallback @delayMs={{100}}>AL</a.Fallback>
        </Avatar>
      </template>,
    )
    await waitUntil(() => PendingImage.made.length === 1)
    const avatar = new AvatarHarness('delayed')
    assert.true(avatar.isLoading)
    assert.strictEqual(avatar.fallback, null, 'not yet')

    await waitUntil(() => avatar.fallback !== null, { timeout: 2000 })
    assert.strictEqual(avatar.fallbackText, 'AL', 'after the delay, while it still loads')

    PendingImage.made[0]!.fail()
    await rendered
    assert.true(avatar.isError)
    assert.strictEqual(avatar.fallbackText, 'AL')
    await a11yAudit()
  })

  test('without an image, the avatar is idle and shows its fallback', async function (assert) {
    await render(
      <template>
        <Avatar @name="idle" @as="div" as |a|>
          <a.Fallback @as="div">AL</a.Fallback>
          <span data-status>{{a.status}}</span>
        </Avatar>
      </template>,
    )
    const avatar = new AvatarHarness('idle')
    assert.dom(avatar.element).hasTagName('div')
    assert.dom(avatar.fallback).hasTagName('div')
    assert.strictEqual(avatar.status, 'idle')
    assert.dom('[data-status]', avatar.element).hasText('idle')
    await a11yAudit()
  })

  test('ImageLoader: a loaded, a broken and a missing image, and destroy', async function (assert) {
    const loaded = new ImageLoader(IMAGE)
    const broken = new ImageLoader(BROKEN)
    const missing = new ImageLoader(undefined)
    assert.strictEqual(missing.status, 'error', 'no src is an error, as in Radix')
    await settled()
    assert.strictEqual(loaded.status, 'loaded')
    assert.strictEqual(broken.status, 'error')

    holdImages()
    const pending = new ImageLoader(IMAGE)
    const heard: ImageLoadingStatus[] = []
    pending.subscribe(status => heard.push(status))
    assert.strictEqual(pending.status, 'loading')
    assert.true(getSettledState().hasPendingWaiters)
    pending.destroy()
    assert.false(getSettledState().hasPendingWaiters, 'destroying it stops the wait')
    PendingImage.made[0]!.load()
    assert.strictEqual(pending.status, 'loading', 'a destroyed loader hears nothing')
    assert.deepEqual(heard, [])
    for (const loader of [loaded, broken, missing]) loader.destroy()
  })
})
