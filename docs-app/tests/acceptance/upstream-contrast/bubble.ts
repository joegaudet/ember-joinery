/**
 * The destructive bubble's text: upstream draws it `--destructive` on its own 10% tint, about
 * 4:1 in the light themes, under the 4.5:1 WCAG AA asks of its 14px text. And the Show more
 * button in upstream's bubble-collapsible example, `text-muted-foreground` on the muted bubble's
 * `--muted`. The Bubble page's Accessibility notes say so, and how an app can darken them.
 */
export default [
  '[data-slot="bubble"][data-variant="destructive"] > [data-slot="bubble-content"]',
  '[data-slot="bubble-content"] [data-slot="collapsible-trigger"]',
]
