import Component from '@glimmer/component'
import type Owner from '@ember/owner'
import { As } from './as.gts'

/** A section heading's level: `<h1>` to `<h6>`. */
export type HeadingLevel = 1 | 2 | 3 | 4 | 5 | 6

/** The elements that can change the heading level of what they hold. */
const BOUNDARY_ELEMENTS = new Set([
  'SECTION',
  'ARTICLE',
  'ASIDE',
  'HEADER',
  'FOOTER',
  'MAIN',
  'NAV',
])

/**
 * The boundaries that start a section of their own (HTML's sectioning content). The others
 * (`header`, `footer`, `main`) belong to the section they are in: a `<header>` usually holds
 * its section's heading, so the search looks inside it.
 */
const SECTIONING_CONTENT = new Set(['SECTION', 'ARTICLE', 'ASIDE', 'NAV'])

const HEADINGS = new Set(['H1', 'H2', 'H3', 'H4', 'H5', 'H6'])

/** Where ember-qunit renders a test: the search stops there, as at `<body>`. */
const TEST_ROOT = 'ember-testing'

const levels = new WeakMap<Text, HeadingLevel>()

// By node type rather than `instanceof`, so a heading rendered in an iframe is found too.
function isElement(node: Node | null | undefined): node is Element {
  return node?.nodeType === Node.ELEMENT_NODE
}

function isShadowRoot(node: Node | null | undefined): node is ShadowRoot {
  return node?.nodeType === Node.DOCUMENT_FRAGMENT_NODE && 'host' in node
}

function isRoot(element: Element): boolean {
  return (
    element === element.ownerDocument.body ||
    element.id === TEST_ROOT ||
    !(element.parentElement || isShadowRoot(element.parentNode))
  )
}

function isBoundary(element: Element): boolean {
  return BOUNDARY_ELEMENTS.has(element.tagName.toUpperCase())
}

/**
 * The level of the heading in `node`, or in what it holds outside any nested section, if
 * there is one. With `from`, the child of `node` the search came up through, the siblings
 * before it are searched first, nearest first, leaving out the boundaries among them: a
 * heading inside one of those is another section's.
 */
function headingIn(node: Node, from?: Node): HeadingLevel | undefined {
  if (!isElement(node)) return undefined
  const tag = node.tagName.toUpperCase()
  if (HEADINGS.has(tag)) return Number(tag.slice(1)) as HeadingLevel

  for (let previous = from?.previousSibling; previous; previous = previous.previousSibling) {
    if (!isElement(previous) || isBoundary(previous)) continue
    const level = headingIn(previous)
    if (level) return level
  }

  // Then anything inside it, since a heading can be inside an <a> or a <header>, but not
  // inside a nested section, whose headings are its own.
  for (const child of node.children) {
    if (SECTIONING_CONTENT.has(child.tagName.toUpperCase())) continue
    const level = headingIn(child)
    if (level) return level
  }
  return undefined
}

/** The nearest ancestor that `matches`, through shadow roots (which `closest()` stops at). */
function nearestAncestor(node: Node, matches: (element: Element) => boolean): Element | undefined {
  let parent: Node | null = node.parentNode
  while (parent) {
    if (isShadowRoot(parent)) {
      parent = parent.host
      continue
    }
    if (isElement(parent) && matches(parent)) return parent
    parent = parent.parentNode
  }
  return undefined
}

const boundaryOrRoot = (element: Element) => isBoundary(element) || isRoot(element)

/**
 * The level for a heading at `node`. From the boundary around it, the search goes up the
 * document; the first heading before it, between that boundary and the next one up, is its
 * parent section's heading, and this heading is one level below. A boundary with no heading
 * of its own is passed through, so a heading-less `<section>` doesn't start again at `<h1>`.
 */
function levelOf(node: Text): HeadingLevel {
  const boundary = nearestAncestor(node, isBoundary)
  if (!boundary) return 1

  let stopAt = nearestAncestor(boundary, boundaryOrRoot)
  if (!stopAt) return 1

  let previous: Node = boundary
  let current: Node | null = boundary.parentNode
  while (current) {
    const level = headingIn(current, previous)
    if (level) return Math.min(level + 1, 6) as HeadingLevel

    if (current === stopAt) {
      if (!isElement(current) || isRoot(current)) break
      stopAt = nearestAncestor(current, boundaryOrRoot)
      if (!stopAt) break
    }

    if (isShadowRoot(current)) current = current.host
    previous = current
    current = current.parentNode
  }
  return 1
}

export interface SectionHeadingOptions {
  /**
   * The level to use when nothing above `node` sets one: the top of what the page has
   * rendered so far. Default 1. It doesn't lower a level the document sets.
   */
  startAt?: HeadingLevel
}

/**
 * Which section heading, `<h1>` to `<h6>`, belongs at `node`, from the document around it:
 * one level below the heading of the section it is in. `<section>`, `<article>`, `<aside>`
 * and `<nav>` start a section, and `<header>`, `<footer>` and `<main>` are looked inside. The
 * first answer for a node is kept, so ask once it is where it will stay.
 *
 *   const marker = document.createTextNode('')
 *   section.append(marker)
 *   getSectionHeadingLevel(marker) // 2, under a page's <h1>
 *
 * It is ember-primitives' `which-heading-do-i-need`, which its `<Heading>` uses.
 */
export function getSectionHeadingLevel(node: Text, options?: SectionHeadingOptions): HeadingLevel {
  let level = levels.get(node)
  if (!level) {
    level = levelOf(node)
    levels.set(node, level)
  }
  if (level === 1 && options?.startAt) return options.startAt
  return level
}

export interface HeadingSignature {
  Args: {
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The heading's text. */
    default: []
  }
  /** The heading: an `<h1>` to `<h6>`. */
  Element: HTMLHeadingElement
}

/**
 * A section heading, `<h1>` to `<h6>`, whose level comes from where it renders, as
 * ember-primitives' `Heading`: one below the heading of the section it is in. Put content in
 * `<section>`, `<article>`, `<aside>` or `<nav>` to start a section, and its headings go one
 * level down, so a component can render a heading without knowing where it will be used.
 *
 *   <Heading>Settings</Heading>          {{! <h1> at the top of the page }}
 *   <section>
 *     <Heading>Profile</Heading>         {{! <h2> }}
 *   </section>
 *
 * The level is found once, as it first renders, from the document as it is then. Before the
 * heading it renders an empty text node, which the search starts from. It wraps its text, so
 * it is a wrapper for the harnesses (`data-test-jn-wrapper`): a part inside it still belongs
 * to the component around it.
 */
export class Heading extends Component<HeadingSignature> {
  /** Where the search for the level starts, rendered just before the heading. */
  readonly marker: Text

  constructor(owner: Owner, args: HeadingSignature['Args']) {
    super(owner, args)
    this.marker = document.createTextNode('')
  }

  get tagName(): string {
    return `h${getSectionHeadingLevel(this.marker)}`
  }

  <template>
    {{this.marker}}
    <As
      @as={{this.tagName}}
      @tag="h1"
      data-test-jn="heading"
      data-test-jn-wrapper
      data-test-jn-name={{@name}}
      ...attributes
    >{{yield}}</As>
  </template>
}
