# Store

One instance of a class per context: per component, per route, or per any other object. Repeat
calls return the same instance, and it is destroyed with its context. Ask with
the owner itself and the whole app shares one, which is what [`service`](/primitives/service.md)
does.

<Example @name="store-drafts" @title="A draft per reply box" />

## Usage

```gts
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { createStore } from '@ember-joinery/primitives/store'

class Draft {
  @tracked text = ''
}

class Reply extends Component {
  // One Draft per Reply, made when first read; the getter reads like a @cached one.
  get draft() {
    return createStore(this, Draft)
  }
}
```

The class is constructed with the context's owner, and the instance gets that owner, so
`@service` injections work in it (after its constructor). A context with no owner (a plain
class of your own) gets an instance all the same, constructed with nothing. For cleanup, call
`registerDestructor(this, …)` in the constructor: it runs when the context is destroyed. A
function in place of the class makes the instance itself, once per context:
`createStore(this, () => new Draft('Untitled'))`. The class (or function) is the key, so two
arrow functions that do the same thing make two instances.

## API

| Export                          | What it does                                                                    |
| ------------------------------- | ------------------------------------------------------------------------------- |
| `createStore(context, Class)`   | The instance of `Class` for `context`, made the first time                      |
| `createStore(context, () => …)` | The same, with the function making the instance                                 |
| `findOwner(contextOrOwner)`     | The owner: the value itself if it is one, its `getOwner()`, or an `owner` field |
| `isOwner(value)`                | Whether `value` has `lookup()`, which is all an owner needs                     |
| `StoreDefinition<T>` (type)     | A class constructed with the owner, or a function returning the instance        |

### From ember-primitives

| ember-primitives                 | Joinery                                                                        |
| -------------------------------- | ------------------------------------------------------------------------------ |
| `createStore(context, Class)`    | The same, except that the class is constructed with the owner, if there is one |
| `findOwner`, `isOwner` (`utils`) | `findOwner`, `isOwner`, from `store`                                           |
| `isNonNullableObject` (`utils`)  | `isNonNullableObject`, from [`narrowing`](/primitives/narrowing.md)            |

## Testing

There is nothing to mock: drive the component that owns the store, as a user would. Each
component instance in a test gets its own instance, and each test its own components.
