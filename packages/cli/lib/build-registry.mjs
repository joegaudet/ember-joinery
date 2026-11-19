#!/usr/bin/env node
// Builds the registry the CLI copies from: every component in @ember-joinery/ember's
// src/components, the -private files they import, and manifest.json, which says what each
// component needs. The package's `build` and `prepack` run it, so the tarball carries the
// source of its own version. The registry is build output (gitignored).
//
//   node lib/build-registry.mjs   from packages/cli: reads ../ember, writes ./registry
//
// manifest.json:
//
//   {
//     "version": "1.2.0",
//     "dependencies": { "@ember-joinery/primitives": "^1.2.0", "lucide": "^0.474.0" },
//     "items": {
//       "dialog": {
//         "files": ["components/dialog.gts", "-private/static-part.gts"],
//         "registryDependencies": ["button", "icon"],   // components it imports
//         "dependencies": ["@ember-joinery/primitives"] // npm packages its files import
//       }
//     }
//   }
//
// Paths are relative to src/, and a copy keeps that layout, so relative imports stay valid.
import { cpSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs'
import { dirname, join, posix, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

/** The package an import specifier names: `@scope/name/sub` → `@scope/name`, `lucide` → `lucide`. */
const packageName = spec =>
  spec
    .split('/')
    .slice(0, spec.startsWith('@') ? 2 : 1)
    .join('/')

/** The specifiers of a module's static imports and re-exports, in either kind of quotes. */
export const imports = source =>
  [
    // Without comments, whose quotes (`it's`) would end a match early. No specifier holds `//`.
    ...source
      .replace(/\/\*[\s\S]*?\*\//g, '')
      .replace(/\/\/[^\n]*/g, '')
      .matchAll(
        /^\s*(?:import|export)\b[^'"]*?\bfrom\s+(['"])([^'"]+)\1|^\s*import\s+(['"])([^'"]+)\3/gm,
      ),
  ].map(match => match[2] ?? match[4])

export function buildRegistry({ emberDir, outDir, version }) {
  const src = join(emberDir, 'src')
  const ember = JSON.parse(readFileSync(join(emberDir, 'package.json'), 'utf8'))
  version ??= ember.version

  // The npm packages a copy may import: the ones @ember-joinery/ember itself depends on.
  // Ember, Glimmer and Glint come with the app.
  const dependencies = {}
  for (const [name, range] of Object.entries(ember.dependencies)) {
    dependencies[name] = name.startsWith('@ember-joinery/') ? `^${version}` : range
  }

  const items = {}
  const names = readdirSync(join(src, 'components'))
    .filter(name => name.endsWith('.gts'))
    .map(name => name.slice(0, -'.gts'.length))
    .sort()

  for (const name of names) {
    const files = []
    const components = new Set()
    const packages = new Set()
    const visit = file => {
      if (files.includes(file)) return
      files.push(file)
      for (const spec of imports(readFileSync(join(src, file), 'utf8'))) {
        if (spec.startsWith('.')) {
          const target = posix.join(posix.dirname(file), spec)
          const component = target.match(/^components\/([^/]+)\.gts$/)?.[1]
          if (component && component !== name) components.add(component)
          else if (!component) visit(target)
        } else if (dependencies[packageName(spec)]) {
          packages.add(packageName(spec))
        }
      }
    }
    visit(`components/${name}.gts`)
    items[name] = {
      files,
      registryDependencies: [...components].sort(),
      dependencies: [...packages].sort(),
    }
  }

  const used = new Set(Object.values(items).flatMap(item => item.dependencies))
  const manifest = {
    version,
    dependencies: Object.fromEntries(
      Object.entries(dependencies).filter(([name]) => used.has(name)),
    ),
    items,
  }

  rmSync(outDir, { recursive: true, force: true })
  for (const file of new Set(Object.values(items).flatMap(item => item.files))) {
    mkdirSync(dirname(join(outDir, 'files', file)), { recursive: true })
    cpSync(join(src, file), join(outDir, 'files', file))
  }
  writeFileSync(join(outDir, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`)
  return manifest
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const pkg = resolve(dirname(fileURLToPath(import.meta.url)), '..')
  const { version } = JSON.parse(readFileSync(join(pkg, 'package.json'), 'utf8'))
  buildRegistry({ emberDir: join(pkg, '../ember'), outDir: join(pkg, 'registry'), version })
}
