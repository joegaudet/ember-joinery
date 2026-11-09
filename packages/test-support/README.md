# @ember-joinery/test-support

A test harness for every [Joinery](https://joegaudet.com/ember-joinery/) primitive and
component. Harnesses find components by their `data-test-jn-*` attributes, read state through
ARIA, and drive them the way a user does, with `@ember/test-helpers` (QUnit or Vitest).

> **Pre-release.** Nothing is published yet; see the
> [repository](https://github.com/joegaudet/ember-joinery#readme). The `Harness` base,
> `@child` and the selectors are here; each component's harness (`DialogHarness`,
> `ButtonHarness`…) lands with its component.

```bash
npm install --save-dev @ember-joinery/test-support
```

Full documentation: the Testing page of the guide at **https://joegaudet.com/ember-joinery/guide/**.

## Harnesses

A harness drives one instance of a component. Make one with the component's `@name`, or with
nothing for the first instance in the test:

```ts
const dialog = new DialogHarness('edit-profile') // <Dialog @name="edit-profile">
const first = new ButtonHarness() // the first Button in the test
const third = new ButtonHarness({ index: 2 }) // by position
const save = new ButtonHarness({ name: 'save', within: dialog }) // inside another harness
const all = ButtonHarness.findAll() // one harness per Button in the test
```

A harness looks its component up every time you read it, so you can make it before the
component renders, and it stays valid across re-renders. `harness.element` is the component's
root and throws when it isn't rendered; `harness.exists` says whether it is, without throwing.

## Page objects

Describe a part of your app once, as a harness subclass. `@child` declares the components
inside it, and `static named` the `@name` it finds by default:

```ts
import { DialogHarness, ButtonHarness, InputHarness, child } from '@ember-joinery/test-support'

class EditProfile extends DialogHarness {
  static named = 'edit-profile'

  @child(InputHarness, 'name') declare name: InputHarness // <Input @name="name">
  @child(ButtonHarness, 'save') declare save: ButtonHarness
  @child(ButtonHarness, { index: 1 }) declare second: ButtonHarness // by position
}

const dialog = new EditProfile()
await dialog.open()
await dialog.name.fillIn('Ada')
await dialog.save.click()
```

Each child is created the first time you read it and kept: `dialog.save` is the same object
for the life of `dialog`, and `dialog.child(ButtonHarness, 'save')` returns that object too.
Without a name, a child is the class's `static named`, or else the first instance. A child's
lookup is scoped to its parent: the parent's root, and every part the parent owns wherever
that part is rendered (see [Portals and the top layer](#portals-and-the-top-layer)). Children
are found at any depth, through other components in between.

With Ember's legacy decorators, write `declare` (TypeScript) or a bare field (JavaScript):
`@child(ButtonHarness, 'save') save;`. With standard decorators, write `accessor`:
`@child(ButtonHarness, 'save') accessor save!: ButtonHarness`.

For a one-off lookup, `find()` makes a new harness on each call, and `findAll()` makes one for
each instance:

```ts
await dialog.find(ButtonHarness, 'cancel').click()
dialog.findAll(ButtonHarness).length // the buttons inside the dialog
```

## Writing a component harness

Extend `Harness`, name the component it drives in `static component` (its `data-test-jn`
value), read state through ARIA, and drive it the way a user does:

```ts
import { click } from '@ember/test-helpers'
import { Harness } from '@ember-joinery/test-support'

export class DisclosureHarness extends Harness {
  static component = 'disclosure'

  get trigger(): HTMLButtonElement {
    return this.part<HTMLButtonElement>('trigger')
  }

  get content(): HTMLElement {
    return this.part('content')
  }

  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  async toggle(): Promise<void> {
    await click(this.trigger)
  }
}
```

A harness pointed at another component fails with a message that says so:
`the component named "more" is a "menu"; this harness drives "disclosure"`. A harness that
drives several components lists them all (`static component = ['sheet', 'dialog']`); the base
`Harness` drives any component. Keep the constructor's signature in subclasses: `@child`,
`find()` and `findAll()` construct them.

What `Harness` gives a subclass:

| Member                     | What it is                                                                                     |
| -------------------------- | ---------------------------------------------------------------------------------------------- |
| `element`                  | The component's root, looked up on every read. Throws when it isn't rendered                   |
| `exists`                   | Whether the component is rendered now                                                          |
| `part(name, value?)`       | One of the component's parts, or the one with that `data-test-jn-value`. Throws when it's none |
| `queryPart(name, value?)`  | The same, or `null`                                                                            |
| `parts(name)`              | All of the component's parts with that name, in document order                                 |
| `values(name)`             | The `data-test-jn-value` of each of those parts                                                |
| `child(Class, options?)`   | A child harness, created once and kept (what `@child` uses)                                    |
| `find(Class, options?)`    | A one-off child harness                                                                        |
| `findAll(Class, options?)` | A harness for every instance of `Class` inside this one                                        |
| `Class.findAll(options?)`  | A harness for every instance in the test                                                       |

`options` is a `@name`, or `{ name, index }`. A part belongs to the nearest component above it,
so a component nested inside another keeps its own parts: an accordion's `parts('item')` leaves
out the items of an accordion inside it. A component's root is never its own part.

## Portals and the top layer

Some parts render outside their component's root: a dialog's content in the top layer, a
popover's content portalled to the end of `<body>`. Those parts carry `data-test-jn-owner`, the
`id` of the root they belong to, and the harnesses follow it, so `dialog.part('content')` and
any child inside the content are found wherever the content is rendered, at any depth of
nesting.

## Selectors

Every Joinery component renders these attributes. They are public API: the harnesses use them,
and so can you.

| Attribute                        | On                                                                                    |
| -------------------------------- | ------------------------------------------------------------------------------------- |
| `data-test-jn="<component>"`     | The root of each component instance: `dialog`, `button`, `select`…                    |
| `data-test-jn-name="<@name>"`    | The same root, when the component was given `@name`                                   |
| `data-test-jn-part="<part>"`     | Each part of a component: `trigger`, `content`, `item`, `option`…                     |
| `data-test-jn-owner="<root id>"` | A part rendered outside its root (top layer or portal): the `id` of the root it's for |
| `data-test-jn-value="<key>"`     | An option, item, tab or toggle, by its key                                            |

`selectors` builds CSS selectors for them, escaping the value, and `attributes` has their names:

```ts
import { selectors, attributes } from '@ember-joinery/test-support'

selectors.component('dialog', 'edit-profile') // '[data-test-jn="dialog"][data-test-jn-name="edit-profile"]'
selectors.name('save') // '[data-test-jn-name="save"]'
selectors.part('trigger') // '[data-test-jn-part="trigger"]'
selectors.owner('ember12') // '[data-test-jn-owner="ember12"]'
selectors.value('apple') // '[data-test-jn-value="apple"]'
selectors.part() // '[data-test-jn-part]', any part

attributes.owner // 'data-test-jn-owner'
```

## The color scheme

Each test gets its own `ColorScheme` (from `@ember-joinery/primitives/color-scheme`), but not
its own operating system or `localStorage`. `setupColorScheme(hooks)` isolates both: before
each test it clears the saved choice and makes `matchMedia('(prefers-color-scheme: …)')`
answer from an emulated system preference; after each, it puts both back.

```ts
import { setupColorScheme } from '@ember-joinery/test-support'

module('dark mode', function (hooks) {
  setupRenderingTest(hooks)
  const system = setupColorScheme(hooks, { system: 'light' })

  test('it follows the system', async function (assert) {
    await render(<template><ModeToggle /></template>)
    system.setSystem('dark') // as switching the OS to dark mode would
    await settled()
    assert.dom(document.documentElement).hasClass('dark')
  })
})
```

`system.fromAnotherTab('dark')` saves a choice and sends the `storage` event, as another tab
would (`null` clears it), and `system.stored` is the saved choice. Pass `storageKey` when the
app configures its own.

## Keyboard and focus

A test can't press the real Tab key: `triggerKeyEvent(element, 'keydown', 'Tab')` sends the
event, but focus stays where it is. `tab()` does what the browser would: the focused element
gets the `keydown`, and unless the page prevents it, focus moves to the next element in the
tab order. That is how a test checks a focus trap or a roving tab stop.

```ts
import { pressKey, tab, tabOrder, typeKeys } from '@ember-joinery/test-support'

await tab() // to the next element in the tab order
await tab({ shift: true }) // to the previous one
tabOrder(form) // the elements Tab visits, in order
await pressKey('ArrowDown') // keydown and keyup on the focused element; true if prevented
await pressKey('Tab', { shiftKey: true })
await typeKeys('ba') // one key press per character, for typeahead
```

`tab()` follows a browser's rules: positive tabindexes first (lowest first), then document
order; one stop per group of native radio buttons (the checked one); nothing hidden, inert or
disabled. Past the last element, focus leaves the page, so nothing is focused afterwards. The
test runner's own controls (QUnit's toolbar, testem's frame) aren't in the order. `pressKey` and
`typeKeys` take `KeyboardEvent#key` values (`'a'`, `' '`, `'Home'`) and send key events only:
they don't type into inputs or press buttons, which `typeIn` and `click` do.

`RovingFocusGroupHarness` drives a `<RovingFocusGroup>` from
`@ember-joinery/primitives/roving-focus`: `items` and `ids`, `item(id)`, the `focused` item,
the `tabStop` Tab comes back to, `focus(id)` and `press(key)`.
