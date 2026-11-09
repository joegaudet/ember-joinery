# Ids

ARIA ties elements together by `id`: a label to its input, a trigger to the content it
controls, a dialog to its title. `@ember-joinery/primitives/id` makes them.

<Example @name="id-label" @title="A label and a hint" />

## Usage

`uniqueId()` makes a new id each time it is called, in JavaScript or as a helper:

```gts
import { uniqueId } from '@ember-joinery/primitives/id'

<template>
  {{#let (uniqueId) as |id|}}
    <label for={{id}}>Email</label>
    <input id={{id}} type="email" />
  {{/let}}
</template>
```

`idFor(object, part?)` gives an object an id for its whole life, made the first time it is
asked for, and derives its parts' ids from it. A component names every part this way, and
lets your `@id` win:

```ts
import { idFor } from '@ember-joinery/primitives/id'

class Dialog extends Component {
  get contentId() {
    return this.args.id ?? idFor(this, 'content') // 'jn-7-content'
  }
  get titleId() {
    return idFor(this, 'title') // 'jn-7-title'
  }
}
```

## API

| Function               | Returns                                                       |
| ---------------------- | ------------------------------------------------------------- |
| `uniqueId(prefix?)`    | A new id: `jn-1`, `jn-2`… (`prefix` replaces `jn`)            |
| `idFor(object, part?)` | The object's own id, or `<its id>-<part>`; the same each call |

Ids are unique on the page. Don't depend on their numbers: they follow the order things render.
