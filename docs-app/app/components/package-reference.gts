import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import { waitForPromise } from '@ember/test-waiters'
import { APIDocs, CommentQuery, ComponentSignature, typedocLoader } from 'kolay'
import { indexPackage, type ApiExport, type ApiModule, type Reflection } from '../api-reference.ts'
import { title } from '../titles.ts'

interface PackageReferenceSignature {
  Element: HTMLDivElement
  Args: {
    /** The package, as Kolay's `packages` lists it in vite.config.mjs. */
    package: string
  }
}

/** Each package's index, fetched once per visit to the guide. */
const indexes = new Map<string, Promise<ApiModule[]>>()

function load(context: object, packageName: string): Promise<ApiModule[]> {
  let index = indexes.get(packageName)
  if (!index) {
    index = (async () => {
      const response = await typedocLoader(context).load(packageName)
      return indexPackage(packageName, (await response.json()) as Reflection)
    })()
    // A failed load is tried again on the next visit.
    index.catch(() => indexes.delete(packageName))
    indexes.set(packageName, index)
  }
  return waitForPromise(index)
}

const MORE = 6

/**
 * A package's API, generated from its type declarations: every public module, each a
 * disclosure that names what it exports and, opened, renders each export's documentation with
 * Kolay's `<APIDocs>` (a component's with `<ComponentSignature>`: its arguments, blocks and
 * element). Only the modules opened render their docs, so a package of five hundred exports
 * loads as quickly as one of five.
 */
export class PackageReference extends Component<PackageReferenceSignature> {
  @tracked modules: ApiModule[] | undefined
  @tracked error: string | undefined
  @tracked open: ReadonlySet<string> = new Set()

  constructor(owner: unknown, args: PackageReferenceSignature['Args']) {
    super(owner as never, args)
    load(this, args.package).then(
      modules => {
        if (!this.isDestroying) this.modules = modules
      },
      (error: unknown) => {
        if (!this.isDestroying) this.error = String(error)
      },
    )
  }

  get exportCount(): number {
    return (this.modules ?? []).reduce((count, module) => count + module.exports.length, 0)
  }

  isOpen = (module: ApiModule) => this.open.has(module.id)
  titleOf = (module: ApiModule) => title(module.id.split('/').at(-1) || this.args.package)
  idOf = (module: ApiModule) => `api-${module.id.replaceAll('/', '-')}`
  firstNames = (module: ApiModule) =>
    module.exports
      .slice(0, MORE)
      .map(entry => entry.name)
      .join(', ')
  moreCount = (module: ApiModule) => Math.max(0, module.exports.length - MORE)
  isComponent = (entry: ApiExport) => entry.kind === 'component'
  /** How an app imports the module's first few exports: values, or else types. */
  importLine = (module: ApiModule) => {
    const isType = (entry: ApiExport) => entry.kind === 'interface' || entry.kind === 'type'
    const values = module.exports.filter(entry => !isType(entry))
    const names = (values.length ? values : module.exports).slice(0, 3).map(entry => entry.name)
    return `import ${values.length ? '' : 'type '}{ ${names.join(', ')} } from '${module.importFrom}'`
  }

  toggle = (module: ApiModule, event: Event) => {
    const open = new Set(this.open)
    if ((event.target as HTMLDetailsElement).open) open.add(module.id)
    else open.delete(module.id)
    this.open = open
  }

  <template>
    <div class="api-reference" data-test-api-reference={{@package}} ...attributes>
      {{#if this.error}}
        <p class="guide-error" role="alert">Couldn’t load the API of
          {{@package}}:
          {{this.error}}</p>
      {{else if this.modules}}
        <p class="api-reference-count" data-test-api-count>
          {{this.modules.length}}
          modules,
          {{this.exportCount}}
          exports. Open a module for its documentation.
        </p>
        {{#each this.modules as |module|}}
          <details
            class="api-module"
            id={{this.idOf module}}
            data-test-api-module={{module.id}}
            {{on "toggle" (fn this.toggle module)}}
          >
            <summary>
              <h2 class="api-module-title">{{this.titleOf module}}</h2>
              <code class="api-module-path">{{module.id}}</code>
              <span class="api-module-exports">
                {{this.firstNames module}}{{#if (this.moreCount module)}}, and
                  {{this.moreCount module}}
                  more{{/if}}
              </span>
            </summary>
            {{#if (this.isOpen module)}}
              <div class="api-module-body">
                <pre class="api-import"><code>{{this.importLine module}}</code></pre>
                {{#each module.exports as |entry|}}
                  <section class="api-export" data-test-api-export={{entry.name}}>
                    <h3 class="api-export-name">
                      <code>{{entry.name}}</code>
                      <span class="api-kind" data-test-api-kind>{{entry.kind}}</span>
                      {{#if entry.extends}}
                        <span class="api-extends">extends <code>{{entry.extends}}</code></span>
                      {{/if}}
                    </h3>
                    {{#if (this.isComponent entry)}}
                      <CommentQuery
                        @package={{@package}}
                        @module={{entry.module}}
                        @name={{entry.declaration}}
                      />
                      {{#if entry.signature}}
                        <ComponentSignature
                          @package={{@package}}
                          @module={{entry.signature.module}}
                          @name={{entry.signature.name}}
                        />
                      {{else}}
                        <ComponentSignature
                          @package={{@package}}
                          @module={{entry.module}}
                          @name={{entry.declaration}}
                        />
                      {{/if}}
                    {{else}}
                      <APIDocs
                        @package={{@package}}
                        @module={{entry.module}}
                        @name={{entry.declaration}}
                      />
                    {{/if}}
                  </section>
                {{/each}}
              </div>
            {{/if}}
          </details>
        {{/each}}
      {{else}}
        <p class="guide-loading" role="status">Loading the API of {{@package}}…</p>
      {{/if}}
    </div>
  </template>
}
