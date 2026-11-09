/**
 * The layout rules a primitive needs to work at all (Zoetrope's track, StickyFooter's grid,
 * Hero's size), shipped without a style sheet to import. Each set is a constructed style sheet,
 * adopted once by the document, or the shadow root, the primitive renders in.
 *
 * The rules sit in `@layer joinery` and select through `:where()`, as `@ember-joinery/ember`'s
 * joinery.css does, so an app's unlayered CSS always wins, and so do its own layers, once the
 * `joinery` layer comes before them. A layer's place is where it is first named, and adopted
 * sheets come after every one of the document's own, so that takes a name earlier in the page:
 * joinery.css names the layer, and so does the Tailwind order the guide's Installation page
 * gives (`@layer theme, base, joinery, components, utilities;`). Where nothing does, `joinery`
 * is the last layer and beats the app's other layers, Tailwind's utilities among them; the
 * guide's Primitives page says how to name it.
 *
 * They select by `data-jn-*` attributes rather than `data-slot`: a layout wraps the caller's
 * content, and joinery.css resets every `[data-slot]` and all it holds (its share of
 * Tailwind's preflight). A constructed sheet is also what a strict Content Security Policy
 * allows (`style-src` without `'unsafe-inline'` blocks a `<style>` element), and unlike inline
 * styles it can select the caller's children and hold a media query.
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
 * Adds the rules to the root `element` is in, once per root. Returns `false` while the element
 * is in neither a document nor a shadow root, so there is nothing to add them to yet.
 */
function adopt(element: Element, name: string, css: string): boolean {
  const root = element.getRootNode()
  if (!isRoot(root)) return false
  let sheets = adopted.get(root)
  if (!sheets) adopted.set(root, (sheets = new Map()))
  let sheet = sheets.get(name)
  if (!sheet) {
    const document = root.nodeType === Node.DOCUMENT_NODE ? (root as Document) : root.ownerDocument
    const Sheet = document?.defaultView?.CSSStyleSheet
    if (!Sheet) return true // a document with no window renders nothing to style
    sheet = new Sheet()
    sheet.replaceSync(css)
    sheets.set(name, sheet)
  }
  // Another script may have set the list since: add it back if it was dropped.
  if (!root.adoptedStyleSheets.includes(sheet)) {
    root.adoptedStyleSheets = [...root.adoptedStyleSheets, sheet]
  }
  return true
}

/**
 * Adds the rules named `name` to the document or shadow root `element` is rendered in, once
 * per root. Call it from a modifier, and return what it returns, which stops it. The sheet is
 * made in the element's own window, so a primitive rendered into an iframe styles that iframe.
 *
 * An element that isn't in a document yet (rendered into one made in JS, such as a Portal's
 * `@to`, and attached later) is checked again each animation frame, so the rules are there by
 * the first frame it is drawn in.
 */
export function adoptLayoutStyles(element: Element, name: string, css: string): () => void {
  const view = element.ownerDocument.defaultView
  let frame: number | undefined
  const attempt = () => {
    frame = undefined
    if (!adopt(element, name, css) && view) frame = view.requestAnimationFrame(attempt)
  }
  attempt()
  return () => {
    if (frame !== undefined) view?.cancelAnimationFrame(frame)
    frame = undefined
  }
}
