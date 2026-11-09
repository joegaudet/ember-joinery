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
// The order the rules go in matters. Upstream builds an element's class list in call order: a
// cva()'s base string (its semantic class, then its inline utilities), then each variant's
// string (the variant's or size's semantic class, then any utilities after it), then the
// compound variants; a cn() call likewise runs argument by argument. The registry build swaps
// each semantic class for its style rule's utilities in place, and tailwind-merge (`cn`) keeps
// the later of two conflicting classes. So an inline utility beats its own string's style rule
// (`.jn-badge`), but a later string's style rule (`.jn-badge-variant-destructive`) beats it.
//
// Joinery's rules are all `:where()`, so source order decides between them. The extracted rules
// go after the ported style sheet, which gets the first case right. For the second, the script
// reads all eight upstream style sheets and checks each inline utility against the style rules
// of the strings after it in the same call (leaving out those that can't apply together, such
// as two options of one variant). A utility that a later class overrides in every style moves
// out of the base rule into one that skips that class,
// `:where(.jn-badge:not(.jn-badge-variant-destructive))`. One that only some styles override
// stays in the base rule, under a NOTE naming the styles where it comes out wrong.
//
// Strings that only apply under a condition (`isActive && "…"`, `a ? "…" : "…"`) are reported
// with their condition and left as comments in the CSS: the component decides how to express
// them (usually a data attribute).

import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs'
import { basename, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { twMerge } from 'cn'
import ts from 'typescript'
import { PATHS, checkoutDir, repoRoot } from './upstream.mjs'

const MARKER = /^(group|peer)(\/[\w-]+)?$/

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
  const add = (node, origin, call, found, extra = {}) => {
    for (const { value, condition } of found) {
      const classes = splitClasses(value)
      if (!classes.semantic.length && !classes.utilities.length && !classes.markers.length) continue
      entries.push({
        origin,
        call,
        function: enclosingFunction(node),
        ...enclosingElement(node, source),
        ...extra,
        ...(condition && { condition }),
        ...classes,
      })
    }
  }

  const visit = node => {
    if (ts.isCallExpression(node) && ts.isIdentifier(node.expression)) {
      const callee = node.expression.text
      if (callee === 'cn') {
        const call = calls++
        for (const argument of node.arguments) {
          const found = []
          collectStrings(argument, source, undefined, found)
          add(argument, 'cn', call, found)
        }
      } else if (callee === 'cva') {
        const call = calls++
        const [base, config] = node.arguments
        if (base) {
          const found = []
          collectStrings(base, source, undefined, found)
          add(base, 'cva', call, found)
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
                add(option, 'cva-variant', call, found, {
                  variant: `${propertyName(group, source)}.${propertyName(option, source)}`,
                })
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
                add(property, 'cva-compound', call, found, { variant: when })
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
      if (literal !== undefined) add(node, 'className', calls++, [{ value: literal }])
    }
    ts.forEachChild(node, visit)
  }
  visit(source)
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
      if (later.call !== entry.call || exclusive(entry, later)) continue
      for (const className of later.semantic) {
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
 * The rule's subject: the string's first semantic class; for a later string of a cn() call
 * without one, the call's (every string of a call styles the same element); or else the
 * element's `data-slot`.
 */
function subjectFor(entry, entries) {
  if (entry.semantic.length) return `.${entry.semantic[0]}`
  if (entry.origin === 'cn') {
    const named = entries.find(other => other.call === entry.call && other.semantic.length)
    if (named && entries.indexOf(named) < entries.indexOf(entry)) return `.${named.semantic[0]}`
  }
  if (entry.slot) return `.jn-${entry.slot}`
  return undefined
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

/**
 * The inline utilities as CSS: one `@apply` rule per class string that has a slot, with the
 * markers and anything conditional or slot-less left as comments for the component to handle.
 * Entries that went through `findOverrides` also get the `:not()` rules and NOTEs it calls for.
 * `sheets: null` says the style sheets weren't there to check against.
 */
export function renderCss(entries, { name, commit, sheets } = {}) {
  const lines = [
    '/*',
    ` * Inline utilities from ${PATHS.ui}/${name}.tsx${commit ? ` (shadcn-ui/ui@${commit.slice(0, 7)})` : ''},`,
    " * extracted by scripts/extract-classes.mjs. They go after the style sheet's rules: in upstream's",
    " * class list each follows its own string's semantic class, so it wins over that class's rule.",
    ' * Where a later class of the same call (a variant, a size) overrides one, its rule skips that',
    ' * class with :not().',
    ...(sheets === null
      ? [' * The style sheets were missing, so later classes were not checked.']
      : []),
    ' */',
  ]
  for (const entry of entries) {
    const subject = subjectFor(entry, entries)
    const notes = []
    if (entry.markers.length) notes.push(`keep on the element: ${entry.markers.join(' ')}`)
    if (entry.semantic.length > 1) notes.push(`also: ${entry.semantic.slice(1).join(' ')}`)
    if (!entry.utilities.length) {
      if (notes.length) {
        lines.push(
          '',
          `/* ${subject ? `:where(${subject})` : describe(entry)}: ${notes.join('; ')} */`,
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
        `/* ${describe(entry)}, ${why}: ${entry.utilities.join(' ')}${later.length ? `; later in the call, ${later.join(', ')}` : ''} */`,
      )
      continue
    }

    // A utility a later class overrides in every style moves to a rule that skips that class.
    const moved = new Map()
    for (const { utility, by, every } of overridden) {
      if (every) moved.set(utility, [...new Set([...(moved.get(utility) ?? []), by])].sort())
    }
    const kept = entry.utilities.filter(utility => !moved.has(utility))
    lines.push(`/* ${describe(entry)}${notes.length ? `; ${notes.join('; ')}` : ''} */`)
    if (kept.length) lines.push(`:where(${subject}) {`, `  @apply ${kept.join(' ')};`, '}')
    for (const { utility, by, styles } of overridden.filter(o => !o.every)) {
      lines.push(
        `/* NOTE: upstream's later .${by} overrides ${utility} in ${styles.join(', ')}, which this rule can't express; handle it in ${plural(styles.length, 'that style', 'those styles')}. */`,
      )
    }
    const groups = new Map()
    for (const [utility, classes] of moved) {
      const key = classes.join(' ')
      groups.set(key, [...(groups.get(key) ?? []), utility])
    }
    for (const [key, utilities] of groups) {
      const classes = key.split(' ')
      lines.push(
        '',
        `/* ${describe(entry)}: upstream's later ${classes.map(c => `.${c}`).join(', ')} ${plural(classes.length, 'overrides', 'override')} ${plural(utilities.length, 'this', 'these')} in every style */`,
        `:where(${subject}${classes.map(c => `:not(.${c})`).join('')}) {`,
        `  @apply ${utilities.join(' ')};`,
        '}',
      )
    }
  }
  return `${lines.join('\n')}\n`
}

function main(argv) {
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
  const output = flag('--json')
    ? `${JSON.stringify(entries, null, 2)}\n`
    : renderCss(entries, { name: name ?? basename(file, '.tsx'), commit, sheets })
  if (option('--out')) writeFileSync(resolve(option('--out')), output)
  else process.stdout.write(output)
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    main(process.argv.slice(2))
  } catch (error) {
    console.error(error.message)
    process.exitCode = 1
  }
}
