import { toast } from '@ember-joinery/ember'

/**
 * Upstream's toast of the values a form submitted, as JSON, at the bottom right. Its `<pre>`
 * is upstream's but for `bg-code text-code-foreground`, ui.shadcn.com's own tokens (not a
 * theme's), which are a theme's `bg-muted` and `text-foreground` here. It takes `tabindex`,
 * which upstream's leaves off, so a keyboard can scroll a long value into view.
 */
export function showSubmitted(values: object): void {
  const json = JSON.stringify(values, null, 2)
  const Values = <template>
    <pre
      class="mt-2 w-[320px] overflow-x-auto rounded-md bg-muted p-4 text-foreground"
      tabindex="0"
    ><code>{{json}}</code></pre>
  </template>
  toast('You submitted the following values:', {
    description: Values,
    position: 'bottom-right',
    classNames: { content: 'flex flex-col gap-2' },
    style: { '--border-radius': 'calc(var(--radius)  + 4px)' },
  })
}
