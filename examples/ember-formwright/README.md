# ember-formwright

Joinery's inputs as [Formwright](https://joegaudet.com/ember-formwright/) controls, in a Vite
(Embroider) Ember app: `@ember-joinery/formwright`'s `setupJoineryForms()` called once from
`app/app.js`, and a Formwright `<Form>` whose fields render Joinery's Input, Select, Switch and
Checkbox in shadcn's Field layout. Its smoke test describes the form with Formwright's
`FormHarness` and Joinery's field harnesses, declares it inside a `CardHarness` with `@form`,
and submits it. CI builds it and runs its smoke test.

```bash
pnpm --filter ember-formwright test
```
