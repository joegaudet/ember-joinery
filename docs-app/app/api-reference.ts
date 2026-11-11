/**
 * The Reference section's index of a package: its public modules and what each exports, read
 * from the package's TypeDoc JSON (the file Kolay writes for `<APIDocs>`, refined by
 * api-docs.mjs). Each export says where Kolay finds its declaration, so the page can render it
 * with `<APIDocs>` or `<ComponentSignature>`.
 */

/** TypeDoc's ReflectionKind values read here. */
const KIND = {
  Module: 2,
  Enum: 8,
  Variable: 32,
  Function: 64,
  Class: 128,
  Interface: 256,
  TypeAlias: 2097152,
  Reference: 4194304,
} as const

/** The part of a TypeDoc reflection's JSON read here. */
export interface Reflection {
  id: number
  name: string
  kind: number
  target?: number
  children?: Reflection[]
  type?: { type: string; name?: string; package?: string; target?: unknown; typeArguments?: Type[] }
  extendedTypes?: Type[]
  comment?: { summary?: { kind: string; text: string }[] }
}

interface Type {
  type: string
  name?: string
  package?: string
  target?: unknown
  typeArguments?: Type[]
}

export type ExportKind =
  | 'component'
  | 'modifier'
  | 'helper'
  | 'class'
  | 'function'
  | 'interface'
  | 'type'
  | 'enum'
  | 'constant'

/** One thing a module exports, and where Kolay finds its declaration. */
export interface ApiExport {
  /** The name it is imported by. */
  name: string
  kind: ExportKind
  /** The TypeDoc module that declares it, as `<APIDocs @module>` takes it. */
  module: string
  /** Its name in that module. */
  declaration: string
  /** For a component, the signature interface its docs render from, when it names one. */
  signature?: { module: string; name: string }
  /** The class it extends, for a class. */
  extends?: string
  /** The first sentence of its doc comment, as text. */
  summary?: string
}

/** A public module: what an app imports, and from where. */
export interface ApiModule {
  /** Its path in the package, `components/button`. */
  id: string
  /** Where its exports are imported from: the package, or its test support. */
  importFrom: string
  exports: ApiExport[]
}

const ORDER: ExportKind[] = [
  'component',
  'modifier',
  'helper',
  'class',
  'function',
  'interface',
  'type',
  'enum',
  'constant',
]

const COMPONENT_TYPES = new Set(['TOC', 'TemplateOnlyComponent', 'ComponentLike'])
const MODIFIER_TYPES = new Set(['FunctionBasedModifier', 'PartModifier', 'ModifierLike'])

/** The module path without the declarations folder: `declarations/components/button` → `components/button`. */
function pathOf(moduleName: string): string {
  const slash = moduleName.indexOf('/')
  return slash === -1 ? '' : moduleName.slice(slash + 1)
}

/** Whether a module is the package's own, public: not a `-private` folder or an `_` file. */
function isPublic(moduleName: string): boolean {
  if (moduleName.includes(' (re-exports')) return false
  return !pathOf(moduleName)
    .split('/')
    .some(segment => segment.startsWith('-') || segment.startsWith('_'))
}

/** The text of a comment's first paragraph, with inline code kept as written. */
function summaryOf(reflection: Reflection): string | undefined {
  const parts = reflection.comment?.summary
  if (!parts?.length) return undefined
  const text = parts
    .map(part => part.text)
    .join('')
    .split(/\n\s*\n/)[0]!
    .replace(/\s+/g, ' ')
    .trim()
  return text || undefined
}

