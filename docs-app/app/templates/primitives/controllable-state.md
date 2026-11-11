# Controllable State

Every Joinery component with state lets you choose who owns it, as Radix's components do. Leave
it to the component, with an optional starting value, or own it yourself and let the component
ask you to change it. `controllable-state` is the helper that gives a component both.

<Example @name="controllable-state-disclosure" @title="Uncontrolled and controlled" />

## The pattern

A state named `open` reads three arguments:

| Argument        | What it does                                                                 |
| --------------- | ---------------------------------------------------------------------------- |
| `@open`         | Controls the state. While you pass anything but `undefined`, it is the state |
| `@defaultOpen`  | The starting value when you don't control it                                 |
| `@onOpenChange` | Called with each new value, controlled or not                                |

The same goes for `@value`, `@defaultValue` and `@onValueChange`, or `@checked`,
`@defaultChecked` and `@onCheckedChange`. Controlled, a change only happens when you pass the
new value back, so you can refuse one. The callback never fires for a value that didn't change.

## Usage

```gts
import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import { controllable, type ControllableArgs } from '@ember-joinery/primitives/controllable-state'

class Disclosure extends Component<{ Args: ControllableArgs<'open', boolean> }> {
  // reads @open, @defaultOpen and @onOpenChange; false when neither is given
  open = controllable(this, 'open', false)

  toggle = () => this.open.set(open => !open)

  <template>
    <button
      type="button"
      aria-expanded={{if this.open.value "true" "false"}}
      {{on "click" this.toggle}}
    >
      Details
    </button>
  </template>
}
```

For state that isn't a component's arguments, build a `ControllableState` from functions:

```ts
import { ControllableState } from '@ember-joinery/primitives/controllable-state'

const selected = new ControllableState({
  value: () => this.args.selected,
  defaultValue: () => this.args.defaultSelected,
  onChange: () => this.args.onSelectedChange,
  fallback: [],
})
```

## API

| Member         | What it is                                                                          |
| -------------- | ----------------------------------------------------------------------------------- |
| `value`        | The current value (tracked)                                                         |
| `set(next)`    | Asks for a new value, or an updater `(current) => next`                             |
| `isControlled` | Whether the caller passes a value now                                               |
| `controllable` | `controllable(component, name, fallback)`: a `ControllableState` from its arguments |

The default is read once, the first time the state is read. A component that switches between
controlled and uncontrolled during its life gets a warning, as in React.

`controllable`'s name must be one of the component's arguments, and the state takes that
argument's type: `controllable(this, 'opn', false)` doesn't compile.

## Testing

A component's harness drives it the same way whichever owns the state. Test both: leave the
state to the component and check it changes; control it and check the callback, and that a
refused change doesn't happen.
