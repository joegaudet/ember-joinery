#!/usr/bin/env node
// Pulls the utility classes upstream writes inline in a component (in its `cn(...)` and
// `cva(...)` calls and `className` strings) out of its ui source, so they can go into the
// component's CSS next to the ported style sheet's rules (see "Styling pipeline" in
// JOINERY_PLAN.md).
//
//   node scripts/extract-classes.mjs button            CSS for ui/button.tsx, on stdout
//   node scripts/extract-classes.mjs button --json     every class string found, as JSON
//   node scripts/extract-classes.mjs --file <path.tsx> any file, not just the pinned ui source
//   ... --out <file>                                   write instead of printing
//
// Each class string is split three ways:
//
// - `cn-*` semantic classes, renamed `jn-*`: the slot the string styles;
// - markers (`group`, `group/name`, `peer`, `peer/name`): not utilities, so they can't be
//   applied; they stay as classes on the element, since other rules' `group-*:` and `peer-*:`
//   variants look for them;
// - everything else: utilities, which the CSS output `@apply`s to the slot's rule.
//
// An icon's size utility leaves a marker behind too. Upstream's rules size the icons inside a
// part unless an icon has a size of its own, which they tell by its class
// (`[&_svg:not([class*='size-'])]:size-4`). When an icon's `size-4` moves into its rule, the
// icon keeps `jn-size-4` instead (no rule styles it), so those rules still leave it alone; see
// `sizeMarker`.
//
// The order the rules go in matters, and it is the registry build's: shadcn's `transformStyle`
// (in the `shadcn` package, which the parity app runs as upstream's build does) swaps each
// semantic class for its style rule's utilities, and tailwind-merge (`cn`) keeps the later of two
// conflicting classes. Where the swapped utilities land depends on the call:
//
// - A cva()'s base string and each variant's string are resolved in place: the string's style
//   utilities, then its inline ones. cva joins the base, then the variants, so an inline utility
//   beats its own string's style rule (`.jn-badge`) but loses to a variant's
//   (`.jn-badge-variant-destructive`).
// - A cn() call gathers the semantic classes of all its plain string arguments and puts their
//   style utilities at the front of the call: into its first argument, ahead of that string's
//   inline utilities, when that argument is a plain string, or as a new first argument when it
//   isn't. So every inline utility in the call beats every style rule of the call's semantic
//   classes, and a later argument's semantic class never overrides an earlier inline utility.
// - Some semantic classes are never resolved, so on ui.shadcn.com they style nothing: those in
//   a cn() argument that isn't a plain string (`open && "cn-x"`, a ternary), in a cn() call that
//   isn't a `className` (Calendar's `classNames={{ dropdown_root: cn(…) }}`, Input OTP's
//   `containerClassName`), in a cva compound variant, and any a cva string of the same file has
//   already resolved. A rule for a `<part>ClassName` prop's cn() goes on `jn-<data-slot>-<part>`
//   (`jn-input-otp-container`), which the element carries instead of the unresolved class.
//   transformStyle also keeps five classes on the element for its other transforms
//   (`cn-font-heading`, `cn-menu-target`, `cn-menu-translucent`, `cn-logical-sides`,
//   `cn-rtl-flip`); those aren't flagged. Other parts share them, so they never name a rule's
//   subject: an element whose only semantic classes are kept ones (a sub-trigger's chevron,
//   `cn-rtl-flip ml-auto`) gets its rule only inside the nearest enclosing element with a class
//   of its own (`:where(.jn-dropdown-menu-sub-trigger) > :where(.jn-rtl-flip)`), so it moves no
//   other part's icon.
//
// Joinery's rules are all `:where()`, so source order decides between them. The extracted rules
// go after the ported style sheet, which gets the inline-beats-own-rule case right, and every
// cn() case. For cva, the script reads all eight upstream style sheets and checks each inline
// utility against the style rules of the cva's later strings (leaving out those that can't
// apply together, such as two options of one variant). A utility that a later class overrides
// in every style moves out of the base rule into one that skips that class,
// `:where(.jn-badge:not(.jn-badge-variant-destructive))`. One that only some styles override
// stays in the base rule, under a NOTE naming the styles where it comes out wrong. A NOTE also
// marks each semantic class upstream never resolves (Joinery's sheet would style it, and
// ui.shadcn.com doesn't), and each one a cn() call moves ahead of an earlier argument that
// isn't a plain string (`cn(buttonVariants(…), "cn-x")`: the button's classes then beat it).
//
// Strings that only apply under a condition (`isActive && "…"`, `a ? "…" : "…"`) are reported
// with their condition and left as comments in the CSS: the component decides how to express
// them (usually a data attribute).
//
// The rules' physical sides are made logical, as port-styles.mjs does to the sheets (see
// rtl.mjs), so they hold right to left too; the checks above run on upstream's own classes.
//
// A class Tailwind has no utility for (navigation-menu's `origin-top-center`) styles nothing on
// ui.shadcn.com, whose Tailwind build skips it, but `@apply` fails on it. The script asks
// Tailwind, set up as the build compiles the styles (packages/ember's src/css/setup.css, so
// shadcn's variants and the theme's colours count), and leaves each such class out of its rule
// under a NOTE, so the output can be kept whole.

