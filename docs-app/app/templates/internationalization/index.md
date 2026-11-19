# Internationalization

Joinery's own strings in your app's language.

A component shows a few strings of its own: a dialog's "Close", a calendar's "Go to the Next
Month", a slider thumb's "Minimum". They are English until your app registers a translator, and
then they are the translator's. Whatever i18n library the app already uses can be that
translator: gettext, [ember-intl](https://ember-intl.github.io/ember-intl/), i18next, Lingui
or one of your own, through msgid's adapters.

<Example @name="i18n-translator" @title="A slider's thumbs, named by the app's translator (see the Test tab)." />

An argument still wins over the translator: `@closeLabel`, `@label`, `@labels`,
`@getThumbLabel` and the like say exactly what they did before. With no translator and no
argument, the strings are the English they always were, so an app that doesn't translate
changes nothing. A language written right to left also needs its direction set:
see [RTL](/internationalization/rtl.md).

## A translator

A translator is an object with a `locale` and a `t` method, which Joinery's components look up
as `translator:main` on the app's owner:

```ts
import type { Message, Translator } from '@ember-joinery/primitives/i18n'

interface Translator {
  /** BCP 47 locale. Make it tracked, so a change of language re-renders. */
  readonly locale: string
  /** The translated, interpolated string; English when it has none. */
  t(message: Message, values?: Record<string, unknown>): string
}
```

Each string is a `Message`: a stable `id` (`joinery.calendar.nextMonth`), the English `message`
(the gettext msgid), with `{name}` placeholders, and sometimes a `plural`, a `context` and a
`description` for translators. Register the translator in an instance initializer:

```ts
// app/instance-initializers/translator.ts
import type ApplicationInstance from '@ember/application/instance'
import { translator } from '../translator'

export function initialize(owner: ApplicationInstance) {
  owner.register('translator:main', translator, { instantiate: false })
}

export default { initialize }
```

or ship it as a class in `app/translators/main.ts`, which the resolver finds and makes once, with
the owner, so `@service` works in it. A component that takes a `@locale` (a calendar's, a
combobox's) uses the translator's `locale` when it isn't given.

## msgid

[msgid](https://github.com/joegaudet/msgid) is the shared contract Joinery follows, and the
quickest way to a translator: it has an adapter for each of gettext, FormatJS (and so
ember-intl), i18next and Lingui, each a function that returns a `Translator`. Joinery doesn't
depend on it; your app installs it:

```sh
pnpm add msgid
```

Every adapter falls back to Joinery's English for a message its catalog hasn't got, or holds as
an empty string, so you can translate one string at a time.

## gettext

gettext is the first-class format. Every package exports its messages as data, from
`<package>/messages`:

```ts
import { messages } from '@ember-joinery/ember/messages'

messages.dialogClose // { id: 'joinery.dialog.close', message: 'Close' }
```

msgid's CLI turns those modules into a `.pot` template for translators, and their `.po` files
into the catalog `msgid/gettext` loads:

```sh
msgid pot @ember-joinery/ember/messages @ember-joinery/primitives/messages > joinery.pot
msginit -i joinery.pot -l fr -o fr.po   # or Poedit, Weblate, Crowdin…
msgid po2json fr.po --out app/translations/fr.json
```

```ts
// app/instance-initializers/translator.ts
import type ApplicationInstance from '@ember/application/instance'
import { gettext } from 'msgid/gettext'
import fr from '../translations/fr.json'

export function initialize(owner: ApplicationInstance) {
  // The locale is the .po file's Language header, as BCP 47.
  owner.register('translator:main', gettext(fr), { instantiate: false })
}

export default { initialize }
```

The adapter handles `Plural-Forms`, `msgctxt` and `msgid_plural`.

## ember-intl

`msgid/intl` wraps ember-intl's `intl` service (or any FormatJS `IntlShape`). It reads the
tracked `primaryLocale`, so `intl.setLocale()` re-renders Joinery's strings too:

```ts
// app/instance-initializers/translator.ts
import type ApplicationInstance from '@ember/application/instance'
import { intl } from 'msgid/intl'

export function initialize(owner: ApplicationInstance) {
  owner.register('translator:main', intl(owner.lookup('service:intl')), { instantiate: false })
}

export default { initialize }
```

The English, as ICU, is a source catalog for ember-intl's translations, under the same ids:

```sh
msgid icu @ember-joinery/ember/messages --out translations/en.json
```

Don't write this adapter yourself with `intl.exists(id)`: that is true for a translation that is
an empty string, which then renders blank. `msgid/intl` counts a message as translated only when
`getTranslation(id, primaryLocale)` has text, and falls back to English otherwise.

## i18next

```ts
import i18n from 'i18next'
import { i18next } from 'msgid/i18next'

export const translator = i18next(i18n) // its locale is i18n.language
```

It looks each message up by its `id` (`id_one` and `id_other` for a plural, `{{name}}` for a
placeholder), and `msgid i18next @ember-joinery/ember/messages --out locales/en/translation.json`
writes the English in that shape. i18next's language isn't tracked: re-render (or keep the
language in a tracked property of your own) when it changes.

## Lingui

```ts
import { i18n } from '@lingui/core'
import { lingui } from 'msgid/lingui'

export const translator = lingui(i18n) // its locale is i18n.locale
```

Load catalogs compiled by `lingui compile`: Lingui's production builds don't compile ICU at
runtime. The source catalog is msgid's ICU one, as for ember-intl.

## Without msgid

A translator over a catalog keyed by id is a few lines, with `format()` for the English it
hasn't got:

```ts
import { format, type Translator } from '@ember-joinery/primitives/i18n'
import catalog from './translations/fr.json' // { "joinery.toast.close": "Fermer", … }

export const translator: Translator = {
  locale: 'fr',
  t: (message, values) =>
    format({ ...message, message: catalog[message.id] || message.message }, values),
}
```

`format()` is Joinery's English: it picks `plural` when `values.count` isn't one, and fills in
each `{name}`.

## In your own components

`@ember-joinery/primitives/i18n` has what Joinery's own components use, for components of
yours that want the same translator (its [page under Primitives](/primitives/i18n.md) is the
reference):

```gts
import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import { t, translate, type Message } from '@ember-joinery/primitives/i18n'

const saved: Message = {
  id: 'app.editor.saved',
  message: 'Saved {count} file',
  plural: 'Saved {count} files',
}

export default class Editor extends Component<{ Args: { count: number } }> {
  get status(): string {
    return translate(this, saved, { count: this.args.count })
  }

  <template>
    <p>{{this.status}}</p>
    <p>{{t saved (hash count=@count)}}</p>
  </template>
}
```

`translate(context, message, values)` asks the context's owner for `translator:main`, and
formats the English itself without one; `t` is the same in a template (a template-only component
has no `this` to pass); `translator(context)` is the translator itself, or `undefined`.

## Testing

`setupTranslator(hooks, translator)` from `@ember-joinery/test-support` registers a translator
for each test in a module. `pseudoTranslator` is a pseudo-locale (`en-XA`) that accents every
string and wraps it, `⟦Ćĺóśé⟧`, so a string that skipped the translator stands out:

```ts
import { pseudoTranslator, setupTranslator } from '@ember-joinery/test-support'

module('my form, translated', function (hooks) {
  setupRenderingTest(hooks)
  setupTranslator(hooks, pseudoTranslator)
})
```

The harnesses find parts by their `data-test-jn-*` attributes, not their English names, so they
work the same in any language.
