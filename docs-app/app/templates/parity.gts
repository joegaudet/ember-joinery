import { modifier } from 'ember-modifier'
import type { TOC } from '@ember/component/template-only'
import type ParityController from '../controllers/parity.ts'
import type { ParityModel } from '../routes/parity.ts'

/** How many stages have the page pinned: a new stage can install before the old one goes. */
let pinned = 0

/**
 * Pins the page to the scheme the comparison asks for, until the route exits: `.dark` (as
 * shadcn's class darkens everything) or `.light`, plus `color-scheme`, so neither the guide's
 * own colours nor native controls follow the browser's or the OS's preference instead. A new
 * style renders a new stage (the controller's stageKey), whose pin may come before the old
 * one's unpin, so the page is unpinned only when the last stage goes.
 */
const scheme = modifier((_element: Element, [theme]: [string]) => {
  const root = document.documentElement
  const dark = theme === 'dark'
  pinned++
  root.classList.toggle('dark', dark)
  root.classList.toggle('light', !dark)
  root.style.colorScheme = dark ? 'dark' : 'light'
  return () => {
    if (--pinned > 0) return
    root.classList.remove('dark', 'light')
    root.style.removeProperty('color-scheme')
  }
})

const isDark = (theme: string) => theme === 'dark'

const Parity: TOC<{ Args: { model: ParityModel; controller: ParityController } }> = <template>
  {{#if @model.example}}
    {{#each @controller.stageKey key="@identity"}}
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
    {{/each}}
  {{else}}
    <p class="parity-missing" role="alert" data-parity-missing={{@model.name}}>
      No example named “{{@model.name}}” in docs-app/app/examples.
    </p>
  {{/if}}
</template>

export default Parity
