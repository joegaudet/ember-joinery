import { tracked } from '@glimmer/tracking'
import { registerDestructor } from '@ember/destroyable'
import { waitForPromise } from '@ember/test-waiters'
import { service } from './service.ts'

/** What the user chose: follow the system, or always light, or always dark. */
export type ColorSchemePreference = 'system' | 'light' | 'dark'

/** The scheme in effect. */
export type ColorSchemeValue = 'light' | 'dark'

/** Where the choice is saved, in `localStorage`, unless `configure()` names another key. */
export const COLOR_SCHEME_STORAGE_KEY = 'joinery-color-scheme'

const DARK_QUERY = '(prefers-color-scheme: dark)'

export interface ColorSchemeOptions {
  /** The `localStorage` key the choice is saved under, or `null` not to save it. */
  storageKey?: string | null
  /** The preference before the user has chosen one. Default `system`. */
  defaultPreference?: ColorSchemePreference
  /** The element that gets the class and `color-scheme`. Default `<html>`. */
  element?: HTMLElement
  /** The class set while dark. Default `dark`, which Joinery's tokens (and shadcn's) use. */
  darkClass?: string | null
  /** A class set while light, if you want one. Default none. */
  lightClass?: string | null
  /** Turn CSS transitions off for the moment the scheme changes, as next-themes can. */
  disableTransitionOnChange?: boolean
}

type Settings = Required<Omit<ColorSchemeOptions, 'element'>> & { element: HTMLElement | null }

function isPreference(value: unknown): value is ColorSchemePreference {
  return value === 'system' || value === 'light' || value === 'dark'
}

function readStorage(key: string | null): ColorSchemePreference | undefined {
  if (key === null) return undefined
  try {
    const value = localStorage.getItem(key)
    return isPreference(value) ? value : undefined
  } catch {
    return undefined // storage can be off (private windows, sandboxed frames)
  }
}

function isLocalStorage(area: Storage | null): boolean {
  try {
    return area === null || area === localStorage
  } catch {
    return false
  }
}

function writeStorage(key: string | null, value: ColorSchemePreference | null): void {
  if (key === null) return
  try {
    if (value === null) localStorage.removeItem(key)
    else localStorage.setItem(key, value)
  } catch {
    // storage can be off; the choice then lasts for the page
  }
}

/** Stops transitions for one frame, as next-themes' `disableTransitionOnChange` does. */
function suspendTransitions(): () => void {
  const style = document.createElement('style')
  style.textContent =
    '*,*::before,*::after{-webkit-transition:none!important;transition:none!important}'
  document.head.appendChild(style)
  return () => {
    // Force the change to apply while transitions are off, then let them back in.
    void getComputedStyle(document.body).opacity
    void waitForPromise(new Promise(resolve => setTimeout(resolve, 1)).then(() => style.remove()))
  }
}

/**
 * The app's color scheme: the user's choice of light, dark or the system's, saved in
 * `localStorage`, kept in step across tabs and with the system, and applied to `<html>` as the
 * `dark` class (what Joinery's and shadcn's tokens use) and the `color-scheme` property (what
 * the browser's own controls and scrollbars use). It replaces next-themes, and covers
 * ember-primitives' color-scheme utility.
 *
 * There is one per app (and so one per test), through `service`:
 *
 *   const scheme = colorScheme(this)   // in a component, route or controller
 *   scheme.set('dark')
 *   scheme.current                     // 'dark'
 *
 *   {{#let (service ColorScheme) as |scheme|}}
 *     <button type="button" {{on "click" scheme.toggle}}>{{scheme.current}}</button>
 *   {{/let}}
 *
 * It applies itself the first time it is asked for. Ask for it early, in the application
 * route, to apply the saved choice when the app boots; `colorSchemeScript()` applies it even
 * before that, from `index.html`.
 */
export class ColorScheme {
  /** What the user chose: `system`, `light` or `dark`. */
  @tracked preference: ColorSchemePreference
  /** What the system prefers now. */
  @tracked system: ColorSchemeValue
  /**
   * The choice saved for the next visit, or `null` when there is none (the user hasn't chosen,
   * `clear()` forgot it, or nothing is saved). ember-primitives' `localPreference.read()`.
   */
  @tracked saved: ColorSchemePreference | null