import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs'
import { createRequire } from 'node:module'
import { basename, dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { twMerge } from 'cn'
import ts from 'typescript'
import { logicalClasses } from './rtl.mjs'
import { PATHS, checkoutDir, repoRoot } from './upstream.mjs'

const MARKER = /^(group|peer)(\/[\w-]+)?$/

/**
 * What `unknownUtilities` asks: the Tailwind packages/ember builds with, and the setup it
 * compiles the styles with.
 */
export const TAILWIND_SETUP = {
  tailwind: join(repoRoot, 'packages', 'ember', 'node_modules', 'tailwindcss', 'package.json'),
  setup: join(repoRoot, 'packages', 'ember', 'src', 'css', 'setup.css'),
}

/** The `package.json` of `name`, from the nearest `node_modules` at or above `dir`. */
function packageJson(name, dir) {
  for (let at = dir; ; at = dirname(at)) {
    const candidate = join(at, 'node_modules', name, 'package.json')
    if (existsSync(candidate)) return candidate
    if (dirname(at) === at) throw new Error(`extract-classes: can't find ${name} from ${dir}`)
  }
}

/** Reads a style sheet `@import`ed from `base`, as Tailwind's design system asks for one. */
async function loadStylesheet(id, base) {
  let path
  if (id.startsWith('.') || id.startsWith('/')) {
    path = resolve(base, id)
  } else {
    // A package's CSS, through its exports (`style`, as tw-animate-css has) or by path.
    const name = id
      .split('/')
      .slice(0, id.startsWith('@') ? 2 : 1)
      .join('/')
    const manifest = packageJson(name, base)
    const json = JSON.parse(readFileSync(manifest, 'utf8'))
    const subpath = id.slice(name.length)
    const exported = json.exports?.[subpath ? `.${subpath}` : '.']
    const file =
      typeof exported === 'string'
        ? exported
        : (exported?.style ?? exported?.default ?? (subpath ? subpath.slice(1) : json.style))
    path = resolve(dirname(manifest), file)
  }
  return { path, base: dirname(path), content: readFileSync(path, 'utf8') }
}

/**
 * The classes among `candidates` that Tailwind has no utility for, set up as the build compiles
 * the styles (TAILWIND_SETUP), so shadcn's own variants (`data-open:`) and utilities
 * (`no-scrollbar`) and the theme's colours (`bg-popover`) all count.
 */
export async function unknownUtilities(candidates) {
  // packages/ember's own Tailwind, as its package resolves it.
  const require = createRequire(join(dirname(TAILWIND_SETUP.setup), '..', '..', 'package.json'))
  const { __unstable__loadDesignSystem: loadDesignSystem } = require('tailwindcss')
  const system = await loadDesignSystem(readFileSync(TAILWIND_SETUP.setup, 'utf8'), {
    base: dirname(TAILWIND_SETUP.setup),
    loadStylesheet,
  })
  const list = [...new Set(candidates)]
  const css = system.candidatesToCss(list)
  return new Set(list.filter((_candidate, index) => !css[index]))
}

/** The semantic classes transformStyle keeps on the element for its other transforms. */
export const KEPT = new Set([
  'jn-font-heading',
  'jn-menu-target',
  'jn-menu-translucent',
  'jn-logical-sides',
  'jn-rtl-flip',
])

/** An element that draws an icon: an `<svg>`, a lucide-react icon, or upstream's placeholder. */
const ICON = /^(svg|IconPlaceholder|\w+Icon)$/

/**
 * The class an icon keeps in place of a size utility its rule now applies, or undefined.
 * Upstream's rules skip an icon that has a size of its own by matching
 * `svg:not([class*='size-'])`, so an icon whose upstream classes say `size-` needs a class that
 * does too: `jn-size-4` for `size-4`, or `jn-size-own` for a size behind a variant
 * (`md:size-4`). None for an element that isn't an icon, or when a semantic class of the same
 * element (the same call's strings) already says `size-`.
 */
export function sizeMarker(entry, entries = [entry]) {
  if (!ICON.test(entry.element ?? '')) return undefined
  const sizes = entry.utilities.filter(utility => utility.includes('size-'))
  if (!sizes.length) return undefined
  const element = entries.filter(other => other.call === entry.call)
  if (element.some(other => other.semantic.some(name => name.includes('size-')))) return undefined
  const plain = sizes.find(utility => /^size-[\w.]+$/.test(utility))
  return plain ? `jn-${plain}` : 'jn-size-own'
}

/** A plain string, as transformStyle reads one: a string literal or a template with no `${}`. */
const isPlain = node => ts.isStringLiteral(node) || ts.isNoSubstitutionTemplateLiteral(node)

const isCnCall = node =>
  Boolean(node) &&
  ts.isCallExpression(node) &&
  ts.isIdentifier(node.expression) &&
  node.expression.text === 'cn'

/**
 * Whether transformStyle resolves a cn() call's semantic classes, or why not: it does for
 * `className={cn(…)}`, for a cn() anywhere inside `className={…}` when that expression isn't a
 * cn() call itself, and for `className: cn(…)` in any object.
 */
function cnResolution(node, source) {
  const parent = node.parent
  if (ts.isPropertyAssignment(parent) && parent.initializer === node) {
    const name = propertyName(parent, source)
    if (name === 'className') return true
  }
  for (let current = parent; current; current = current.parent) {
    if (!ts.isJsxAttribute(current)) continue
    const name = current.name.getText(source)
    if (name !== 'className') return `its cn() call is in ${name}, not a className`
    const expression =
      current.initializer && ts.isJsxExpression(current.initializer)
        ? current.initializer.expression
        : undefined
    return expression === node || !isCnCall(expression)
      ? true
      : 'its cn() call is inside another cn() call'
  }
  return 'its cn() call is not a className'
}

/** Splits a class string into semantic classes (renamed `jn-`), markers and utilities. */
export function splitClasses(value) {
  const semantic = []
  const markers = []
  const utilities = []
  for (const token of value.split(/\s+/).filter(Boolean)) {
    if (token.startsWith('cn-')) semantic.push(`jn-${token.slice(3)}`)
    else if (MARKER.test(token)) markers.push(token)
    else utilities.push(token)
  }
  return { semantic, markers, utilities }
}

/** A string literal's text, or a `String.raw` template's raw text (backslashes kept). */
function stringValue(node) {
  if (ts.isStringLiteral(node) || ts.isNoSubstitutionTemplateLiteral(node)) return node.text
  if (
    ts.isTaggedTemplateExpression(node) &&
    ts.isNoSubstitutionTemplateLiteral(node.template) &&
    ts.isPropertyAccessExpression(node.tag) &&
    ts.isIdentifier(node.tag.expression) &&
    node.tag.expression.text === 'String' &&
    node.tag.name.text === 'raw'
  ) {
    return node.template.rawText
  }
  return undefined
}

function propertyName(property, source) {
  return property.name && (ts.isIdentifier(property.name) || ts.isStringLiteral(property.name))
    ? property.name.text
    : property.name?.getText(source)
}

/**
 * The JSX element a node sits in: its tag, its `data-slot` if it has one, and, for a string in
 * an object passed to another attribute (Calendar's `classNames={{ months: cn(…) }}`), that
 * attribute and the key, as `prop` (`classNames.months`).
 */
function enclosingElement(node, source) {
  let key
  let attribute
  for (let current = node.parent; current; current = current.parent) {
    if (key === undefined && ts.isPropertyAssignment(current)) key = propertyName(current, source)
    if (attribute === undefined && ts.isJsxAttribute(current)) {
      attribute = current.name.getText(source)
    }
    if (ts.isJsxOpeningElement(current) || ts.isJsxSelfClosingElement(current)) {
      let slot
      for (const property of current.attributes.properties) {
        if (!ts.isJsxAttribute(property) || property.name.getText(source) !== 'data-slot') continue
        const init = property.initializer
        if (init && ts.isStringLiteral(init)) slot = init.text
        else if (init && ts.isJsxExpression(init) && init.expression) {
          slot = stringValue(init.expression)
        }
      }
      const prop =
        attribute && attribute !== 'className' ? [attribute, key].filter(Boolean).join('.') : ''
      return { element: current.tagName.getText(source), slot, ...(prop && { prop }) }
    }
    if (ts.isFunctionDeclaration(current) || ts.isArrowFunction(current)) break
  }
  return {}
}

/** A class that is the element's own: a semantic class transformStyle doesn't keep for others. */
const ownClass = names => names.find(name => !KEPT.has(name))

/**
 * The class an opening JSX element is styled by, as the rules name it: the first semantic class
 * of its own in its plain `className` strings (those of a `cn()` call included), or else
 * `jn-<data-slot>`. Undefined when it has neither.
 */
function elementClass(opening, source) {
  let slot
  let name
  for (const property of opening.attributes.properties) {
    if (!ts.isJsxAttribute(property) || !property.initializer) continue
    const attribute = property.name.getText(source)
    const init = property.initializer
    const expression = ts.isJsxExpression(init) ? init.expression : init
    if (!expression) continue
    if (attribute === 'data-slot') slot = stringValue(expression)
    if (attribute !== 'className') continue
    const strings = isCnCall(expression)
      ? expression.arguments.map(stringValue).filter(value => value !== undefined)
      : [stringValue(expression)].filter(value => value !== undefined)
    name = ownClass(strings.flatMap(value => splitClasses(value).semantic))
  }
  return name ?? (slot && `jn-${slot}`)
}

/**
 * For a node in the class list of an element whose only semantic classes are ones
 * transformStyle keeps (a chevron that is only `cn-rtl-flip`): the nearest JSX element around
 * that element with a class of its own (see `elementClass`), as `{ class, child }`, where `child`
 * says the element is its direct child. Other parts share a kept class (Breadcrumb's separators
 * and Pagination's arrows are `cn-rtl-flip` too), so the element's rule is scoped under it.
 */
function enclosingScope(node, source) {
  let own
  let child = true
  for (let current = node.parent; current; current = current.parent) {
    if (
      ts.isFunctionDeclaration(current) ||
      ts.isArrowFunction(current) ||
      ts.isFunctionExpression(current)
    )
      break
    if (!own) {
      if (ts.isJsxSelfClosingElement(current)) own = current
      else if (ts.isJsxOpeningElement(current)) own = current = current.parent
      continue
    }
    // An element passed in another element's attribute is rendered somewhere inside it.
    if (ts.isJsxAttribute(current)) child = false
    if (!ts.isJsxElement(current)) continue
    const name = elementClass(current.openingElement, source)
    if (name) return { class: name, child }
    child = false
  }
  return undefined
}

/** The function a node is in (`CardHeader`), for context in the report. */
function enclosingFunction(node) {
  for (let current = node.parent; current; current = current.parent) {
    if (ts.isFunctionDeclaration(current) && current.name) return current.name.text
    if (ts.isVariableDeclaration(current) && ts.isIdentifier(current.name)) return current.name.text
  }
  return undefined
}

/**
 * The class strings among a `cn(...)` argument: plain strings, and strings behind `&&`, `?:` or
 * `||`, with the condition they depend on.
 */
function collectStrings(node, source, condition, out) {
  const value = stringValue(node)
  if (value !== undefined) {
    out.push({ value, ...(condition && { condition }) })
    return
  }
  if (ts.isParenthesizedExpression(node))
    return collectStrings(node.expression, source, condition, out)
  if (ts.isBinaryExpression(node)) {
    const op = node.operatorToken.kind
    if (op === ts.SyntaxKind.AmpersandAmpersandToken) {
      const test = node.left.getText(source)
      return collectStrings(node.right, source, condition ? `${condition} && ${test}` : test, out)
    }
    if (op === ts.SyntaxKind.BarBarToken || op === ts.SyntaxKind.QuestionQuestionToken) {
      collectStrings(node.right, source, `!(${node.left.getText(source)})`, out)
      return
    }
  }
  if (ts.isConditionalExpression(node)) {
    const test = node.condition.getText(source)
    collectStrings(node.whenTrue, source, condition ? `${condition} && ${test}` : test, out)
    collectStrings(
      node.whenFalse,
      source,
      condition ? `${condition} && !(${test})` : `!(${test})`,
      out,
    )
  }
}

function objectProperty(object, name, source) {
  return object.properties.find(
    property => ts.isPropertyAssignment(property) && propertyName(property, source) === name,
  )
}

/**
 * Every class string in a ui source, in source order. Each entry says where it came from
 * (`cn`, `cva`, `cva-variant`, `cva-compound` or `className`), which call it belongs to (`call`,
 * numbered in source order: one call's strings make one element's class list, in entry order),
 * the element and `data-slot` it styles when that can be told, and its classes split as
 * `splitClasses` does.
 */
export function extractClasses(code, fileName = 'component.tsx') {
  const source = ts.createSourceFile(
    fileName,
    code,
    ts.ScriptTarget.Latest,
    true,
    ts.ScriptKind.TSX,
  )
  const entries = []
  let calls = 0
  // `resolution`: true when transformStyle resolves the string's semantic classes, or why not.
  const add = (node, origin, call, found, extra = {}, resolution = true) => {
    for (const { value, condition } of found) {
      const classes = splitClasses(value)
      if (!classes.semantic.length && !classes.utilities.length && !classes.markers.length) continue
      const why = condition ? 'it is behind a condition' : resolution
      const unresolved = why === true ? [] : classes.semantic.filter(name => !KEPT.has(name))
      const within =
        classes.semantic.length && !ownClass(classes.semantic)
          ? enclosingScope(node, source)
          : undefined
      entries.push({
        origin,
        call,
        function: enclosingFunction(node),
        ...enclosingElement(node, source),
        ...(within && { within }),
        ...extra,
        ...(condition && { condition }),
        ...classes,
        ...(unresolved.length && { unresolved: { classes: unresolved, why } }),
      })
    }
  }

  const visit = node => {
    if (ts.isCallExpression(node) && ts.isIdentifier(node.expression)) {
      const callee = node.expression.text
      if (callee === 'cn') {
        const call = calls++
        const resolution = cnResolution(node, source)
        node.arguments.forEach((argument, index) => {
          const found = []
          collectStrings(argument, source, undefined, found)
          // transformStyle moves this string's style rules to the front of the call, ahead of
          // any earlier argument that isn't a plain string.
          const ahead = node.arguments
            .slice(0, index)
            .filter(earlier => !isPlain(earlier))
            .map(earlier => earlier.getText(source).replace(/\s+/g, ' '))
          add(
            argument,
            'cn',
            call,
            found,
            resolution === true && ahead.length ? { ahead } : {},
            resolution === true ? isPlain(argument) || 'it is not a plain string' : resolution,
          )
        })
      } else if (callee === 'cva') {
        const call = calls++
        const [base, config] = node.arguments
        if (base) {
          const found = []
          collectStrings(base, source, undefined, found)
          add(base, 'cva', call, found, {}, ts.isStringLiteral(base) || 'it is not a plain string')
        }
        if (config && ts.isObjectLiteralExpression(config)) {
          const variants = objectProperty(config, 'variants', source)?.initializer
          if (variants && ts.isObjectLiteralExpression(variants)) {
            for (const group of variants.properties) {
              if (
                !ts.isPropertyAssignment(group) ||
                !ts.isObjectLiteralExpression(group.initializer)
              )
                continue
              for (const option of group.initializer.properties) {
                if (!ts.isPropertyAssignment(option)) continue
                const found = []
                collectStrings(option.initializer, source, undefined, found)
                add(
                  option,
                  'cva-variant',
                  call,
                  found,
                  { variant: `${propertyName(group, source)}.${propertyName(option, source)}` },
                  ts.isStringLiteral(option.initializer) || 'it is not a plain string',
                )
              }
            }
          }
          const compounds = objectProperty(config, 'compoundVariants', source)?.initializer
          if (compounds && ts.isArrayLiteralExpression(compounds)) {
            for (const compound of compounds.elements) {
              if (!ts.isObjectLiteralExpression(compound)) continue
              const when = compound.properties
                .filter(
                  p =>
                    ts.isPropertyAssignment(p) &&
                    !['class', 'className'].includes(propertyName(p, source)),
                )
                .map(p => `${propertyName(p, source)}=${p.initializer.getText(source)}`)
                .join(' ')
              for (const key of ['class', 'className']) {
                const property = objectProperty(compound, key, source)
                if (!property) continue
                const found = []
                collectStrings(property.initializer, source, undefined, found)
                add(
                  property,
                  'cva-compound',
                  call,
                  found,
                  { variant: when },
                  'it is in a cva compound variant',
                )
              }
            }
          }
        }
        return
      }
    }
    if (ts.isJsxAttribute(node) && node.name.getText(source) === 'className' && node.initializer) {
      const init = node.initializer
      const literal = ts.isStringLiteral(init)
        ? init.text
        : ts.isJsxExpression(init) && init.expression
          ? stringValue(init.expression)
          : undefined
      if (literal !== undefined) {
        const plain =
          isPlain(init) || (ts.isJsxExpression(init) && init.expression && isPlain(init.expression))
        add(
          node,
          'className',
          calls++,
          [{ value: literal }],
          {},
          plain || 'it is not a plain string',
        )
      }
    }
    ts.forEachChild(node, visit)
  }
  visit(source)

  // transformStyle resolves every cva first, and a class a cva string has resolved isn't
  // resolved again anywhere in the file.
  const byCva = new Set()
  const cvaFirst = [
    ...entries.filter(entry => entry.origin === 'cva' || entry.origin === 'cva-variant'),
    ...entries.filter(entry => entry.origin === 'cn' || entry.origin === 'className'),
  ]
  for (const entry of cvaFirst) {
    if (entry.unresolved) continue
    const repeated = entry.semantic.filter(name => !KEPT.has(name) && byCva.has(name))
    if (repeated.length) {
      entry.unresolved = { classes: repeated, why: 'a cva string of this file resolved it already' }
    }
    if (entry.origin !== 'cn' && entry.origin !== 'className') {
      for (const name of entry.semantic) byCva.add(name)
    }
  }
  return entries
}

// ---------------------------------------------------------------------------------------------
// The style sheets, and the inline utilities a later string's style rule overrides

/**
 * An upstream style sheet's plain rules (`.cn-x { @apply …; }`), as a map from the renamed
 * class (`jn-x`) to its utilities. A rule with any other selector (`.cn-x:has(…)`) only applies
 * in some context, so it is left out.
 */
export function sheetRules(css) {
  const rules = new Map()
  for (const match of css.matchAll(/^[ \t]*\.(cn-[a-z0-9-]+)[ \t]*\{([^}]*)\}/gm)) {
    const name = `jn-${match[1].slice(3)}`
    const utilities = [...match[2].matchAll(/@apply\s+([^;]+);/g)].flatMap(found =>
      found[1].split(/\s+/).filter(Boolean),
    )
    rules.set(name, [...(rules.get(name) ?? []), ...utilities])
  }
  return rules
}

