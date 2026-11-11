// The guide's API reference (app/components/package-reference.gts, the Reference pages) reads
// each package's TypeDoc JSON, which Kolay writes from the package's declarations: one TypeDoc
// module per declaration file, at `docs/<package>.json` (kolay/vite's `packages`). This plugin
// refines that JSON on its way to the browser, in the dev server's response and in the built
// file, for what Kolay's renderer and the reference read:
//
// - Module names are unique. TypeDoc names `carousel.d.ts` and `carousel/index.d.ts` both
//   `…/carousel`, and Kolay's `<APIDocs @module>` finds a module by name, so the first one wins:
//   the re-export stub, whose children are references. The module that declares things keeps
//   the name; a stub is renamed `<name> (re-exports)`.
// - A class lists its own members. TypeDoc repeats every inherited member on a subclass, so each
//   harness would list all of `Harness`'s; the reference shows the class it extends instead.
// - An accessor reads as a property. TypeDoc keeps an accessor's type and comment on its getter,
//   which Kolay's renderer doesn't show, so a getter's `label` would render as a bare name.
// - A signature's `Args` lists every argument. Kolay lists the arguments of an object type or an
//   interface, but not of an intersection (`ButtonOptions & { as?: TagName }`), so those are
//   merged into one object type, wherever each part is declared in the package.
// - A doc comment's examples are code. Kolay renders a comment as Markdown compiled to a
//   template, and Joinery's comments show their usage indented, as plain text in an editor
//   (`  <Button @variant="outline">…`): each indented run becomes a fenced code block, rather
//   than markup that names components the comment has no scope for.

import { readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'

/** TypeDoc's ReflectionKind values that the refinements use. */
export const KIND = {
  Module: 2,
  Variable: 32,
  Function: 64,
  Class: 128,
  Interface: 256,
  Property: 1024,
  Method: 2048,
  Accessor: 262144,
  TypeLiteral: 65536,
  TypeAlias: 2097152,
  Reference: 4194304,
}

/** Where Kolay writes a package's TypeDoc JSON, under the guide's base URL. */
export function apiDocsFile(packageName) {
  return `docs/${packageName.replace('/', '__')}.json`
}

/** Whether a URL path (or an emitted file name) is one of these packages' TypeDoc files. */
export function isApiDocsPath(path, packages) {
  return packages.some(name => path === apiDocsFile(name) || path.endsWith(`/${apiDocsFile(name)}`))
}

const declares = module => (module.children ?? []).some(child => child.kind !== KIND.Reference)

/** Gives each module a unique name: the one that declares things keeps it. */
function uniqueModuleNames(project) {
  const byName = new Map()
  for (const module of project.children ?? []) {
    if (!byName.has(module.name)) byName.set(module.name, [])
    byName.get(module.name).push(module)
  }
  for (const [name, modules] of byName) {
    if (modules.length < 2) continue
    const keeper = modules.find(declares) ?? modules[0]
    let n = 0
    for (const module of modules) {
      if (module === keeper) continue
      n++
      module.name = `${name} (re-exports${n > 1 ? ` ${n}` : ''})`
    }
  }
}

/** A class's own members, and its groups pointing at them only. */
function ownMembers(reflection) {
  if (reflection.kind !== KIND.Class || !reflection.children) return
  reflection.children = reflection.children.filter(child => !child.inheritedFrom)
  const kept = new Set(reflection.children.map(child => child.id))
  for (const list of [reflection.groups, reflection.categories]) {
    for (const group of list ?? []) group.children = group.children?.filter(id => kept.has(id))
  }
  if (reflection.groups) reflection.groups = reflection.groups.filter(g => g.children?.length)
}

/** An accessor as a property: its getter's (or setter's) type and comment, read-only unless set. */
function accessorAsProperty(reflection) {
  if (reflection.kind !== KIND.Accessor) return
  const get = reflection.getSignature
  const set = reflection.setSignature
  reflection.kind = KIND.Property
  reflection.type = get?.type ?? set?.parameters?.[0]?.type
  reflection.comment = reflection.comment ?? get?.comment ?? set?.comment
  reflection.flags = { ...reflection.flags, ...(set ? {} : { isReadonly: true }) }
  delete reflection.getSignature
  delete reflection.setSignature
}

/**
 * A comment's text, with each indented run of lines (after a blank line or at the start) made a
 * fenced code block, dedented. TypeDoc splits a comment into text and inline-code parts; they
 * are joined back into one Markdown string.
 */
export function fenceIndentedCode(markdown) {
  const lines = markdown.split('\n')
  const out = []
  let fence = false
  for (let index = 0; index < lines.length; index++) {
    const line = lines[index]
    const indented = /^ {2,}\S/.test(line)
    const startsBlock = indented && !fence && (out.length === 0 || out.at(-1).trim() === '')
    if (startsBlock) {
      const block = []
      while (
        index < lines.length &&
        (/^ {2,}\S/.test(lines[index]) || lines[index].trim() === '')
      ) {
        block.push(lines[index])
        index++
      }
      index--
      while (block.length && block.at(-1).trim() === '') block.pop()
      const indent = Math.min(...block.filter(l => l.trim()).map(l => l.match(/^ */)[0].length))
      const code = block.map(l => l.slice(indent))
      const lang = code.some(l => /<[A-Za-z]|\{\{/.test(l)) ? 'hbs' : 'ts'
      out.push('```' + lang, ...code, '```', '')
      continue
    }
    if (/^\s*```/.test(line)) fence = !fence
    out.push(line)
  }
  return out.join('\n').replace(/\n+$/, '')
}

function refineComment(comment) {
  if (!comment) return
  const parts = [comment.summary, ...(comment.blockTags ?? []).map(tag => tag.content)]
  for (const content of parts) {
    if (!content?.length) continue
    const text = fenceIndentedCode(content.map(part => part.text).join(''))
    content.splice(0, content.length, { kind: 'text', text })
  }
}

/**
 * The members of an intersection's parts, when every part is an object type or an internal
 * interface or object type alias, as one object type; else nothing.
 */
function mergedIntersection(type, byId, nextId) {
  if (type?.type !== 'intersection') return undefined
  const children = []
  for (const part of type.types) {
    let members
    if (part.type === 'reflection') members = part.declaration?.children
    else if (part.type === 'reference' && typeof part.target === 'number') {
      const target = byId.get(part.target)
      members =
        target?.kind === KIND.Interface ? target.children : target?.type?.declaration?.children
    }
    if (!members) return undefined
    for (const member of members) {
      const copy = structuredClone(member)
      reassignIds(copy, nextId)
      const existing = children.findIndex(child => child.name === copy.name)
      if (existing === -1) children.push(copy)
      else children[existing] = copy
    }
  }
  return {
    type: 'reflection',
    declaration: {
      id: nextId(),
      name: '__type',
      variant: 'declaration',
      kind: KIND.TypeLiteral,
      flags: {},
      children,
    },
  }
}

/** Gives a copied reflection, and everything in it, ids of its own. */
function reassignIds(reflection, nextId) {
  if (reflection && typeof reflection === 'object') {
    if (typeof reflection.id === 'number' && typeof reflection.kind === 'number')
      reflection.id = nextId()
    for (const value of Object.values(reflection)) {
      if (Array.isArray(value)) value.forEach(item => reassignIds(item, nextId))
      else if (value && typeof value === 'object') reassignIds(value, nextId)
    }
  }
}

function visit(reflection, fn) {
  fn(reflection)
  for (const child of reflection.children ?? []) visit(child, fn)
  // Members of object types (an interface's `Args: { … }`) are reflections too.
  const declaration = reflection.type?.declaration
  if (declaration) visit(declaration, fn)
}

/** The refinements above, applied to a TypeDoc project's JSON (in place, and returned). */
export function refineApiDocs(project) {
  uniqueModuleNames(project)
  const byId = new Map()
  visit(project, reflection => {
    if (typeof reflection.id === 'number') byId.set(reflection.id, reflection)
  })
  // New ids start above every id in the file, those of reflections nested in types included.
  let maxId = 0
  JSON.stringify(project, (key, value) => {
    if (key === 'id' && typeof value === 'number') maxId = Math.max(maxId, value)
    return value
  })
  const nextId = () => ++maxId
  visit(project, reflection => {
    accessorAsProperty(reflection)
    ownMembers(reflection)
    if (reflection.name === 'Args') {
      const merged = mergedIntersection(reflection.type, byId, nextId)
      if (merged) reflection.type = merged
    }
  })
  visit(project, reflection => {
    refineComment(reflection.comment)
    for (const signature of [
      ...(reflection.signatures ?? []),
      reflection.getSignature,
      reflection.setSignature,
    ]) {
      if (!signature) continue
      refineComment(signature.comment)
      for (const parameter of signature.parameters ?? []) refineComment(parameter.comment)
    }
  })
  return project
}

function refineText(text) {
  return JSON.stringify(refineApiDocs(JSON.parse(text)))
}

/** The refinements, for the packages Kolay is given (its `packages`). */
export function apiDocs({ packages }) {
  return {
    name: 'joinery-guide-api-docs',
    configureServer(server) {
      // Ahead of Kolay's own middleware (which it adds after Vite's), so its response can be
      // refined as it is sent.
      server.middlewares.use((req, res, next) => {
        const path = (req.originalUrl ?? '').split('?')[0]
        if (!isApiDocsPath(path, packages)) return next()
        const end = res.end.bind(res)
        res.end = (body, ...rest) => {
          if (typeof body === 'string' && body.startsWith('{')) body = refineText(body)
          return end(body, ...rest)
        }
        next()
      })
    },
    writeBundle(options, bundle) {
      for (const fileName of Object.keys(bundle)) {
        if (!isApiDocsPath(fileName, packages)) continue
        const path = join(options.dir, fileName)
        writeFileSync(path, refineText(readFileSync(path, 'utf8')))
      }
    },
  }
}
