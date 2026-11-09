import { modifier } from 'ember-modifier'
import type { TOC } from '@ember/component/template-only'
import type ParityController from '../controllers/parity.ts'
import type { ParityModel } from '../routes/parity.ts'

/** `theme=dark` darkens the whole page, as shadcn's `.dark` class does, until the route exits. */
const scheme = modifier((_element: Element, [theme]: [string]) => {
  const root = document.documentElement
  root.classList.toggle('dark', theme === 'dark')
  return () => root.classList.remove('dark')
})

const Parity: TOC<{ Args: { model: ParityModel; controller: ParityController } }> = <template>
  {{#if @model.example}}
    <div
      class="parity-stage"
      data-parity={{@model.name}}
      data-align={{@controller.align}}
      dir={{@controller.dir}}
      {{scheme @controller.theme}}
    >
      <@model.example.component />
    </div>
  {{else}}
    <p class="parity-missing" role="alert" data-parity-missing={{@model.name}}>
      No example named “{{@model.name}}” in docs-app/app/examples.
    </p>
  {{/if}}
</template>

export default Parity
