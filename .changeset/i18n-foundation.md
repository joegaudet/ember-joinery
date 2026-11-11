---
'@ember-joinery/primitives': minor
'@ember-joinery/test-support': minor
---

Joinery's built-in strings can be translated. `@ember-joinery/primitives/i18n` declares the msgid
contract's `Message` and `Translator`, with `format()` (English: a `plural` by `values.count`, and
`{name}` placeholders), `translate(context, message, values?)`, which uses the app's
`translator:main` when it registers one and English otherwise, and `t`, the same for a
template. Every string the primitives show is a message in `@ember-joinery/primitives/messages`
(`joinery.<component>.<name>`) and goes through the translator; an argument still wins. Joined
strings are one message each (`Value {index} of {count}`, `Today, {date}, selected`, `Notifications
{hotkey}`), so a translation orders the words. A calendar's and a combobox's `@locale` default to
the translator's. `defaultSliderThumbLabel` takes an optional context, and `CalendarState` an
optional third argument, the component, for the same. `@ember-joinery/test-support` adds
`setupTranslator(hooks, translator)` and `pseudoTranslator`, a pseudo-locale that wraps every
string it translates.
