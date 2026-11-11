---
'@ember-joinery/ember': minor
'@ember-joinery/primitives': minor
---

Every string `@ember-joinery/ember`'s components show goes through the app's translator: a
dialog's and a sheet's Close, the breadcrumb's and pagination's names and links, the combobox's
buttons, the sidebar's trigger, rail and mobile title, the spinner's Loading, the document file
drop's prompt, and the Command Dialog's, Message Scroller's and Questionnaire's, which are the
primitives' messages. They are in `@ember-joinery/ember/messages`; an argument still wins. The
Calendar's `@locale` defaults to the translator's. `paginationLinkAttributes` takes an optional
context for the translator, and a `part()` function's `this` is now its modifier, which has the
app's owner.
