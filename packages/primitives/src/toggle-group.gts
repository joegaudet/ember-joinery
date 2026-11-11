import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import { registerDestructor } from '@ember/destroyable'
import Modifier from 'ember-modifier'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import { ControllableState } from './controllable-state.ts'
import type { Direction } from './direction.gts'
import { part, type PartModifier, type PartSpec } from './part.ts'
import { RovingFocus, type Orientation, type RovingFocusItemState } from './roving-focus.gts'

/** Whether one item can be pressed at a time (`single`), or any number (`multiple`). */
export type ToggleGroupType = 'single' | 'multiple'

/**
 * A toggle group's value, by its type: the pressed item's value (`''` for none) for `single`,
 * and the pressed items' values for `multiple`.
 */
export type ToggleGroupValue<T extends ToggleGroupType> = T extends 'multiple' ? string[] : string

/** What a toggle group's item takes, as `<g.Item>` or the `g.item` modifier. */
export interface ToggleGroupItemOptions {
  /** The item's value, unique in its group. */
  value: string
  /** Whether it can't be pressed (the whole group's `@disabled` does the same). */
  disabled?: boolean
}

/** Where a `ToggleGroupState` reads its settings. Each is a function, so it reads them live. */
export interface ToggleGroupOptions {
  type: () => ToggleGroupType
  /** The controlled value. */
  value?: () => string | string[] | undefined
  /** The first value, when uncontrolled. */
  defaultValue?: () => string | string[] | undefined
  /** Called with each new value. */
  onValueChange?: () => ((value: never) => void) | undefined
  /** Whether no item can be pressed. */
  disabled?: () => boolean | undefined
  /** Whether the items share one tab stop, with the arrow keys moving between them. Default `true`. */
  rovingFocus?: () => boolean | undefined
  /** Which arrow keys move focus. Unset: all four. */
  orientation?: () => Orientation | undefined
  /** The text direction, when the document's shouldn't decide. */
  dir?: () => Direction | undefined
  /** Whether the arrows wrap round. Default `true`. */
  loop?: () => boolean | undefined
}

/**
 * A toggle group's state and behaviour, as Radix's `ToggleGroup` has them: the value, and the
 * roving focus its items share. `<ToggleGroup>` is built on it, and so is the styled one, which
 * adds its own classes to the same item behaviour through `itemSpec()`.
 *
 *   group = new ToggleGroupState({ type: () => 'multiple', value: () => this.args.value, … })
 *   <div role="group" {{this.group.group}}>
 *     <button type="button" {{this.group.item value="bold"}}>Bold</button>
 *   </div>
 */
export class ToggleGroupState {
  readonly #options: ToggleGroupOptions
  readonly state: ControllableState<string | string[]>
  readonly roving: RovingFocus
  /** Each item the roving focus knows, by value. */
  readonly #items = new Map<string, RovingFocusItemState>()

  /** Put it on the group's element. */
  readonly group: typeof Modifier<{ Element: HTMLElement }>
  /** Put it on each item's element: `{{group.item value="bold"}}`. */
  readonly item: PartModifier<HTMLElement, ToggleGroupItemOptions>

  constructor(options: ToggleGroupOptions) {
    this.#options = options
    this.state = new ControllableState<string | string[]>({
      name: 'value',
      value: () => options.value?.(),
      defaultValue: () => options.defaultValue?.() ?? (this.type === 'multiple' ? [] : ''),
      onChange: () => options.onValueChange?.() as ((value: string | string[]) => void) | undefined,
      fallback: '',
    })
    this.roving = new RovingFocus({
      orientation: () => options.orientation?.(),
      dir: () => options.dir?.(),
      loop: () => options.loop?.() ?? true,
    })
    this.group = groupModifier(this)
    this.item = part<HTMLElement, ToggleGroupItemOptions>(named => this.itemSpec(named))
  }

  get type(): ToggleGroupType {
    return this.#options.type()
  }

  get isDisabled(): boolean {
    return this.#options.disabled?.() ?? false
  }

  get hasRovingFocus(): boolean {
    return this.#options.rovingFocus?.() ?? true
  }