/** Every style sheet in an upstream checkout, as `{ nova: sheetRules(…), … }`. */
export function readSheets(checkout) {
  const dir = join(checkout, PATHS.styles)
  if (!existsSync(dir)) return undefined
  return Object.fromEntries(
    readdirSync(dir)
      .filter(name => /^style-[a-z]+\.css$/.test(name))
      .sort()
      .map(name => [
        basename(name, '.css').slice('style-'.length),
        sheetRules(readFileSync(join(dir, name), 'utf8')),
      ]),
  )
}

/** Whether tailwind-merge, as upstream's `cn` runs it, drops `earlier` from `earlier later`. */
export function overrides(earlier, later) {
  if (earlier === later) return false
  return !twMerge(`${earlier} ${later}`).split(/\s+/).includes(earlier)
}

const terms = condition => (condition ? condition.split(' && ') : [])

/** A compound variant's conditions, `variant="link" size="sm"`, as `{ variant: 'link', … }`. */
const compoundWants = when =>
  Object.fromEntries(
    [...(when ?? '').matchAll(/([\w-]+)=(["']?)([^"'\s]+)\2/g)].map(m => [m[1], m[3]]),
  )

/**
 * Whether two strings of one call can never apply together: two options of one variant, an
 * option and a compound variant that asks for another option of it, or the two sides of a
 * condition.
 */
export function exclusive(a, b) {
  // `variant.destructive`: the variant, then the option (which may itself hold a dot).
  const option = entry =>
    entry.origin === 'cva-variant' ? entry.variant.split(/\.(.*)/s).slice(0, 2) : undefined
  const [groupA, valueA] = option(a) ?? []
  const [groupB, valueB] = option(b) ?? []
  if (groupA && groupA === groupB && valueA !== valueB) return true
  for (const [variant, compound] of [
    [a, b],
    [b, a],
  ]) {
    const [group, value] = option(variant) ?? []
    if (!group || compound.origin !== 'cva-compound') continue
    const wanted = compoundWants(compound.variant)[group]
    if (wanted !== undefined && wanted !== value) return true
  }
  const termsA = terms(a.condition)
  const termsB = terms(b.condition)
  return (
    termsA.some(term => termsB.includes(`!(${term})`)) ||
    termsB.some(term => termsA.includes(`!(${term})`))
  )
}

/**
 * Whether transformStyle resolves a string's semantic classes where the string is: a cva's base
 * and variant strings. A cn() call moves its strings' style rules to its front, so they never
 * override its inline utilities.
 */
const inPlace = entry => entry.origin === 'cva' || entry.origin === 'cva-variant'

/**
 * The entries, each with `overriddenBy` where a later string of the same call has a style rule
 * that overrides one of its utilities: `{ utility, by, with, styles, every }`, where `by` is the
 * later class, `with` its overriding utilities, `styles` the sheets it happens in, and `every`
 * whether that is all of them.
 */
export function findOverrides(entries, sheets) {
  const styles = Object.keys(sheets)
  return entries.map((entry, index) => {
    if (!entry.utilities.length) return entry
    const found = []
    for (const later of entries.slice(index + 1)) {
      if (later.call !== entry.call || !inPlace(later) || exclusive(entry, later)) continue
      for (const className of later.semantic.filter(
        name => !later.unresolved?.classes.includes(name),
      )) {
        for (const utility of entry.utilities) {
          const by = {}
          for (const style of styles) {
            const winner = (sheets[style].get(className) ?? []).find(other =>
              overrides(utility, other),
            )
            if (winner) by[style] = winner
          }
          const overriding = Object.keys(by)
          if (!overriding.length) continue
          found.push({
            utility,
            by: className,
            with: [...new Set(Object.values(by))],
            styles: overriding,
            every: overriding.length === styles.length,
          })
        }
      }
    }
    return found.length ? { ...entry, overriddenBy: found } : entry
  })
}

// ---------------------------------------------------------------------------------------------
// The CSS

/**
 * The class for a part upstream styles through a `<part>ClassName` prop of the element (Input
 * OTP's `containerClassName`), when that cn() call's semantic classes are never resolved:
 * `jn-<data-slot>-<part>` (`jn-input-otp-container`). Joinery's element carries it instead of
 * the semantic class, so the style sheets' rule for that class styles nothing there, as on
 * ui.shadcn.com, and the inline utilities still have an element to go on.
 */
export function partClassFor(entry) {
  const part = /^([a-z][A-Za-z0-9]*)ClassName$/.exec(entry.prop ?? '')?.[1]
  if (!part || !entry.slot || !entry.unresolved) return undefined
  return `jn-${entry.slot}-${part.replace(/[A-Z]/g, letter => `-${letter.toLowerCase()}`)}`
}

/**
 * The rule's subject: the string's first semantic class of its own (one transformStyle doesn't
 * keep); for a later string of a cn() call without one, the call's (every string of a call
 * styles the same element); or else the element's `data-slot`. An element whose only semantic
 * classes are kept ones shares them with other parts, so its first is the subject only inside
 * the nearest enclosing element with a class of its own, `scope` (`.jn-x > ` for a direct
 * child). A `<part>ClassName` prop's part class comes first, flagged `part`. Undefined, with no
 * scope, when there is nothing to attach the rule to.
 */
function subjectFor(entry, entries) {
  const part = partClassFor(entry)
  if (part) return { subject: `.${part}`, part: true }
  const own = ownClass(entry.semantic)
  if (own) return { subject: `.${own}` }
  if (entry.origin === 'cn') {
    const named = entries.find(other => other.call === entry.call && ownClass(other.semantic))
    if (named && entries.indexOf(named) < entries.indexOf(entry)) {
      return { subject: `.${ownClass(named.semantic)}` }
    }
  }
  if (entry.slot) return { subject: `.jn-${entry.slot}` }
  if (entry.semantic.length && entry.within) {
    const { class: name, child } = entry.within
    return { subject: `.${entry.semantic[0]}`, scope: `:where(.${name})${child ? ' >' : ''} ` }
  }
  return {}
}

function describe(entry) {
  const where = [
    entry.slot && `data-slot="${entry.slot}"`,
    entry.prop && `${entry.element} ${entry.prop}`,
    entry.function && `in ${entry.function}`,
    entry.variant && `(${entry.origin} ${entry.variant})`,
  ]
  return where.filter(Boolean).join(' ') || entry.origin
}

const plural = (count, one, many) => (count === 1 ? one : many)

const classList = names => names.map(name => `.${name}`).join(', ')

/**
 * NOTEs for what transformStyle does to a string's semantic classes that the ported sheet
 * can't follow: classes it never resolves, and classes a cn() call moves ahead of an earlier
 * argument (only those with a rule in some style, when the sheets were read).
 */
function transformNotes(entry, sheets) {
  const notes = []
  if (entry.unresolved) {
    const { classes, why } = entry.unresolved
    const part = partClassFor(entry)
    const remedy = part
      ? `this rule is on .${part} instead, so give the element that class, and not ${classList(classes)}`
      : `to match, keep ${plural(classes.length, 'that class', 'those classes')} off this element, or ${plural(classes.length, 'its rule', 'their rules')} from reaching it`
    notes.push(
      `/* NOTE: upstream's registry build never resolves ${classList(classes)} here (${why}), so on ui.shadcn.com ${plural(classes.length, 'its style rule applies', 'their style rules apply')} nowhere; ${remedy}. */`,
    )
  }
  if (entry.ahead) {
    const moved = entry.semantic.filter(
      name =>
        !KEPT.has(name) &&
        !entry.unresolved?.classes.includes(name) &&
        (!sheets || Object.values(sheets).some(rules => rules.get(name)?.length)),
    )
    if (moved.length) {
      notes.push(
        `/* NOTE: upstream's registry build moves ${classList(moved)}'s style rule to the front of this cn() call, ahead of ${entry.ahead.join(', ')}, whose classes then beat it; Joinery's sheet orders the rules by where the sheet has them. */`,
      )
    }
  }
  return notes
}

/**
 * The inline utilities as CSS: one `@apply` rule per class string that has a slot, with the
 * markers and anything conditional or slot-less left as comments for the component to handle.
 * Entries that went through `findOverrides` also get the `:not()` rules and NOTEs it calls for.
 * `sheets: null` says the style sheets weren't there to check against. A class in `unknown`
 * (from `unknownUtilities`) stays out of every rule, under a NOTE.
 */
export function renderCss(entries, { name, commit, sheets, unknown = new Set() } = {}) {
  const lines = [
    '/*',
    ` * Inline utilities from ${PATHS.ui}/${name}.tsx${commit ? ` (shadcn-ui/ui@${commit.slice(0, 7)})` : ''},`,
    " * extracted by scripts/extract-classes.mjs. They go after the style sheet's rules: upstream's",
    " * registry build puts a string's style rules ahead of its inline utilities (a cn() call's, ahead",
    ' * of all of them), so each wins over those rules. Where a later string of the same cva (a',
    ' * variant, a size) overrides one, its rule skips that class with :not(). Physical sides are',
    ' * logical, as in the ported sheets (scripts/rtl.mjs), so the rules hold in both directions.',
    ...(sheets === null
      ? [' * The style sheets were missing, so later classes were not checked.']
      : []),
    ' */',
  ]
  for (const entry of entries) {
    const { subject, scope = '', part } = subjectFor(entry, entries)
    const notes = []
    const keep = [...entry.markers, sizeMarker(entry, entries)].filter(Boolean)
    if (keep.length) notes.push(`keep on the element: ${keep.join(' ')}`)
    const also =
      subject && !part
        ? entry.semantic.filter(name => `.${name}` !== subject)
        : entry.semantic.slice(1)
    if (also.length) notes.push(`also: ${also.join(' ')}`)
    if (scope && entry.utilities.length) {
      notes.push(
        `inside .${entry.within.class} only, since other parts share ${classList(entry.semantic)}`,
      )
    }
    const warnings = transformNotes(entry, sheets)
    if (!entry.utilities.length) {
      if (notes.length || warnings.length) {
        lines.push(
          '',
          `/* ${subject ? `${scope}:where(${subject})` : describe(entry)}${notes.length ? `: ${notes.join('; ')}` : ''} */`,
          ...warnings,
        )
      }
      continue
    }
    const overridden = entry.overriddenBy ?? []
    lines.push('')
    if (entry.condition || !subject) {
      const why = entry.condition ? `only when ${entry.condition}` : 'no slot to attach it to'
      const later = overridden.map(
        o => `.${o.by} overrides ${o.utility} (${o.every ? 'every style' : o.styles.join(', ')})`,
      )
      lines.push(
        `/* ${describe(entry)}, ${why}: ${entry.utilities.join(' ')}${later.length ? `; later in the call, ${later.join(', ')}` : ''}${keep.length ? `; keep on the element: ${keep.join(' ')}` : ''} */`,
        ...warnings,
      )
      continue
    }

    // A utility a later class overrides in every style moves to a rule that skips that class.
    const moved = new Map()
    for (const { utility, by, every } of overridden) {
      if (every) moved.set(utility, [...new Set([...(moved.get(utility) ?? []), by])].sort())
    }
    const kept = entry.utilities.filter(utility => !moved.has(utility) && !unknown.has(utility))
    const dropped = entry.utilities.filter(utility => unknown.has(utility))
    lines.push(`/* ${describe(entry)}${notes.length ? `; ${notes.join('; ')}` : ''} */`)
    if (kept.length)
      lines.push(`${scope}:where(${subject}) {`, `  @apply ${logicalClasses(kept.join(' '))};`, '}')
    if (dropped.length) {
      lines.push(
        `/* NOTE: upstream's list also has ${dropped.join(', ')}, which Tailwind has no utility for: ${plural(dropped.length, 'it styles', 'they style')} nothing on ui.shadcn.com, and @apply would fail on ${plural(dropped.length, 'it', 'them')}, so ${plural(dropped.length, 'it is', 'they are')} left out. */`,
      )
    }
    lines.push(...warnings)
    for (const { utility, by, styles } of overridden.filter(o => !o.every)) {
      lines.push(
        `/* NOTE: upstream's later .${by} overrides ${utility} in ${styles.join(', ')}, which this rule can't express; handle it in ${plural(styles.length, 'that style', 'those styles')}. */`,
      )
    }
    const groups = new Map()
    for (const [utility, classes] of moved) {
      if (unknown.has(utility)) continue
      const key = classes.join(' ')
      groups.set(key, [...(groups.get(key) ?? []), utility])
    }
    for (const [key, utilities] of groups) {
      const classes = key.split(' ')
      lines.push(
        '',
        `/* ${describe(entry)}: upstream's later ${classes.map(c => `.${c}`).join(', ')} ${plural(classes.length, 'overrides', 'override')} ${plural(utilities.length, 'this', 'these')} in every style */`,
        `${scope}:where(${subject}${classes.map(c => `:not(.${c})`).join('')}) {`,
        `  @apply ${logicalClasses(utilities.join(' '))};`,
        '}',
      )
    }
  }
  return `${lines.join('\n')}\n`
}

async function main(argv) {
  const flag = name => argv.includes(name)
  const option = name => {
    const index = argv.indexOf(name)
    return index === -1 ? undefined : argv[index + 1]
  }
  const optionValues = new Set(['--file', '--out'].map(option).filter(Boolean))
  const name = argv.find(arg => !arg.startsWith('--') && !optionValues.has(arg))
  const file = option('--file')
    ? resolve(option('--file'))
    : name && join(checkoutDir('shadcn-ui'), PATHS.ui, `${name}.tsx`)
  if (!file) {
    console.error(
      'usage: node scripts/extract-classes.mjs <component> | --file <path.tsx> [--json] [--out <file>]',
    )
    process.exitCode = 1
    return
  }
  let commit
  try {
    commit = JSON.parse(readFileSync(join(repoRoot, 'upstream.json'), 'utf8'))['shadcn-ui'].commit
  } catch {
    commit = undefined
  }
  const sheets = readSheets(checkoutDir('shadcn-ui')) ?? null
  if (!sheets) {
    console.error(
      'extract-classes: the upstream style sheets are missing (`node scripts/upstream.mjs fetch`), so later classes are not checked',
    )
  }
  const extracted = extractClasses(readFileSync(file, 'utf8'), basename(file))
  const entries = sheets ? findOverrides(extracted, sheets) : extracted
  let unknown
  if (existsSync(TAILWIND_SETUP.tailwind)) {
    unknown = await unknownUtilities(entries.flatMap(entry => entry.utilities))
  } else {
    console.error(
      "extract-classes: packages/ember's Tailwind is missing (`pnpm install`), so classes Tailwind doesn't know are not left out",
    )
  }
  const output = flag('--json')
    ? `${JSON.stringify(entries, null, 2)}\n`
    : renderCss(entries, { name: name ?? basename(file, '.tsx'), commit, sheets, unknown })
  if (option('--out')) writeFileSync(resolve(option('--out')), output)
  else process.stdout.write(output)
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    await main(process.argv.slice(2))
  } catch (error) {
    console.error(error.message)
    process.exitCode = 1
  }
}
