import { tracked } from '@glimmer/tracking'
import { warn } from '@ember/debug'
import { isDestroyed, isDestroying, registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import type { ComponentLike } from '@glint/template'
import { service } from '../service.ts'
import { isOwner } from '../store.ts'

// sonner 2.0.7's toast state (its `Observer` and `toast`), kept per owner instead of once per
// page, so each app instance, and so each test, has its own toasts.

/** A toast's id: the one you gave it, or a number counted per app. */
export type ToastId = number | string

/** What kind of toast it is, as sonner's `type`: it picks the icon and the rich colours. */
export type ToastType =
  'normal' | 'action' | 'success' | 'info' | 'warning' | 'error' | 'loading' | 'default'

/** Where a Toaster shows its toasts, as sonner's `position`. */
export type ToastPosition =
  'top-left' | 'top-right' | 'bottom-left' | 'bottom-right' | 'top-center' | 'bottom-center'

/** A side a toast can be swiped off towards, as sonner's `swipeDirections`. */
export type SwipeDirection = 'top' | 'right' | 'bottom' | 'left'

/** What a toast shows as its title or description: text, or a component of your own. */
export type ToastContent = string | ComponentLike

/**
 * Inline styles, as `{ property: value }` with CSS's own names (`'margin-top'`, or a custom
 * property such as `'--normal-bg'`). They are set through the CSSOM, so a strict Content
 * Security Policy doesn't block them as it would a `style` attribute.
 */
export type ToastStyle = Readonly<Record<string, string>>

/** A button a toast shows, as sonner's `action` and `cancel`. */
export interface ToastAction {
  /** The button's text. */
  label: string
  /**
   * Called when it is pressed. The toast then closes; for an action, unless the handler calls
   * `event.preventDefault()`.
   */
  onClick: (event: MouseEvent) => void
  /** Its inline styles. */
  actionButtonStyle?: ToastStyle
}

/** Extra classes for each part of a toast, as sonner's `classNames`. */
export interface ToastClassnames {
  toast?: string
  title?: string
  description?: string
  loader?: string
  closeButton?: string
  cancelButton?: string
  actionButton?: string
  success?: string
  error?: string
  info?: string
  warning?: string
  loading?: string
  default?: string
  content?: string
  icon?: string
}

/**
 * The icons a Toaster shows for each type, and on its close button: a component each (with no
 * arguments), or `null` for none. Unset ones are sonner's own.
 */
export interface ToastIcons {
  success?: ComponentLike | null
  info?: ComponentLike | null
  warning?: ComponentLike | null
  error?: ComponentLike | null
  loading?: ComponentLike | null
  close?: ComponentLike | null
}

/** What a custom toast's component (`toast.custom()`) is given. */
export interface CustomToastSignature {
  Args: {
    /** The toast's id. */
    id: ToastId
    /** Closes the toast. */
    dismiss: () => void
  }
}

/** A toast: what `toast()` was given, as sonner's `ToastT`. */
export interface ToastT {
  id: ToastId
  /** The Toaster that shows it: the one whose `@id` this is, or else the one without an `@id`. */
  toasterId?: string
  title?: ToastContent
  type?: ToastType
  /** Its icon, in place of its type's; `null` for none. */
  icon?: ComponentLike | null
  /** A custom toast's component (sonner's `jsx`), shown in place of the title, unstyled. */
  component?: ComponentLike<CustomToastSignature>
  /** Coloured by its type (success green, error red…). Default the Toaster's `@richColors`. */
  richColors?: boolean
  /** Dark on a light page, light on a dark one. */
  invert?: boolean
  /** Shows a close button. Default the Toaster's `@closeButton`. */
  closeButton?: boolean
  /** Whether the user can close it (swipe, its close button). Default `true`. */
  dismissible?: boolean
  description?: ToastContent
  /** How long it shows, in milliseconds. Default the Toaster's `@duration`, else 4000. */
  duration?: number
  /** Set once it has been dismissed, while it animates out. */
  delete?: boolean
  action?: ToastAction | ComponentLike
  cancel?: ToastAction | ComponentLike
  /** Called when it is closed, by its close button, a swipe or `toast.dismiss()`. */
  onDismiss?: (toast: ToastT) => void
  /** Called when its time runs out. */
  onAutoClose?: (toast: ToastT) => void
  /** The promise a `toast.promise()` toast waits for. */
  promise?: PromiseT
  cancelButtonStyle?: ToastStyle
  actionButtonStyle?: ToastStyle
  style?: ToastStyle
  /** Leaves out sonner's look (`data-styled="false"`), for styling it all yourself. */
  unstyled?: boolean
  className?: string
  classNames?: ToastClassnames
  descriptionClassName?: string
  /** Where it shows, in place of the Toaster's `@position`. */
  position?: ToastPosition
  /** Rendered as `data-testid`. */
  testId?: string
}

/** What `toast()` and its methods take, as sonner's `ExternalToast`. */
export type ExternalToast = Omit<
  ToastT,
  'id' | 'type' | 'title' | 'component' | 'delete' | 'promise'
> & {
  /** Its id: give one to update the toast later, by calling `toast()` again with it. */
  id?: ToastId
  toasterId?: string
}

/** A promise, or a function that starts one. */
export type PromiseT<Data = unknown> = Promise<Data> | (() => Promise<Data>)

/** A promise toast's message for an outcome, with more options for that toast. */
export interface PromiseExtendedResult extends ExternalToast {
  message: ToastContent
}

/** What a promise toast shows for an outcome: a message, or one made from the result. */
export type PromiseResult<Data = unknown> =
  | ToastContent
  | PromiseExtendedResult
  | ((
      data: Data,
    ) => ToastContent | PromiseExtendedResult | Promise<ToastContent | PromiseExtendedResult>)

/** What `toast.promise()` shows while it waits and when it settles, as sonner's. */
export type PromiseData<Data = unknown> = Omit<ExternalToast, 'description'> & {
  loading?: ToastContent
  success?: PromiseResult<Data>
  error?: PromiseResult<unknown>
  description?: PromiseResult<unknown>
  finally?: () => void | Promise<void>
}

/** What `toast.promise()` returns: the toast's id (when it showed one) and `unwrap()`. */
export interface PromiseToast<Data> {
  /** The loading toast's id, which the outcome replaces. `undefined` without `loading`. */
  id: ToastId | undefined
  /** The promise's own result, or its rejection. */
  unwrap: () => Promise<Data>
}

/** What `create` takes: a toast's options plus its message (its title). */
interface CreateData extends Omit<ToastT, 'id' | 'title'> {
  id?: ToastId
  message?: ToastContent
}

function isHttpResponse(data: unknown): data is { ok: boolean; status: number } {
  return (
    typeof data === 'object' &&
    data !== null &&
    'ok' in data &&
    typeof data.ok === 'boolean' &&
    'status' in data &&
    typeof data.status === 'number'
  )
}

/** A promise result's options, when it is the extended form `{ message, … }`. */
function isExtendedResult(value: unknown): value is PromiseExtendedResult {
  return typeof value === 'object' && value !== null && 'message' in value
}

async function resolveResult<Data>(
  result: PromiseResult<Data> | undefined,
  data: Data,
): Promise<ToastContent | PromiseExtendedResult | undefined> {
  return typeof result === 'function' && !isComponentClass(result)
    ? await (result as (data: Data) => ToastContent | PromiseExtendedResult)(data)
    : (result as ToastContent | PromiseExtendedResult | undefined)
}

/**
 * Whether a function is a component class rather than a result function: a class component
 * is constructed, so it has a prototype other than a plain function's, with its own methods.
 */
function isComponentClass(value: unknown): boolean {
  return typeof value === 'function' && /^class[\s{]/.test(Function.prototype.toString.call(value))
}

/**
 * The toasts of one app (one owner): what is shown, what has been, and sonner's `toast` methods
 * to make and close them. Each app instance has one, through `service`, so tests don't share
 * toasts. `toast()` reaches the app's from anywhere; `toastsFor(this)` from anything with an
 * owner.
 *
 *   toastsFor(this).success('Saved')
 *   toastsFor(this).toasts // what the Toasters show, newest first
 */
export class Toasts {
  /** The toasts the Toasters show (or are taking away), newest first. */
  @tracked toasts: readonly ToastT[] = []

  /** Every toast made, oldest first, each as last updated (sonner's `getHistory()`). */
  readonly history: ToastT[] = []

  readonly #dismissed = new Set<ToastId>()
  #counter = 1
  #destroyed = false

  constructor() {
    registerDestructor(this, () => (this.#destroyed = true))
  }

  /**
   * Makes a toast, or updates the one with the same `id`. Returns its id. The methods below are
   * shorthands for it.
   */
  create = (data: CreateData): ToastId => {
    const { message, ...rest } = data
    const id =
      typeof data.id === 'number' || (typeof data.id === 'string' && data.id.length > 0)
        ? data.id
        : this.#counter++
    if (this.#destroyed) return id
    const dismissible = data.dismissible === undefined ? true : data.dismissible
    this.#dismissed.delete(id)

    const index = this.history.findIndex(toast => toast.id === id)
    if (index !== -1) {
      const updated: ToastT = { ...this.history[index]!, ...rest, id, dismissible, title: message }
      this.history[index] = updated
    } else {
      this.history.push({ title: message, ...rest, dismissible, id })
    }

    const shown = this.toasts.findIndex(toast => toast.id === id)
    if (shown !== -1) {
      const toasts = [...this.toasts]
      toasts[shown] = { ...toasts[shown]!, ...rest, id, dismissible, title: message }
      this.toasts = toasts
    } else {
      this.toasts = [{ title: message, ...rest, dismissible, id }, ...this.toasts]
    }
    return id
  }

  /** A toast with only the message and the options you give. */
  message = (message: ToastContent, data?: ExternalToast): ToastId =>
    this.create({ ...data, message })

  /** A success toast: a check icon, and green with rich colours. */
  success = (message: ToastContent, data?: ExternalToast): ToastId =>
    this.create({ ...data, type: 'success', message })

  /** An info toast. */
  info = (message: ToastContent, data?: ExternalToast): ToastId =>
    this.create({ ...data, type: 'info', message })

  /** A warning toast. */
  warning = (message: ToastContent, data?: ExternalToast): ToastId =>
    this.create({ ...data, type: 'warning', message })

  /** An error toast. */
  error = (message: ToastContent, data?: ExternalToast): ToastId =>
    this.create({ ...data, type: 'error', message })

  /** A loading toast, with a spinner, that stays until you update or dismiss it. */
  loading = (message: ToastContent, data?: ExternalToast): ToastId =>
    this.create({ ...data, type: 'loading', message })

  /**
   * A toast drawn by a component of your own, with none of sonner's look (sonner's
   * `toast.custom()`). The component gets `@id` and `@dismiss`.
   */
  custom = (component: ComponentLike<CustomToastSignature>, data?: ExternalToast): ToastId => {
    const id = data?.id || this.#counter++
    return this.create({ ...data, component, id })
  }

  /**
   * A toast that follows a promise: `loading` while it waits, then `success` (given the result)
   * or `error` (given the reason). A resolved `Response` that isn't `ok`, or an `Error`, counts
   * as a failure.
   *
   *   toast.promise(save(), {
   *     loading: 'Saving…',
   *     success: data => `${data.name} has been saved`,
   *     error: 'Could not save',
   *   })
   */
  promise = <Data>(promise: PromiseT<Data>, data?: PromiseData<Data>): PromiseToast<Data> => {
    if (!data) return { id: undefined, unwrap: () => Promise.resolve(promise as never) }
    let id: ToastId | undefined
    if (data.loading !== undefined) {
      id = this.create({
        ...data,
        promise,
        type: 'loading',
        message: data.loading,
        description: typeof data.description !== 'function' ? data.description : undefined,
      } as CreateData)
    }
    const started = Promise.resolve(typeof promise === 'function' ? promise() : promise)
    let shouldDismiss = id !== undefined
    let result: ['resolve', Data] | ['reject', unknown] | undefined

    const show = async (
      type: 'success' | 'error',
      outcome: PromiseResult<never> | undefined,
      value: unknown,
    ) => {
      const shown = await resolveResult(outcome as PromiseResult<unknown>, value)
      const description = await resolveResult(data.description, value)
      const settings = isExtendedResult(shown) ? shown : { message: shown }
      this.create({ id, type, description: description as ToastContent, ...settings })
    }

    const original = started
      .then(async response => {
        result = ['resolve', response]
        if (isHttpResponse(response) && !response.ok) {
          shouldDismiss = false
          await show('error', data.error as never, `HTTP error! status: ${response.status}`)
        } else if (response instanceof Error) {
          shouldDismiss = false
          await show('error', data.error as never, response)
        } else if (data.success !== undefined) {
          shouldDismiss = false
          await show('success', data.success as never, response)
        }
      })
      .catch(async (error: unknown) => {
        result = ['reject', error]
        if (data.error !== undefined) {
          shouldDismiss = false
          await show('error', data.error as never, error)
        }
      })
      .finally(() => {
        if (shouldDismiss) {
          // Still loading, and nothing will replace it: take it away.
          this.dismiss(id)
          id = undefined
        }
        void data.finally?.()
      })

    const unwrap = () =>
      new Promise<Data>((resolve, reject) =>
        original
          .then(() => (result?.[0] === 'reject' ? reject(result[1]) : resolve(result?.[1] as Data)))
          .catch(reject),
      )
    return { id, unwrap }
  }

  /**
   * Closes the toast with this id, or every toast without one. It animates out, and its
   * `onDismiss` is called.
   */
  dismiss = (id?: ToastId): ToastId | undefined => {
    if (this.#destroyed) return id
    if (id !== undefined) {
      this.#dismissed.add(id)
      this.#markDeleted(toast => toast.id === id)
    } else {
      for (const toast of this.toasts) this.#dismissed.add(toast.id)
      this.#markDeleted(() => true)
    }
    return id
  }

  /** Every toast made, as sonner's `toast.getHistory()`. */
  getHistory = (): ToastT[] => [...this.history]

  /** The toasts made that haven't been dismissed, as sonner's `toast.getToasts()`. */
  getToasts = (): ToastT[] => this.history.filter(toast => !this.#dismissed.has(toast.id))

  /**
   * Takes a toast off the list once it has animated out. A Toaster calls it; to close a toast,
   * call `dismiss`.
   */
  remove(toast: ToastT): void {
    if (this.#destroyed) return
    const shown = this.toasts.find(each => each.id === toast.id)
    if (!shown?.delete) this.#dismissed.add(toast.id)
    this.toasts = this.toasts.filter(each => each.id !== toast.id)
  }

  #markDeleted(matches: (toast: ToastT) => boolean): void {
    if (!this.toasts.some(matches)) return
    this.toasts = this.toasts.map(toast => (matches(toast) ? { ...toast, delete: true } : toast))
  }
}

/** The owners whose Toasters are rendered, oldest first: `toast()` uses the newest. */
const bound: Owner[] = []

const GLOBAL = 'JOINERY_TOAST_OWNER'

const alive = (owner: Owner) => !isDestroying(owner) && !isDestroyed(owner)

/**
 * Points `toast()` at an owner's toasts while its Toaster is rendered: the Toaster does it
 * itself. Returns the function that takes it back.
 */
export function bindToasts(owner: Owner): () => void {
  bound.push(owner)
  let active = true
  return () => {
    if (!active) return
    active = false
    const index = bound.lastIndexOf(owner)
    if (index !== -1) bound.splice(index, 1)
  }
}

/**
 * The owner `toast()` uses now: `globalThis.JOINERY_TOAST_OWNER` (which test-support's
 * `setupToaster(hooks)` sets to each test's owner), else the owner of the newest rendered
 * Toaster.
 */
export function toastOwner(): Owner | undefined {
  const global = (globalThis as Record<string, unknown>)[GLOBAL]
  if (isOwner(global) && alive(global)) return global
  for (let index = bound.length - 1; index >= 0; index--) {
    const owner = bound[index]!
    if (alive(owner)) return owner
  }
  return undefined
}

/**
 * The toasts of the app `context` belongs to (anything with an owner, or the owner itself):
 * the same `Toasts` its Toasters show. sonner's `useSonner()` is `toastsFor(this).toasts`.
 *
 *   toastsFor(this).success('Saved')
 */
export function toastsFor(context: object): Toasts {
  return service(context, Toasts)
}

/** Toasts for when no Toaster is rendered: nothing shows them, as with sonner. */
let detached: Toasts | undefined

function current(caller: string): Toasts {
  const owner = toastOwner()
  if (owner) return toastsFor(owner)
  warn(
    `Joinery: ${caller} found no Toaster to show the toast. Render a <Toaster> once, in your ` +
      'application template; in tests, call setupToaster(hooks) or render a <Toaster>.',
    false,
    { id: 'joinery.toast.no-toaster' },
  )
  return (detached ??= new Toasts())
}

type Shorthand = (message: ToastContent, data?: ExternalToast) => ToastId

/** sonner's `toast`: a function, with a method for each kind of toast. */
export interface ToastFunction {
  /** Shows a toast with this message (its title). Returns its id. */
  (message: ToastContent, data?: ExternalToast): ToastId
  success: Shorthand
  info: Shorthand
  warning: Shorthand
  error: Shorthand
  message: Shorthand
  loading: Shorthand
  custom: (component: ComponentLike<CustomToastSignature>, data?: ExternalToast) => ToastId
  promise: <Data>(promise: PromiseT<Data>, data?: PromiseData<Data>) => PromiseToast<Data>
  dismiss: (id?: ToastId) => ToastId | undefined
  getHistory: () => ToastT[]
  getToasts: () => ToastT[]
}

/**
 * Shows a toast, from anywhere: a component, a route, a plain function. It is sonner's `toast`,
 * with the same methods (`toast.success()`, `toast.promise()`, `toast.dismiss()`…), and it
 * shows in the app's `<Toaster>`:
 *
 *   import { toast } from '@ember-joinery/primitives/toast'
 *
 *   toast('Event has been created', { description: 'Sunday at 9:00 AM' })
 *   toast.success('Saved')
 *   toast.promise(save(), { loading: 'Saving…', success: 'Saved', error: 'Failed' })
 *
 * The toasts belong to an owner (one app, or one test), not to the page: `toast()` uses the
 * app whose `<Toaster>` is rendered (in tests, the test's, with `setupToaster(hooks)`), and
 * `toastsFor(this)` names one.
 */
export const toast: ToastFunction = Object.assign(
  (message: ToastContent, data?: ExternalToast) => current('toast()').message(message, data),
  {
    success: (message: ToastContent, data?: ExternalToast) =>
      current('toast.success()').success(message, data),
    info: (message: ToastContent, data?: ExternalToast) =>
      current('toast.info()').info(message, data),
    warning: (message: ToastContent, data?: ExternalToast) =>
      current('toast.warning()').warning(message, data),
    error: (message: ToastContent, data?: ExternalToast) =>
      current('toast.error()').error(message, data),
    message: (message: ToastContent, data?: ExternalToast) =>
      current('toast.message()').message(message, data),
    loading: (message: ToastContent, data?: ExternalToast) =>
      current('toast.loading()').loading(message, data),
    custom: (component: ComponentLike<CustomToastSignature>, data?: ExternalToast) =>
      current('toast.custom()').custom(component, data),
    promise: <Data>(promise: PromiseT<Data>, data?: PromiseData<Data>) =>
      current('toast.promise()').promise(promise, data),
    dismiss: (id?: ToastId) => current('toast.dismiss()').dismiss(id),
    getHistory: () => current('toast.getHistory()').getHistory(),
    getToasts: () => current('toast.getToasts()').getToasts(),
  },
)