  /** The values pressed now. */
  get values(): string[] {
    const value = this.state.value
    if (Array.isArray(value)) return value
    return value ? [value] : []
  }

  /** The value, as the group's type has it: a string for `single`, an array for `multiple`. */
  get value(): string | string[] {
    return this.type === 'multiple' ? this.values : (this.values[0] ?? '')
  }

  isPressed = (value: string): boolean => this.values.includes(value)

  /** Presses an item, or lets it go, as a click on it does. */
  setPressed = (value: string, pressed: boolean): void => {
    if (this.type === 'multiple') {
      const values = this.values
      this.state.set(pressed ? [...values, value] : values.filter(other => other !== value))
    } else {
      this.state.set(pressed ? value : '')
    }
  }

  /**
   * What an item puts on its element, as a `part()` spec: Radix's `ToggleGroupItem`. A
   * `multiple` group's items are toggles (`aria-pressed`); a `single` group's are radios
   * (`role="radio"` and `aria-checked`). Each has `data-state` and `data-disabled`, the group's
   * roving tab stop, and a click that presses it or lets it go.
   */
  itemSpec = ({ value, disabled: own }: ToggleGroupItemOptions): PartSpec => {
    const pressed = this.isPressed(value)
    const disabled = this.isDisabled || (own ?? false)
    const single = this.type === 'single'
    const roving = this.hasRovingFocus
    const item = this.#items.get(value)
    if (item) {
      const focusableChanged = item.focusable !== !disabled
      item.focusable = !disabled
      item.active = pressed
      if (focusableChanged) this.roving.changed()
    }
    return {
      attributes: {
        role: single ? 'radio' : undefined,
        'aria-checked': single ? String(pressed) : undefined,
        'aria-pressed': single ? undefined : String(pressed),
        'data-state': pressed ? 'on' : 'off',
        'data-disabled': disabled,
        disabled,
        tabindex: roving ? (this.roving.currentTabStopId === value ? '0' : '-1') : undefined,
        'data-orientation': roving ? this.roving.orientation : undefined,
        'data-test-jn-part': 'item',
        'data-test-jn-value': value,
      },
      on: {
        click: () => {
          if (!this.isDisabled && !own) this.setPressed(value, !this.isPressed(value))
        },
        ...(roving && {
          mousedown: (event: MouseEvent) => {
            const state = this.#items.get(value)
            if (state) this.roving.onItemMouseDown(event, state)
          },
          focusin: () => this.roving.onItemFocus(value),
          keydown: (event: KeyboardEvent) => {
            const state = this.#items.get(value)
            if (state) this.roving.onItemKeyDown(event, state)
          },
        }),
      },
      element: element => {
        if (!roving) return
        const state: RovingFocusItemState = {
          element,
          id: value,
          focusable: !disabled,
          active: pressed,
        }
        this.#items.set(value, state)
        const unregister = this.roving.register(state)
        return () => {
          unregister()
          if (this.#items.get(value) === state) this.#items.delete(value)
        }
      },
    }
  }
}

/** The group's roving focus, when it has one: `RovingFocus#group`, or nothing. */
function groupModifier(group: ToggleGroupState): typeof Modifier<{ Element: HTMLElement }> {
  return class ToggleGroupModifier extends Modifier<{ Element: HTMLElement }> {
    #installed = false

    override modify(element: HTMLElement): void {
      if (!group.hasRovingFocus) return
      const roving = group.roving
      if (this.#installed) return roving.updateGroup(element)
      this.#installed = true
      const tabindex = element.getAttribute('tabindex')
      roving.updateGroup(element)
      const uninstall = roving.installGroup(element)
      registerDestructor(this, () => {
        uninstall()
        if (tabindex === null) element.removeAttribute('tabindex')
        else element.setAttribute('tabindex', tabindex)
      })
    }
  }
}

export interface ToggleGroupItemSignature {
  Args: {
    /** The item's value, unique in its group. */
    value: string
    /** Whether it can't be pressed. */
    disabled?: boolean
    /** The tag to render. Default `button`. */
    as?: TagName
    /** @internal Bound by the group. */
    group: ToggleGroupState
  }
  Blocks: {
    /** Its content, given whether it is pressed. */
    default: [pressed: boolean]
  }
  Element: HTMLButtonElement
}

/** One of a toggle group's items, yielded as `g.Item`: a `<button type="button">`. */
export const ToggleGroupItem: TOC<ToggleGroupItemSignature> = <template>
  <As
    @as={{@as}}
    @tag="button"
    type="button"
    ...attributes
    {{@group.item value=@value disabled=@disabled}}
  >{{yield (@group.isPressed @value)}}</As>
</template>

/** What `<ToggleGroup>` yields. */
export interface ToggleGroupYield<T extends ToggleGroupType> {
  /** An item: `<g.Item @value="bold" aria-label="Bold">`. */
  Item: WithBoundArgs<typeof ToggleGroupItem, 'group'>
  /** An item, as a modifier on your own element: `<button type="button" {{g.item value="bold"}}>`. */
  item: ToggleGroupState['item']
  /** The value: the pressed item's (`''` for none), or the pressed items'. */
  value: ToggleGroupValue<T>
  /** Whether an item is pressed: `(g.isPressed "bold")`. */
  isPressed: (value: string) => boolean
}

export interface ToggleGroupSignature<T extends ToggleGroupType> {
  Args: {
    /** `single`: one item pressed at a time, or none. `multiple`: any number. */
    type: T
    /** The controlled value. */
    value?: ToggleGroupValue<T>
    /** The first value, when uncontrolled. */
    defaultValue?: ToggleGroupValue<T>
    /** Called with each new value. */
    onValueChange?: (value: ToggleGroupValue<T>) => void
    /** Whether no item can be pressed. */
    disabled?: boolean
    /** Whether Tab stops once, with the arrow keys moving between items. Default `true`. */
    rovingFocus?: boolean
    /** Which arrow keys move focus: left and right, up and down, or (unset) all four. */
    orientation?: Orientation
    /** The text direction; by default the document's, from the nearest `dir`. */
    dir?: Direction
    /** Whether the arrows wrap round from the last item to the first. Default `true`. */
    loop?: boolean
    /** The tag to render. Default `div`. */
    as?: TagName
    /** Its name, for `ToggleGroupHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [ToggleGroupYield<T>] }
  Element: HTMLDivElement
}

/**
 * A set of two-state buttons that can be toggled on or off: Radix's `ToggleGroup`, headless,
 * which also covers ember-primitives' (`@type="multiple"` for its `multi`). It is a
 * `role="group"` whose items share one tab stop, with the arrow keys moving between them:
 *
 *   <ToggleGroup @type="multiple" @defaultValue={{array "bold"}} aria-label="Format" as |g|>
 *     <g.Item @value="bold" aria-label="Bold">B</g.Item>
 *     <g.Item @value="italic" aria-label="Italic">I</g.Item>
 *   </ToggleGroup>
 *
 * In a `single` group, pressing an item lets go of the one pressed before, and pressing it
 * again lets it go too (the value is then `''`).
 */
export class ToggleGroup<T extends ToggleGroupType = 'single'> extends Component<
  ToggleGroupSignature<T>
> {
  group = new ToggleGroupState({
    type: () => this.args.type,
    value: () => this.args.value,
    defaultValue: () => this.args.defaultValue,
    onValueChange: () => this.args.onValueChange as ((value: never) => void) | undefined,
    disabled: () => this.args.disabled,
    rovingFocus: () => this.args.rovingFocus,
    orientation: () => this.args.orientation,
    dir: () => this.args.dir,
    loop: () => this.args.loop,
  })

  get value(): ToggleGroupValue<T> {
    return this.group.value as ToggleGroupValue<T>
  }

  <template>
    <As
      @as={{@as}}
      @tag="div"
      role="group"
      dir={{@dir}}
      data-orientation={{@orientation}}
      data-test-jn="toggle-group"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.group.group}}
    >
      {{yield
        (hash
          Item=(component ToggleGroupItem group=this.group)
          item=this.group.item
          value=this.value
          isPressed=this.group.isPressed
        )
      }}
    </As>
  </template>
}

export default ToggleGroup
