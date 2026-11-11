# Ids

ARIA ties elements together by `id`: a label to its input, a trigger to the content it
controls, a dialog to its title. `idFor` gives each of a component's parts an id of its own.

<Example @name="id-label" @title="A label and a hint" />

## Usage

`idFor(object, part?)` gives an object an id for its whole life, made the first time it is
asked for, and derives its parts' ids from it. A component names every part this way, and
lets your `@id` win:

```gts
import Component from '@glimmer/component'
import { idFor } from '@ember-joinery/primitives/id'

class Dialog extends Component {
  get contentId() {
    return this.args.id ?? idFor(this, 'content') // 'jn-7-content'
  }
  get titleId() {
    return idFor(this, 'title') // 'jn-7-title'
  }

  <template>
    <div role="dialog" id={{this.contentId}} aria-labelledby={{this.titleId}}>…</div>
  </template>
}
```

It works in a template too, as a helper: `id={{idFor this "title"}}`.

For a one-off id with no object to keep it, use Ember's built-in `uniqueId`, from
`@ember/helper`; Joinery doesn't add its own:

```gts
import { uniqueId } from '@ember/helper'

<template>
  {{#let (uniqueId) as |id|}}
    <label for={{id}}>Email</label>
    <input id={{id}} type="email" />
  {{/let}}
</template>
```

## API

| Function               | Returns                                                       |
| ---------------------- | ------------------------------------------------------------- |
| `idFor(object, part?)` | The object's own id, or `<its id>-<part>`; the same each call |

Ids are `jn-1`, `jn-2`… and unique on the page. Don't depend on their numbers: they follow the
order things render. Tests find parts by their `data-test-jn-part`, never by id.
