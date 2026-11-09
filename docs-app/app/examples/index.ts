import type { ComponentLike } from '@glint/template'

/**
 * The guide's examples: one `.gts` file each in this folder, named `<component>-<example>`
 * after the upstream example it ports, with its test in docs-app/tests/examples/<name>-test.gts.
 * An example's default export is the component the guide shows. Everything loads on demand,
 * so a page pulls in only the examples it shows.
 */
export interface ExampleModule {
  default: ComponentLike
}

export interface LoadedExample {
  name: string
  component: ComponentLike
  /** The example file, exactly: the frame's Template tab. */
  source: string
  /** Its test file, exactly: the frame's Test tab. */
  test: string | undefined
}

const modules = import.meta.glob<ExampleModule>('./*.gts')
const sources = import.meta.glob<string>('./*.gts', { query: '?raw', import: 'default' })
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

export function hasExample(name: string): boolean {
  return `./${name}.gts` in modules
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
  return { name, component: module.default, source, test }
}
