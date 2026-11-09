#!/usr/bin/env node
// Pulls the utility classes upstream writes inline in a component (in its `cn(...)` and
// `cva(...)` calls and `className` strings) out of its ui source, so they can go into the
// component's base rule next to the ported style sheet's (see "Styling pipeline" in
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
// Upstream merges the style sheet's classes first and these inline ones after them
// (tailwind-merge keeps the later one), so where both set the same property the inline class
// wins. Put the extracted rules after the ported sheet's to keep that order.
//
// Strings that only apply under a condition (`isActive && "…"`, `a ? "…" : "…"`) are reported
// with their condition and left as comments in the CSS: the component decides how to express
// them (usually a data attribute).

import { readFileSync, writeFileSync } from 'node:fs'
import { basename, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
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

function stringValue(node) {
  if (ts.isStringLiteral(node) || ts.isNoSubstitutionTemplateLiteral(node)) return node.text
  return undefined
}

/** The JSX element a node sits in: its tag and its `data-slot`, if it has one. */
function enclosingElement(node, source) {
  for (let current = node.parent; current; current = current.parent) {
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
      return { element: current.tagName.getText(source), slot }
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

function propertyName(property, source) {
  return property.name && (ts.isIdentifier(property.name) || ts.isStringLiteral(property.name))
    ? property.name.text
    : property.name?.getText(source)
}

function objectProperty(object, name, source) {
  return object.properties.find(
    property => ts.isPropertyAssignment(property) && propertyName(property, source) === name,
  )
}

/**
 * Every class string in a ui source, in source order. Each entry says where it came from
 * (`cn`, `cva`, `cva-variant`, `cva-compound` or `className`), the element and `data-slot` it
 * styles when that can be told, and its classes split as `splitClasses` does.
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
  const add = (node, origin, found, extra = {}) => {
    for (const { value, condition } of found) {
      const classes = splitClasses(value)
      if (!classes.semantic.length && !classes.utilities.length && !classes.markers.length) continue
      entries.push({
        origin,
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
        for (const argument of node.arguments) {
          const found = []
          collectStrings(argument, source, undefined, found)
          add(argument, 'cn', found)
        }
      } else if (callee === 'cva') {
        const [base, config] = node.arguments
        if (base) {
          const found = []
          collectStrings(base, source, undefined, found)
          add(base, 'cva', found)
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
                add(option, 'cva-variant', found, {
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
                add(property, 'cva-compound', found, { variant: when })
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
      if (literal !== undefined) add(node, 'className', [{ value: literal }])
    }
    ts.forEachChild(node, visit)
  }
  visit(source)
  return entries
}

/** The rule's selector: the string's first semantic class, or its element's `data-slot`. */
function selectorFor(entry) {
  if (entry.semantic.length) return `:where(.${entry.semantic[0]})`
  if (entry.slot) return `:where(.jn-${entry.slot})`
  return undefined
}

function describe(entry) {
  const where = [
    entry.slot && `data-slot="${entry.slot}"`,
    entry.function && `in ${entry.function}`,
    entry.variant && `(${entry.origin} ${entry.variant})`,
  ]
  return where.filter(Boolean).join(' ') || entry.origin
}

/**
 * The inline utilities as CSS: one `@apply` rule per class string that has a slot, with the
 * markers and anything conditional or slot-less left as comments for the component to handle.
 */
export function renderCss(entries, { name, commit }) {
  const lines = [
    '/*',
    ` * Inline utilities from ${PATHS.ui}/${name}.tsx${commit ? ` (shadcn-ui/ui@${commit.slice(0, 7)})` : ''},`,
    " * extracted by scripts/extract-classes.mjs. They come after the style sheet's rules, as upstream",
    ' * merges them.',
    ' */',
  ]
  for (const entry of entries) {
    const selector = selectorFor(entry)
    const notes = []
    if (entry.markers.length) notes.push(`keep on the element: ${entry.markers.join(' ')}`)
    if (entry.semantic.length > 1) notes.push(`also: ${entry.semantic.slice(1).join(' ')}`)
    if (!entry.utilities.length) {
      if (notes.length) lines.push('', `/* ${selector ?? describe(entry)}: ${notes.join('; ')} */`)
      continue
    }
    lines.push('')
    if (entry.condition || !selector) {
      const why = entry.condition ? `only when ${entry.condition}` : 'no slot to attach it to'
      lines.push(`/* ${describe(entry)}, ${why}: ${entry.utilities.join(' ')} */`)
      continue
    }
    lines.push(`/* ${describe(entry)}${notes.length ? `; ${notes.join('; ')}` : ''} */`)
    lines.push(`${selector} {`, `  @apply ${entry.utilities.join(' ')};`, '}')
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
  const entries = extractClasses(readFileSync(file, 'utf8'), basename(file))
  const output = flag('--json')
    ? `${JSON.stringify(entries, null, 2)}\n`
    : renderCss(entries, { name: name ?? basename(file, '.tsx'), commit })
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
