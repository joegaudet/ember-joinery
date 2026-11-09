/**
 * The layout rules a primitive needs to work at all (Zoetrope's track, StickyFooter's grid,
 * Hero's size), shipped without a style sheet to import. Each set is a constructed style sheet,
 * adopted once by the document, or the shadow root, the primitive renders in.
 *
 * The rules sit in `@layer joinery` and select through `:where()`, as `@ember-joinery/ember`'s
 * joinery.css does, so an app's own CSS always wins: a class on the element, an unlayered rule
 * or a Tailwind utility. They select by `data-jn-*` attributes rather than `data-slot`: a
 * layout wraps the caller's content, and joinery.css resets every `[data-slot]` and all it
 * holds (its share of Tailwind's preflight). A constructed sheet is also what a strict Content
 * Security Policy allows (`style-src` without `'unsafe-inline'` blocks a `<style>` element), and
 * unlike inline styles it can select the caller's children and hold a media query.
 *
 * Nothing is adopted until a primitive renders in a browser: a server-rendered page gets the
 * rules once it boots.
 */

/** A document or a shadow root: what can adopt a style sheet. */
type Root = Document | ShadowRoot

const adopted = new WeakMap<Root, Map<string, CSSStyleSheet>>()

function isRoot(node: Node): node is Root {
  return (
    'adoptedStyleSheets' in node &&
    (node.nodeType === Node.DOCUMENT_NODE || node.nodeType === Node.DOCUMENT_FRAGMENT_NODE)
  )
}

/**
 * Adds the rules named `name` to the document or shadow root `element` is rendered in, once
 * per root. Call it from a modifier, once the element is in the document. The sheet is made in
 * the element's own window, so a primitive rendered into an iframe styles that iframe.
 */
export function adoptLayoutStyles(element: Element, name: string, css: string): void {
  const root = element.getRootNode()
  if (!isRoot(root)) return
  let sheets = adopted.get(root)
  if (!sheets) adopted.set(root, (sheets = new Map()))
  let sheet = sheets.get(name)
  if (!sheet) {
    const document = root.nodeType === Node.DOCUMENT_NODE ? (root as Document) : root.ownerDocument
    const Sheet = document?.defaultView?.CSSStyleSheet
    if (!Sheet) return
    sheet = new Sheet()
    sheet.replaceSync(css)
    sheets.set(name, sheet)
  }
  // Another script may have set the list since: add it back if it was dropped.
  if (!root.adoptedStyleSheets.includes(sheet)) {
    root.adoptedStyleSheets = [...root.adoptedStyleSheets, sheet]
  }
}
