# Testing

`@ember-joinery/test-support` has a harness for every Joinery component and primitive. A
harness finds its component by the `data-test-jn-*` attributes every component renders, reads
its state through ARIA, as a screen reader does, and drives it the way a user does: clicks,
keys, typing and the pointer. So a test written with harnesses checks the ARIA contract as it
goes, and keeps working when the markup inside a component changes.

Every example in this guide has a **Test** tab with the test that covers it. The Dialog's is a
page object, as below:

<Example @name="dialog-demo" @title="A dialog, and its test" />

## Installation

```bash
pnpm add --save-dev @ember-joinery/test-support
```

It works with `@ember/test-helpers` 5 and later, under QUnit or Vitest. The guide's tests, and
Joinery's own, end every test in an axe audit with
[ember-a11y-testing](https://github.com/ember-a11y/ember-a11y-testing)'s `a11yAudit()`; do the
same in yours.

## Harnesses

A harness drives one instance of a component. Make one with the component's `@name`, or with
nothing for the first instance in the test:

```ts
import { ButtonHarness, DialogHarness } from '@ember-joinery/test-support'

const dialog = new DialogHarness('edit-profile') // <Dialog @name="edit-profile">
const first = new ButtonHarness() // the first Button in the test
const third = new ButtonHarness({ index: 2 }) // by position
const save = new ButtonHarness({ name: 'save', within: dialog }) // inside another harness
const all = ButtonHarness.findAll() // one harness per Button in the test
```

A harness looks its component up every time you read it, so you can make it before the
component renders, and it stays valid across re-renders. `harness.element` is the component's
root and throws when it isn't rendered; `harness.exists` says whether it is, without throwing.
A harness pointed at another component fails with a message that says so: `the component
named "more" is a "menu"; this harness drives "disclosure"`.

Each component's page lists its harness's members under **Testing**, and the
[test-support reference](/reference/test-support.md) documents every harness, generated from
its types.

## Page objects

Describe a part of your app once, as a harness subclass. `@child` declares the components
inside it, and `static named` the `@name` it finds by default:

```ts
import { ButtonHarness, DialogHarness, InputHarness, child } from '@ember-joinery/test-support'

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
assert.false(dialog.isOpen)
assert.dom(dialog.trigger).isFocused() // focus went back
```

Each child is created the first time you read it and kept: `dialog.save` is the same object for
the life of `dialog`. Without a name, a child is the class's `static named`, or else the first
instance. A child's lookup is scoped to its parent: the parent's root, and every part the parent
owns wherever it is rendered (see [the top layer](#portals-and-the-top-layer)), at any depth.

With Ember's legacy decorators, write `declare` (TypeScript) or a bare field (JavaScript). With
standard decorators, write `accessor`. For a one-off lookup, `find()` makes a new harness on each
call, and `findAll()` one for each instance:

```ts
await dialog.find(ButtonHarness, 'cancel').click()
dialog.findAll(ButtonHarness).length // the buttons inside the dialog
```

A form built with [Formwright](/formwright/index.md) is described with Formwright's
`FormHarness` and Joinery's field harnesses, and `@form` puts it in a page object: see
[Formwright's Testing](/formwright/testing.md).

## Writing a harness

Extend `Harness`, name the component it drives in `static component` (its `data-test-jn`
value), read state through ARIA, and drive it as a user does:

```ts
import { click } from '@ember/test-helpers'
import { Harness } from '@ember-joinery/test-support'

export class DisclosureHarness extends Harness {
  static component = 'disclosure'

  get trigger(): HTMLButtonElement {
    return this.part<HTMLButtonElement>('trigger')
  }

  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  async toggle(): Promise<void> {
    await click(this.trigger)
  }
}
```

A harness that drives several components lists them all (`static component = ['sheet',
'dialog']`); the base `Harness` drives any component. Keep the constructor's signature in
subclasses: `@child`, `find()` and `findAll()` construct them. The
[Introduction](/getting-started/introduction.md)'s example has a small one.

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
so a component nested inside another keeps its own parts. A component that wraps your content
(a `Scroller`, a layout, a `Heading`) marks its root `data-test-jn-wrapper`: its harness scopes
lookups to it, but a part inside it belongs to the component around it.

## Portals and the top layer

Some parts render outside their component's root: a dialog's content in the top layer, a
popover's content portalled to the end of `<body>`. Those parts carry `data-test-jn-owner`, the
`id` of the root they belong to, and the harnesses follow it, so `dialog.part('content')` and any
child inside the content are found wherever it is rendered.

Overlays close on Escape or a press outside, through the dismiss stack, which listens for
`pointerdown` as Radix's does. `click()` sends no pointer events, so these drive them:

| Helper                         | What it does                                                                          |
| ------------------------------ | ------------------------------------------------------------------------------------- |
| `press(element, options?)`     | Presses an element as a pointer does: `pointerdown`, then `click()`, then `pointerup` |
| `pressOutside(target?, opts?)` | `press()` outside every layer: on `target`, or the test's root element                |
| `pressEscape(target?)`         | Presses Escape where focus is, or on `target`. Only the top layer closes              |
| `isInTopLayer(element)`        | Whether it is an open popover or a modal `<dialog>`                                   |
| `placementOf(element)`         | `{ side, align }`, where an anchored element ended up                                 |
| `setupAnchorFallback(hooks)`   | Forces the Floating UI fallback for a module's tests, as CI's second run does         |
| `hover(element, options?)`     | Rests the pointer on an element, as a mouse does, and waits for the delay it sets off |
| `unhover(element, options?)`   | Moves the pointer off an element, and waits as `hover()` does                         |
| `sendPointer(target, type, …)` | One real `PointerEvent`, for drags (a Resizable handle, a Scroll Area thumb)          |
| `setupTranslator(hooks, t)`    | Registers a translator as `translator:main` for a module's tests                      |
| `pseudoTranslator`             | A pseudo-locale translator, `⟦Ćĺóśé⟧`, that shows a string that skipped translation   |

`{ pointerType: 'touch' }` presses as a finger does. A harness that drags takes distances in CSS
pixels, since the test container is scaled.

## Keyboard and focus

A test can't press the real Tab key: `triggerKeyEvent(element, 'keydown', 'Tab')` sends the
event, but focus stays where it is. `tab()` does what the browser would:

```ts
import { pressKey, tab, tabOrder, typeKeys } from '@ember-joinery/test-support'

await tab() // to the next element in the tab order
await tab({ shift: true }) // to the previous one
tabOrder(form) // the elements Tab visits, in order
await pressKey('ArrowDown') // keydown and keyup on the focused element
await typeKeys('ba') // one key press per character, for typeahead
```

`tab()` follows a browser's rules: positive tabindexes first, then document order; one stop per
group of radio buttons; nothing hidden, inert or disabled. `pressKey` and `typeKeys` send key
events only: they don't type into inputs, which `fillIn` and `typeIn` do.

## Toasts, the colour scheme and routing

`setupToaster(hooks)` points `toast()` at each test's own Toaster, so a toast never reaches the
next test, and `ToasterHarness` reads them:

```ts
import { ToasterHarness, setupToaster } from '@ember-joinery/test-support'

module('saving', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('it says so', async function (assert) {
    await render(<template><SaveButton /><Toaster /></template>)
    await click('[data-test-save]')
    assert.strictEqual(new ToasterHarness().toast().title, 'Saved')
  })
})
```

`setupColorScheme(hooks, { system: 'light' })` isolates the machine's colour scheme and the
saved choice: `system.setSystem('dark')` switches the emulated OS, and `system.stored` is what is
saved (the [Dark mode](/getting-started/dark-mode.md) example's test uses it).
`setupRouting(owner, map)` gives a test its own routes, and `getRouter(owner)` the router service.

## Files, codes and observers

| Helper                              | What it does                                                               |
| ----------------------------------- | -------------------------------------------------------------------------- |
| `dropFiles(target, files)`          | Drops files on an element: `dragenter`, `dragover`, then `drop`            |
| `dragFilesOver(target, files)`      | Drags files over it, without dropping                                      |
| `dragFilesAway(target, files?)`     | Drags them away again                                                      |
| `fillOTP(code, within?)`            | Fills an `InputOTP` with a code, as ember-primitives' `fillOTP` does       |
| `scrollIntoView(target)`            | Scrolls an element into view as a user would, then waits for the observers |
| `waitForObservers()`                | Waits for what `viewport` and `onResize` report after a scroll or resize   |
| `findInShadow(root, selector)`, `…` | ember-primitives' shadow DOM helpers, for a `Shadowed`                     |

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
| `data-test-jn-wrapper`           | A root that wraps your content: the parts inside belong to the component around it    |

`selectors` builds CSS selectors for them, escaping the value, and `attributes` has their names:

```ts
import { attributes, selectors } from '@ember-joinery/test-support'

selectors.component('dialog', 'edit-profile') // '[data-test-jn="dialog"][data-test-jn-name="edit-profile"]'
selectors.part('trigger') // '[data-test-jn-part="trigger"]'
selectors.value('apple') // '[data-test-jn-value="apple"]'
attributes.owner // 'data-test-jn-owner'
```

## The add-ons' harnesses

Each opt-in add-on has its harnesses at its own `/test-support`, so the core packages never
import an add-on:

| Package                         | Harnesses, from `<package>/test-support`                                                   |
| ------------------------------- | ------------------------------------------------------------------------------------------ |
| `@ember-joinery/chart`          | `ChartHarness`, `PolarChartHarness`, `ChartTooltipHarness`, `ChartLegendHarness`           |
| `@ember-joinery/carousel`       | `CarouselHarness`                                                                          |
| `@ember-joinery/data-table`     | `DataTableHarness`                                                                         |
| `@ember-joinery/code-block`     | `CodeBlockHarness`                                                                         |
| `@ember-joinery/file-upload`    | `FileUploadHarness`, `FileUploadItemHarness`                                               |
| `@ember-joinery/tiptap`         | `RichTextEditorHarness`                                                                    |
| `@ember-joinery/power-calendar` | `PowerCalendarHarness`, `DatePickerHarness`                                                |
| `@ember-joinery/maskito`        | `MaskedInputHarness`, `PhoneInputHarness`                                                  |
| `@ember-joinery/formwright`     | A field harness for each control, on [Formwright's `FieldHarness`](/formwright/testing.md) |
