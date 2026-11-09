import { modifier } from 'ember-modifier'
import type { TOC } from '@ember/component/template-only'
import type ParityController from '../controllers/parity.ts'
import type { ParityModel } from '../routes/parity.ts'

/**
 * Pins the page to the scheme the comparison asks for, until the route exits: `.dark` (as
 * shadcn's class darkens everything) or `.light`, plus `color-scheme`, so neither the guide's
 * own colours nor native controls follow the browser's or the OS's preference instead.
 */
const scheme = modifier((_element: Element, [theme]: [string]) => {
  const root = document.documentElement
  const dark = theme === 'dark'
  root.classList.toggle('dark', dark)
  root.classList.toggle('light', !dark)
  root.style.colorScheme = dark ? 'dark' : 'light'
  return () => {
    root.classList.remove('dark', 'light')
    root.style.removeProperty('color-scheme')
  }
})

const isDark = (theme: string) => theme === 'dark'

const Parity: TOC<{ Args: { model: ParityModel; controller: ParityController } }> = <template>
  {{#if @model.example}}
    <div
      class="parity-stage guide-stage {{if (isDark @controller.theme) 'dark'}}"
      data-parity={{@model.name}}
      data-align={{@controller.align}}
      dir={{@controller.dir}}
      data-style={{@controller.style}}
      style={{@controller.tokens}}
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