export function indexPackage(packageName: string, project: Reflection): ApiModule[] {
  const modules = (project.children ?? []).filter(child => child.kind === KIND.Module)
  // The barrel: the package's index, which re-exports every module (`declarations`, `dist`).
  const barrel = modules.find(module => !module.name.includes('/'))
  const names = new Set(modules.map(module => module.name))

  const byId = new Map<number, { reflection: Reflection; module: Reflection }>()
  for (const module of modules) {
    for (const child of module.children ?? []) byId.set(child.id, { reflection: child, module })
  }

  /** The names the barrel exports things by, so a default export reads as its import name. */
  const barrelName = new Map<number, string>()
  for (const child of barrel?.children ?? []) {
    barrelName.set(child.kind === KIND.Reference ? (child.target ?? -1) : child.id, child.name)
  }

  const resolve = (reflection: Reflection, depth = 0): Reflection | undefined => {
    if (reflection.kind !== KIND.Reference) return reflection
    const target = reflection.target === undefined ? undefined : byId.get(reflection.target)
    return target && depth < 8 ? resolve(target.reflection, depth + 1) : undefined
  }

  const isComponentClass = (reflection: Reflection, depth = 0): boolean => {
    const base = reflection.extendedTypes?.[0]
    if (!base || depth > 8) return false
    if (base.package === '@glimmer/component') return true
    const target = typeof base.target === 'number' ? byId.get(base.target) : undefined
    return target ? isComponentClass(target.reflection, depth + 1) : false
  }

  const kindOf = (reflection: Reflection): ExportKind => {
    switch (reflection.kind) {
      case KIND.Class:
        if (isComponentClass(reflection)) return 'component'
        return reflection.extendedTypes?.[0]?.package === 'ember-modifier' ? 'modifier' : 'class'
      case KIND.Variable: {
        const name = reflection.type?.type === 'reference' ? reflection.type.name : undefined
        if (name && COMPONENT_TYPES.has(name)) return 'component'
        if (name && MODIFIER_TYPES.has(name)) return 'modifier'
        return 'constant'
      }
      case KIND.Function:
        return 'function'
      case KIND.Interface:
        return 'interface'
      case KIND.TypeAlias:
        return 'type'
      case KIND.Enum:
        return 'enum'
      default:
        return 'constant'
    }
  }

  /** A component's signature interface, when its type names one: `Component<ButtonSignature>`. */
  const signatureOf = (reflection: Reflection): ApiExport['signature'] => {
    const argument =
      reflection.kind === KIND.Class
        ? reflection.extendedTypes?.[0]?.typeArguments?.[0]
        : reflection.type?.typeArguments?.[0]
    if (argument?.type !== 'reference' || typeof argument.target !== 'number') return undefined
    const target = byId.get(argument.target)
    if (!target || target.reflection.kind !== KIND.Interface) return undefined
    return { module: target.module.name, name: target.reflection.name }
  }

  /**
   * Whether a module sits beside a folder's index (`anchor/modifier.d.ts` beside
   * `anchor/index.d.ts`, which TypeDoc names `anchor`): its exports are the folder's own, and
   * only what the index exports is public.
   */
  const insideFolder = (moduleName: string): boolean => {
    const segments = moduleName.split('/')
    for (let length = 2; length < segments.length; length++) {
      if (names.has(segments.slice(0, length).join('/'))) return true
    }
    return false
  }

  const groups = new Map<string, Map<number, ApiExport>>()
  for (const module of modules) {
    if (module === barrel || !isPublic(module.name) || insideFolder(module.name)) continue
    const exports = new Map<number, ApiExport>()
    groups.set(module.name, exports)
    for (const child of module.children ?? []) {
      const declaration = resolve(child)
      if (!declaration || exports.has(declaration.id)) continue
      const home = byId.get(declaration.id)?.module ?? module
      const kind = kindOf(declaration)
      const base = declaration.extendedTypes?.[0]?.name
      exports.set(declaration.id, {
        name:
          barrelName.get(declaration.id) ??
          (child.name === 'default' ? declaration.name : child.name),
        kind,
        module: home.name,
        declaration: declaration.name,
        ...(kind === 'component' && { signature: signatureOf(declaration) }),
        ...(kind === 'class' && base && { extends: base }),
        summary: summaryOf(declaration),
      })
    }
  }

  const testSupport = (id: string) => id === 'test-support' || id.startsWith('test-support/')
  return [...groups]
    .map(([name, exports]) => {
      const id = pathOf(name)
      return {
        id,
        importFrom:
          testSupport(id) && !packageName.endsWith('/test-support')
            ? `${packageName}/test-support`
            : packageName,
        exports: [...exports.values()].sort(
          (a, b) => ORDER.indexOf(a.kind) - ORDER.indexOf(b.kind) || a.name.localeCompare(b.name),
        ),
      }
    })
    .filter(module => module.exports.length > 0)
    .sort((a, b) => a.id.localeCompare(b.id))
}
