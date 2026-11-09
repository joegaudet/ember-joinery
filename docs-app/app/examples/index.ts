import type { ComponentLike } from '@glint/template'

/**
 * The guide's examples: one `.gts` file each in this folder, named `<component>-<example>`
 * after the upstream example it ports, with its test in docs-app/tests/examples/<name>-test.gts.
 * An example's default export is the component the guide shows. Everything loads on demand,
 * so a page pulls in only the examples it shows.
 *
 * Files an example imports from a folder here (`./lazy/revenue-summary.gts`, which it loads
 * on demand) are part of it, not examples: the frame shows them after the example's source.
 */
export interface ExampleModule {
  default: ComponentLike
}

/** A file an example imports from a folder beside it, shown with the example's source. */
export interface ExampleFile {
  /** Its path in docs-app/app/examples: `lazy/revenue-summary.gts`. */
  path: string
  source: string
}

export interface LoadedExample {
  name: string
  component: ComponentLike
  /** The example file, exactly: the frame's Template tab. */
  source: string
  /** The files it imports from the folders here, in the order it names them. */
  files: ExampleFile[]
  /** Its test file, exactly: the frame's Test tab. */
  test: string | undefined
}

const modules = import.meta.glob<ExampleModule>('./*.gts')
const sources = import.meta.glob<string>('./*.gts', { query: '?raw', import: 'default' })
const files = import.meta.glob<string>(['./*/*.gts', './*/*.ts'], {
  query: '?raw',
  import: 'default',
})
const tests = import.meta.glob<string>('../../tests/examples/*-test.gts', {
  query: '?raw',
  import: 'default',
})

/** Every example's name, A–Z. */
export function exampleNames(): string[] {
  return Object.keys(modules)
    .map(path => path.slice(2, -'.gts'.length))
    .sort()
}

/**
 * The name of every example test in docs-app/tests/examples, A–Z. The guide's tests check that
 * it matches exampleNames(), since a frame whose example has no test just drops its Test tab.
 */
export function exampleTestNames(): string[] {
  return Object.keys(tests)
    .map(path => path.slice('../../tests/examples/'.length, -'-test.gts'.length))
    .sort()
}

export function hasExample(name: string): boolean {
  return `./${name}.gts` in modules
}

/** The files in the folders here that `source` imports (statically or with `import()`). */
function importedFiles(source: string): string[] {
  const paths = [...source.matchAll(/(?:from|import\()\s*['"]\.\/([\w-]+\/[\w.-]+)['"]/g)]
  return [...new Set(paths.map(match => `./${match[1]}`))].filter(path => path in files)
}

/** Loads an example with its source and test, or undefined if there's no example by `name`. */
export async function loadExample(name: string): Promise<LoadedExample | undefined> {
  const load = modules[`./${name}.gts`]
  if (!load) return undefined
  const testFile = tests[`../../tests/examples/${name}-test.gts`]
  const [module, source, test] = await Promise.all([
    load(),
    sources[`./${name}.gts`]!(),
    testFile ? testFile() : Promise.resolve(undefined),
  ])
  const imported = await Promise.all(
    importedFiles(source).map(async path => ({
      path: path.slice(2),
      source: await files[path]!(),
    })),
  )
  return { name, component: module.default, source, files: imported, test }
}
