// Ports shadcn's base colours (apps/v4/registry/themes.ts, filtered by base-colors.ts, at the
// commit pinned in upstream.json) into packages/ember/src/themes/<name>.css, one theme each: the
// light tokens on `:root` and the dark ones on `.dark`, under shadcn's own names, so a theme
// copied from ui.shadcn.com pastes in unchanged. port-styles.mjs runs it (and `--check`s it)
// along with the style sheets. See "Styling pipeline" in JOINERY_PLAN.md.
//
// The TypeScript files are read as data: their object literals are parsed with the TypeScript
// compiler, and nothing upstream is run.

import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import ts from 'typescript'
import { checkoutDir, readPins, repoRoot } from './upstream.mjs'

export const THEMES_DIR = 'packages/ember/src/themes'
export const THEMES_FILE = 'apps/v4/registry/themes.ts'
export const BASE_COLORS_FILE = 'apps/v4/registry/base-colors.ts'

/** A literal's value: strings, numbers, booleans, arrays and objects. Anything else fails. */
function literal(node, file) {
  if (ts.isStringLiteral(node) || ts.isNoSubstitutionTemplateLiteral(node)) return node.text
  if (ts.isNumericLiteral(node)) return Number(node.text)
  if (node.kind === ts.SyntaxKind.TrueKeyword) return true
  if (node.kind === ts.SyntaxKind.FalseKeyword) return false
  if (ts.isArrayLiteralExpression(node)) return node.elements.map(element => literal(element, file))
  if (ts.isObjectLiteralExpression(node)) {
    const object = {}
    for (const property of node.properties) {
      if (!ts.isPropertyAssignment(property)) {
        throw new Error(`${file}: expected plain properties, found ${property.getText()}`)
      }
      const key = ts.isIdentifier(property.name) ? property.name.text : literal(property.name, file)
      object[key] = literal(property.initializer, file)
    }
    return object
  }
  if (
    ts.isAsExpression(node) ||
    ts.isSatisfiesExpression(node) ||
    ts.isParenthesizedExpression(node)
  )
    return literal(node.expression, file)
  throw new Error(`${file}: expected a literal, found ${node.getText()}`)
}

/** The initializer of `export const <name> = …` in a source file. */
function exportedConst(source, name, file) {
  for (const statement of source.statements) {
    if (!ts.isVariableStatement(statement)) continue
    for (const declaration of statement.declarationList.declarations) {
      if (ts.isIdentifier(declaration.name) && declaration.name.text === name) {
        if (!declaration.initializer) break
        return declaration.initializer
      }
    }
  }
  throw new Error(`${file}: no \`export const ${name}\``)
}

/** The THEMES array of themes.ts, as data. */
export function parseThemes(code, file = THEMES_FILE) {
  const source = ts.createSourceFile(file, code, ts.ScriptTarget.Latest, true)
  return literal(exportedConst(source, 'THEMES', file), file)
}

/** The names base-colors.ts filters THEMES by (`["neutral", "stone", …].includes(theme.name)`). */
export function parseBaseColorNames(code, file = BASE_COLORS_FILE) {
  const source = ts.createSourceFile(file, code, ts.ScriptTarget.Latest, true)
  let names
  const visit = node => {
    if (
      !names &&
      ts.isCallExpression(node) &&
      ts.isPropertyAccessExpression(node.expression) &&
      node.expression.name.text === 'includes' &&
      ts.isArrayLiteralExpression(node.expression.expression)
    ) {
      names = literal(node.expression.expression, file)
    }
    ts.forEachChild(node, visit)
  }
  visit(exportedConst(source, 'BASE_COLORS', file))
  if (!names?.length || names.some(name => typeof name !== 'string')) {
    throw new Error(`${file}: expected BASE_COLORS to filter THEMES by a list of names`)
  }
  return names
}

function block(selector, vars) {
  const lines = Object.entries(vars).map(([name, value]) => `  --${name}: ${value};`)
  return [`${selector} {`, ...lines, '}'].join('\n')
}

/** One base colour as CSS: its light tokens on `:root`, its dark ones on `.dark`. */
export function themeCss(theme, commit) {
  const { light, dark } = theme.cssVars ?? {}
  if (!light || !dark)
    throw new Error(`${THEMES_FILE}: ${theme.name} has no light and dark cssVars`)
  return [
    '/*',
    ` * The ${theme.title} base colour, ported from shadcn-ui/ui@${commit.slice(0, 7)}`,
    ` * ${THEMES_FILE} by scripts/port-styles.mjs. Do not edit it: change the script, or`,
    ' * move upstream.json forward and run it again.',
    ' */',
    '',
    block(':root', light),
    '',
    block('.dark', dark),
    '',
  ].join('\n')
}

/** Whether a file is a theme this script ported. */
export function isPortedTheme(css) {
  return /^\/\*\n \* The [\w ]+ base colour, ported from shadcn-ui\/ui@[0-9a-f]+\n/.test(css)
}

/** The base colours, as `{ name, css }`, in upstream's order. */
export function baseColors({ root = repoRoot } = {}) {
  const commit = readPins(root)['shadcn-ui'].commit
  const checkout = checkoutDir('shadcn-ui', root)
  const themesPath = join(checkout, THEMES_FILE)
  if (!existsSync(themesPath)) {
    throw new Error(`${themesPath} is missing; run \`node scripts/upstream.mjs fetch\``)
  }
  const themes = parseThemes(readFileSync(themesPath, 'utf8'))
  const names = parseBaseColorNames(readFileSync(join(checkout, BASE_COLORS_FILE), 'utf8'))
  return names.map(name => {
    const theme = themes.find(candidate => candidate.name === name)
    if (!theme) throw new Error(`${BASE_COLORS_FILE} names ${name}, which ${THEMES_FILE} lacks`)
    return { name, css: themeCss(theme, commit) }
  })
}

/**
 * Writes (or, with `check`, compares) every base colour, and removes (or reports) those left
 * from a base colour upstream no longer has. Returns the names it covered.
 */
export function portThemes({ root = repoRoot, check = false, log = console.log } = {}) {
  const outDir = join(root, THEMES_DIR)
  const colors = baseColors({ root })
  const current = new Set(colors.map(({ name }) => `${name}.css`))
  const stale = []
  if (existsSync(outDir)) {
    for (const file of readdirSync(outDir).sort()) {
      if (!file.endsWith('.css') || current.has(file)) continue
      if (!isPortedTheme(readFileSync(join(outDir, file), 'utf8'))) continue
      if (check) stale.push(`${THEMES_DIR}/${file} (upstream has no such base colour any more)`)
      else {
        rmSync(join(outDir, file))
        log(`removed ${THEMES_DIR}/${file}: upstream has no such base colour any more`)
      }
    }
  }
  for (const { name, css } of colors) {
    const target = join(outDir, `${name}.css`)
    if (check) {
      if (!existsSync(target) || readFileSync(target, 'utf8') !== css)
        stale.push(`${THEMES_DIR}/${name}.css`)
      continue
    }
    mkdirSync(outDir, { recursive: true })
    writeFileSync(target, css)
  }
  if (stale.length) {
    throw new Error(
      `stale ported themes (run \`node scripts/port-styles.mjs\`):\n  ${stale.join('\n  ')}`,
    )
  }
  const names = colors.map(({ name }) => name)
  log(
    `${check ? 'checked' : 'wrote'} ${names.length} base colours in ${THEMES_DIR}: ${names.join(', ')}`,
  )
  return names
}
