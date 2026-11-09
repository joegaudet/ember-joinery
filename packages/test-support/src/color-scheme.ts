/** The test hooks `setupColorScheme` registers on: QUnit's `hooks`, or Vitest's shape of it. */
export interface TestHooks {
  beforeEach(callback: () => void | Promise<void>): void
  afterEach(callback: () => void | Promise<void>): void
}

/** A color scheme the system can prefer. */
export type SystemColorScheme = 'light' | 'dark'

export interface ColorSchemeEmulation {
  /** What the emulated system prefers now. */
  readonly system: SystemColorScheme
  /** Changes what the system prefers, as switching the OS to dark mode would: listeners hear it. */
  setSystem(scheme: SystemColorScheme): void
  /**
   * What another tab does when the user picks a scheme there: saves it and sends the `storage`
   * event. `null` clears the saved choice.
   */
  fromAnotherTab(preference: string | null): void
  /** The saved choice, or `null`. */
  readonly stored: string | null
}

export interface SetupColorSchemeOptions {
  /** What the system prefers at the start of each test. Default `light`. */
  system?: SystemColorScheme
  /** The storage key the app's `ColorScheme` uses. Default `joinery-color-scheme`. */
  storageKey?: string
}

/** `@ember-joinery/primitives/color-scheme`'s default key (`COLOR_SCHEME_STORAGE_KEY`). */
const DEFAULT_STORAGE_KEY = 'joinery-color-scheme'

const QUERY = /^\(\s*prefers-color-scheme\s*:\s*(light|dark|no-preference)\s*\)$/

/** A `MediaQueryList` for a `prefers-color-scheme` query, answered by the emulation. */
class EmulatedMediaQueryList extends EventTarget implements MediaQueryList {
  readonly media: string
  readonly #value: string
  readonly #system: () => SystemColorScheme
  onchange: ((this: MediaQueryList, event: MediaQueryListEvent) => unknown) | null = null
  readonly #legacy = new Set<(event: MediaQueryListEvent) => void>()

  constructor(media: string, value: string, system: () => SystemColorScheme) {
    super()
    this.media = media
    this.#value = value
    this.#system = system
  }

  get matches(): boolean {
    return this.#system() === this.#value
  }

  addListener(listener: ((event: MediaQueryListEvent) => void) | null): void {
    if (listener) this.#legacy.add(listener)
  }

  removeListener(listener: ((event: MediaQueryListEvent) => void) | null): void {
    if (listener) this.#legacy.delete(listener)
  }

  /** Tells listeners the answer changed. */
  notify(): void {
    const event = new MediaQueryListEvent('change', { matches: this.matches, media: this.media })
    this.dispatchEvent(event)
    this.onchange?.call(this, event)
    for (const listener of this.#legacy) listener(event)
  }
}

/**
 * Isolates each test from the color scheme around it: what the machine running the tests
 * prefers, and a choice an earlier test saved. Before each test it clears the saved choice and
 * makes `matchMedia('(prefers-color-scheme: …)')` answer from an emulated system preference
 * instead of the real one; after each, it puts both back.
 *
 *   module('dark mode', function (hooks) {
 *     setupRenderingTest(hooks)
 *     const scheme = setupColorScheme(hooks, { system: 'light' })
 *
 *     test('it follows the system', async function (assert) {
 *       await render(<template><ModeToggle /></template>)
 *       scheme.setSystem('dark')
 *       await settled()
 *       assert.dom(document.documentElement).hasClass('dark')
 *     })
 *   })
 *
 * The app's `ColorScheme` is per owner, so it starts fresh in each test without help.
 */
export function setupColorScheme(
  hooks: TestHooks,
  options: SetupColorSchemeOptions = {},
): ColorSchemeEmulation {
  const storageKey = options.storageKey ?? DEFAULT_STORAGE_KEY
  let system: SystemColorScheme = options.system ?? 'light'
  let lists = new Map<string, EmulatedMediaQueryList>()
  let original: typeof window.matchMedia | undefined

  const clear = () => {
    try {
      localStorage.removeItem(storageKey)
    } catch {
      // storage is off; there is nothing saved
    }
  }

  hooks.beforeEach(() => {
    system = options.system ?? 'light'
    lists = new Map()
    clear()
    const real = window.matchMedia
    original = real
    window.matchMedia = (query: string): MediaQueryList => {
      const match = QUERY.exec(query.trim())
      if (!match) return real.call(window, query)
      let list = lists.get(query)
      if (!list)
        lists.set(query, (list = new EmulatedMediaQueryList(query, match[1]!, () => system)))
      return list
    }
  })

  hooks.afterEach(() => {
    if (original) window.matchMedia = original
    original = undefined
    clear()
  })

  return {
    get system() {
      return system
    },
    setSystem(scheme: SystemColorScheme) {
      if (scheme === system) return
      const before = new Map([...lists].map(([query, list]) => [query, list.matches]))
      system = scheme
      for (const [query, list] of lists) if (before.get(query) !== list.matches) list.notify()
    },
    fromAnotherTab(preference: string | null) {
      const oldValue = localStorage.getItem(storageKey)
      if (preference === null) localStorage.removeItem(storageKey)
      else localStorage.setItem(storageKey, preference)
      window.dispatchEvent(
        new StorageEvent('storage', {
          key: storageKey,
          oldValue,
          newValue: preference,
          storageArea: localStorage,
          url: location.href,
        }),
      )
    },
    get stored() {
      return localStorage.getItem(storageKey)
    },
  }
}
