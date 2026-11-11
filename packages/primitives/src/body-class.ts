import Helper from '@ember/component/helper'

export interface BodyClassSignature {
  Args: {
    /**
     * The classes to put on `<body>` while the helper renders, separated by spaces. When the
     * helper stops rendering, or the classes change, the ones no longer asked for come off.
     */
    Positional: [classes: string | undefined | null]
  }
  /** Nothing: the helper's work is the classes it sets. */
  Return: undefined
}

/** The classes each rendered helper asks for. */
const requests = new Map<object, string[]>()
/** The classes this module put on `<body>`, and so may take off. */
const added = new Set<string>()

function split(classes: string | undefined | null): string[] {
  return (classes ?? '').split(/\s+/).filter(Boolean)
}

/**
 * Puts on `<body>` every class some helper asks for, and takes off the ones this module added
 * that nobody asks for now. A class `<body>` already had (from index.html, or the app's own
 * code) is never taken off.
 */
function update(): void {
  const wanted = new Set([...requests.values()].flat())
  const classes = document.body.classList
  for (const name of added) {
    if (wanted.has(name)) continue
    classes.remove(name)
    added.delete(name)
  }
  for (const name of wanted) {
    if (classes.contains(name)) continue
    classes.add(name)
    added.add(name)
  }
}

/**
 * Sets classes on `<body>` while it renders: `{{bodyClass "no-scroll"}}` in a route's template
 * puts `no-scroll` on `<body>` while that route shows, and takes it off when it goes. Several
 * helpers can ask for the same class; it stays until none of them does. A class `<body>` had
 * already is left alone. The argument is reactive.
 *
 *   {{bodyClass (if this.menuOpen "menu-open")}}
 *
 * It is ember-primitives' `bodyClass` (from ember-set-body-class), except that it never removes
 * a class it didn't add, and it applies the classes as it renders rather than a frame later.
 */
class BodyClass extends Helper<BodyClassSignature> {
  compute([classes]: [string | undefined | null]): undefined {
    requests.set(this, split(classes))
    update()
    return undefined
  }

  willDestroy(): void {
    requests.delete(this)
    update()
    super.willDestroy()
  }
}

export const bodyClass = BodyClass
