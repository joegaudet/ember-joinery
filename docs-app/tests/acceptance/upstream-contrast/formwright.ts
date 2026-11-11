/**
 * A chosen choice card's description: upstream draws it `--muted-foreground` on the card's
 * `--primary` 5% tint, about 4.3:1 in the light themes, under the 4.5:1 WCAG AA asks of its
 * 14px text. The Forms page's Accessibility notes say so, and how an app can darken it.
 */
export default [
  '[data-slot="field-label"]:has([role="radio"][aria-checked="true"]) [data-slot="field-description"]',
]
