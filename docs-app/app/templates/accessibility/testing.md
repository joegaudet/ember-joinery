# Testing

Check in your app's tests what Joinery checks in its own.

`@ember-joinery/test-support`'s harnesses read a component's state through ARIA, as a screen
reader does: a dialog is open when its trigger says `aria-expanded="true"`, an option is chosen
when it says `aria-selected`. So a test written with them checks the ARIA contract as it goes,
and fails when what assistive technology hears stops matching what the test drove. The
harnesses drive the keyboard as a user does too, with `tab()`, `pressKey()` and `pressEscape()`,
so a test can follow a component's keyboard pattern and where focus goes.

End each test in an axe audit with
[ember-a11y-testing](https://github.com/ember-a11y/ember-a11y-testing), as Joinery's own tests
do:

```bash
pnpm add --save-dev ember-a11y-testing
```

```ts
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DialogHarness } from '@ember-joinery/test-support'

test('the dialog opens and closes', async function (assert) {
  // … render it
  const dialog = new DialogHarness('edit-profile')
  await dialog.open()
  await a11yAudit()
  await dialog.close()
  assert.dom(dialog.trigger).isFocused() // focus went back
})
```

Audit while the component is open as well as closed: a dialog's content, a menu's items and a
popover's panel are only on the page while they show. `a11yAudit()` takes axe's options to turn
a rule off where your page can't meet it; give the reason beside it.

[Testing](/getting-started/testing.md) has the harnesses, page objects and the keyboard and focus
helpers.
