const ATTRIBUTES = [
  'aria-label',
  'aria-roledescription',
  'aria-valuetext',
  'title',
  'placeholder',
  'alt',
]

// Takes out each `⟦…⟧`, innermost first: a value may itself be a translated string.
function unwrap(text: string): string {
  let rest = text
  for (let last = ''; last !== rest;) [last, rest] = [rest, rest.replace(/⟦[^⟦⟧]*⟧/g, '')]
  return rest
}

/**
 * Every string under `root` a person sees or hears (its text, and the attributes a screen reader
 * reads) with words left over once the pseudo-locale's `⟦…⟧` are taken out: a built-in string
 * that skipped the translator. `ignore` leaves out what isn't a message (a date Intl wrote).
 */
export function unlocalized(
  root: Element = document.querySelector('#ember-testing')!,
  ignore: RegExp[] = [],
): string[] {
  const strings: string[] = []
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT)
  for (let node: Node | null = walker.currentNode; node; node = walker.nextNode()) {
    if (node instanceof Text) {
      if (!node.parentElement?.closest('style, script')) strings.push(node.data)
    } else if (node instanceof Element) {
      for (const name of ATTRIBUTES) strings.push(node.getAttribute(name) ?? '')
    }
  }
  return strings
    .map(text => text.trim())
    .filter(text => /\p{L}/u.test(unwrap(text)))
    .filter(text => !ignore.some(pattern => pattern.test(text)))
}