  #settings: Settings = {
    storageKey: COLOR_SCHEME_STORAGE_KEY,
    defaultPreference: 'system',
    element: null,
    darkClass: 'dark',
    lightClass: null,
    disableTransitionOnChange: false,
  }
  #media: MediaQueryList
  #listeners = new Set<(scheme: ColorSchemeValue, preference: ColorSchemePreference) => void>()
  #applied: ColorSchemeValue | undefined
  /** The element's state before this touched it, put back when the app is destroyed. */
  #original: { element: HTMLElement; classes: string[]; colorScheme: string } | undefined

  constructor() {
    this.#media = window.matchMedia(DARK_QUERY)
    this.system = this.#media.matches ? 'dark' : 'light'
    this.saved = readStorage(this.#settings.storageKey) ?? null
    this.preference = this.saved ?? this.#settings.defaultPreference

    this.#media.addEventListener('change', this.#onSystemChange)
    window.addEventListener('storage', this.#onStorage)
    registerDestructor(this, () => {
      this.#media.removeEventListener('change', this.#onSystemChange)
      window.removeEventListener('storage', this.#onStorage)
      this.#restore()
    })
    this.#apply()
  }

  /** The scheme in effect: the preference, with `system` resolved. */
  get current(): ColorSchemeValue {
    return this.preference === 'system' ? this.system : this.preference
  }

  get isDark(): boolean {
    return this.current === 'dark'
  }

  get isLight(): boolean {
    return this.current === 'light'
  }

  /**
   * Changes the preference, saves it, and applies it. `set('system')` saves `system`, as
   * next-themes does; `clear()` forgets the choice instead.
   */
  set = (preference: ColorSchemePreference): void => {
    if (!isPreference(preference)) {
      throw new Error(`Joinery: a color scheme is 'system', 'light' or 'dark', not '${preference}'`)
    }
    this.preference = preference
    writeStorage(this.#settings.storageKey, preference)
    this.saved = readStorage(this.#settings.storageKey) ?? null
    this.#apply()
  }

  /**
   * Forgets the saved choice and goes back to the default preference (`system`, unless
   * `configure()` set another), as ember-primitives' `localPreference.delete()` does.
   */
  clear = (): void => {
    writeStorage(this.#settings.storageKey, null)
    this.saved = null
    this.preference = this.#settings.defaultPreference
    this.#apply()
  }

  /** Switches to the other of light and dark (leaving `system` behind). */
  toggle = (): void => {
    this.set(this.isDark ? 'light' : 'dark')
  }

  /**
   * Changes where and how the scheme is saved and applied. Call it before the app renders,
   * as in the application route. A new storage key's saved choice is read and applied.
   */
  configure(options: ColorSchemeOptions): this {
    const before = this.#settings
    this.#restore()
    this.#settings = { ...before, ...options, element: options.element ?? before.element }
    if (options.storageKey !== undefined || options.defaultPreference !== undefined) {
      this.saved = readStorage(this.#settings.storageKey) ?? null
      this.preference = this.saved ?? this.#settings.defaultPreference
    }
    this.#applied = undefined
    this.#apply()
    return this
  }

  /** Calls `listener` whenever the scheme in effect changes. Returns the unsubscribe. */
  onChange(
    listener: (scheme: ColorSchemeValue, preference: ColorSchemePreference) => void,
  ): () => void {
    this.#listeners.add(listener)
    return () => this.#listeners.delete(listener)
  }

  #onSystemChange = (event: MediaQueryListEvent): void => {
    this.system = event.matches ? 'dark' : 'light'
    this.#apply()
  }

  /** Another tab saved a choice (or cleared storage). */
  #onStorage = (event: StorageEvent): void => {
    const key = this.#settings.storageKey
    if (key === null || (event.key !== null && event.key !== key)) return
    if (!isLocalStorage(event.storageArea)) return
    const value = event.newValue
    this.saved = event.key !== null && isPreference(value) ? value : null
    this.preference = this.saved ?? this.#settings.defaultPreference
    this.#apply()
  }

  get #element(): HTMLElement {
    return this.#settings.element ?? document.documentElement
  }

  #apply(): void {
    const scheme = this.current
    const element = this.#element
    if (!this.#original) {
      this.#original = {
        element,
        classes: [this.#settings.darkClass, this.#settings.lightClass].filter(
          (name): name is string => !!name && element.classList.contains(name),
        ),
        colorScheme: element.style.colorScheme,
      }
    }
    const changed = this.#applied !== undefined && this.#applied !== scheme
    const resume =
      changed && this.#settings.disableTransitionOnChange ? suspendTransitions() : undefined

    const { darkClass, lightClass } = this.#settings
    if (darkClass) element.classList.toggle(darkClass, scheme === 'dark')
    if (lightClass) element.classList.toggle(lightClass, scheme === 'light')
    element.style.colorScheme = scheme
    resume?.()

    const previous = this.#applied
    this.#applied = scheme
    if (previous !== undefined && previous !== scheme) {
      for (const listener of this.#listeners) listener(scheme, this.preference)
    }
  }

  /** Puts the element back as it was before. */
  #restore(): void {
    const original = this.#original
    if (!original) return
    const { element } = original
    for (const name of [this.#settings.darkClass, this.#settings.lightClass]) {
      if (name) element.classList.toggle(name, original.classes.includes(name))
    }
    element.style.colorScheme = original.colorScheme
    this.#original = undefined
  }
}

/**
 * The app's `ColorScheme`, for anything with an owner (a component, route or controller).
 *
 *   colorScheme(this).set('dark')
 */
export function colorScheme(context: object): ColorScheme {
  return service(context, ColorScheme)
}

/**
 * What the system prefers, read now (ember-primitives' `prefers`). `custom` asks about any
 * other `prefers-color-scheme` value.
 */
export const prefers = {
  dark: (): boolean => window.matchMedia(DARK_QUERY).matches,
  light: (): boolean => window.matchMedia('(prefers-color-scheme: light)').matches,
  none: (): boolean => window.matchMedia('(prefers-color-scheme: no-preference)').matches,
  custom: (name: string): boolean => window.matchMedia(`(prefers-color-scheme: ${name})`).matches,
}

/** The `color-scheme` set on an element (default `<html>`). */
export function getColorScheme(element: HTMLElement = document.documentElement): string {
  return element.style.getPropertyValue('color-scheme')
}

/**
 * Sets `color-scheme` on `<html>`, or on one element, such as a preview that stays dark. This
 * sets only the property; `ColorScheme` is what applies, saves and syncs the user's choice.
 *
 *   setColorScheme('dark')
 *   setColorScheme(preview, 'dark')
 */
export function setColorScheme(value: string): void
export function setColorScheme(element: HTMLElement, value: string): void
export function setColorScheme(...args: [string] | [HTMLElement, string]): void {
  const [element, value] =
    args.length === 1 ? [document.documentElement, args[0]] : (args as [HTMLElement, string])
  element.style.setProperty('color-scheme', value)
}

/** Removes `color-scheme` from an element (default `<html>`). */
export function removeColorScheme(element: HTMLElement = document.documentElement): void {
  element.style.removeProperty('color-scheme')
}

/**
 * A script for `index.html` that applies the saved scheme before the app loads, so a dark page
 * doesn't flash light first (next-themes does the same). Put its output in a `<script>` in
 * `<head>`; give it the same options as `configure()`.
 *
 *   <script>(function(){…})()</script>
 */
export function colorSchemeScript(
  options: Pick<
    ColorSchemeOptions,
    'storageKey' | 'defaultPreference' | 'darkClass' | 'lightClass'
  > = {},
): string {
  const settings = JSON.stringify({
    key: options.storageKey === undefined ? COLOR_SCHEME_STORAGE_KEY : options.storageKey,
    fallback: options.defaultPreference ?? 'system',
    dark: options.darkClass === undefined ? 'dark' : options.darkClass,
    light: options.lightClass ?? null,
  })
  return (
    `(function(s){try{var p=s.key&&localStorage.getItem(s.key);` +
    `if(p!=="light"&&p!=="dark"&&p!=="system")p=s.fallback;` +
    `if(p==="system")p=matchMedia(${JSON.stringify(DARK_QUERY)}).matches?"dark":"light";` +
    `var e=document.documentElement;if(s.dark)e.classList.toggle(s.dark,p==="dark");` +
    `if(s.light)e.classList.toggle(s.light,p==="light");e.style.colorScheme=p}catch(_){}})(${settings})`
  )
}
