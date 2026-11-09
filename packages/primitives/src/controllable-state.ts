import { tracked } from '@glimmer/tracking'
import { warn } from '@ember/debug'

/** The next value, or a function from the current value to the next. */
export type NextValue<T> = T | ((current: T) => T)

/** Where a `ControllableState` reads its inputs. Each is a function, so it reads them live. */
export interface ControllableStateOptions<T> {
  /** The controlled value. While it returns anything but `undefined`, the caller owns the state. */
  value: () => T | undefined
  /** The starting value when uncontrolled. Read once, the first time the state is read. */
  defaultValue?: () => T | undefined
  /** Called with every new value, controlled or not. */
  onChange?: () => ((value: T) => void) | undefined
  /** The value when there is neither a controlled value nor a default. */
  fallback: T
  /** What the state is called in warnings, such as `open`. */
  name?: string
}

/**
 * State that a component can own or hand to its caller, as Radix's components do. While the
 * caller passes a value (`@open`, `@value`), the state is that value, and `set()` only tells the
 * caller what it should become. Otherwise the state is the component's own, starting from the
 * default (`@defaultOpen`, `@defaultValue`). Either way, `onChange` (`@onOpenChange`,
 * `@onValueChange`) hears every change, and nothing is called when the value stays the same.
 *
 *   open = new ControllableState({
 *     value: () => this.args.open,
 *     defaultValue: () => this.args.defaultOpen,
 *     onChange: () => this.args.onOpenChange,
 *     fallback: false,
 *   })
 *
 *   this.open.value            // read it (tracked)
 *   this.open.set(true)        // ask for a change
 *   this.open.set(open => !open)
 *
 * `controllable(this, 'open', false)` builds the same thing from a component's arguments.
 */
export class ControllableState<T> {
  readonly #options: ControllableStateOptions<T>
  #seeded = false
  #seed: T
  #wasControlled: boolean | undefined

  /** The component's own value, once `set()` has changed it while uncontrolled. */
  @tracked private changed: { value: T } | undefined

  constructor(options: ControllableStateOptions<T>) {
    this.#options = options
    this.#seed = options.fallback
  }

  /** Whether the caller controls the state now (it passes a value that isn't `undefined`). */
  get isControlled(): boolean {
    return this.#controlled(this.#options.value())
  }

  /** The current value: the controlled value, or the component's own. */
  get value(): T {
    const controlled = this.#options.value()
    return this.#controlled(controlled) ? (controlled as T) : this.#own
  }

  /**
   * Asks for a new value. Uncontrolled, the state takes it. Controlled, the state stays as the
   * caller passes it, so the caller decides. `onChange` is called with the new value either way,
   * unless it equals the current one.
   */
  set(next: NextValue<T>): void {
    const current = this.value
    const value = typeof next === 'function' ? (next as (current: T) => T)(current) : next
    if (Object.is(value, current)) return
    if (!this.isControlled) this.changed = { value }
    this.#options.onChange?.()?.(value)
  }

  /** Whether a value counts as controlled, warning when that flips during the state's life. */
  #controlled(value: T | undefined): boolean {
    const controlled = value !== undefined
    const was = this.#wasControlled
    if (was !== undefined && was !== controlled) {
      const name = this.#options.name ?? 'value'
      warn(
        `Joinery: \`${name}\` changed from ${was ? 'controlled' : 'uncontrolled'} to ` +
          `${controlled ? 'controlled' : 'uncontrolled'}. Pass a value for the component's whole ` +
          `life or not at all, and use the default argument for a starting value.`,
        false,
        { id: 'ember-joinery.controllable-state' },
      )
    }
    this.#wasControlled = controlled
    return controlled
  }

  /** The uncontrolled value: the last one set, or else the default, read once. */
  get #own(): T {
    const changed = this.changed
    if (changed) return changed.value
    if (!this.#seeded) {
      this.#seeded = true
      const initial = this.#options.defaultValue?.()
      if (initial !== undefined) this.#seed = initial
    }
    return this.#seed
  }
}

type Capitalized<Name extends string> = Capitalize<Name>

/**
 * The arguments a controllable state named `Name` reads: `@<name>`, `@default<Name>` and
 * `@on<Name>Change`, as in `@open`, `@defaultOpen` and `@onOpenChange`.
 */
export type ControllableArgs<Name extends string, T> = {
  readonly [K in Name]?: T
} & {
  readonly [K in `default${Capitalized<Name>}`]?: T
} & {
  readonly [K in `on${Capitalized<Name>}Change`]?: (value: T) => void
}

function capitalize(name: string): string {
  return name.charAt(0).toUpperCase() + name.slice(1)
}

/**
 * A `ControllableState` read from a component's arguments, by the Radix naming pattern:
 * `controllable(this, 'open', false)` reads `@open`, `@defaultOpen` and `@onOpenChange`;
 * `controllable(this, 'value', '')` reads `@value`, `@defaultValue` and `@onValueChange`.
 *
 *   class Disclosure extends Component<{ Args: ControllableArgs<'open', boolean> }> {
 *     open = controllable(this, 'open', false)
 *     toggle = () => this.open.set(open => !open)
 *   }
 *
 * @param component anything with `args`, usually a Glimmer component
 * @param name the controlled argument's name
 * @param fallback the value when neither the argument nor its default is given
 */
export function controllable<T, Name extends string = string>(
  component: { readonly args: object },
  name: Name,
  fallback: T,
): ControllableState<T> {
  const args = () => component.args as Record<string, unknown>
  const key = capitalize(name)
  return new ControllableState<T>({
    name,
    value: () => args()[name] as T | undefined,
    defaultValue: () => args()[`default${key}`] as T | undefined,
    onChange: () => args()[`on${key}Change`] as ((value: T) => void) | undefined,
    fallback,
  })
}
