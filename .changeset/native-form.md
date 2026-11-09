---
'@ember-joinery/primitives': minor
'@ember-joinery/test-support': minor
---

`NativeForm` is ember-primitives' Form, renamed so it can't clash with Formwright's `<Form>`: a
native `<form>` whose `@onChange` hears its data as an object on every input and on submit.
`dataFromEvent` reads the same object out of any form's event, converting numbers, dates,
checkboxes, radios, selects and files as form-data-utils does, and takes Joinery's button
controls in through their hidden inputs. `@ember-joinery/test-support` adds
`NativeFormHarness`.
