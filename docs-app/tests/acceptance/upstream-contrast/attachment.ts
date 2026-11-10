/**
 * A failed upload's description: upstream draws it `--destructive` at 80%, under the 4.5:1 WCAG
 * AA asks of its 12px text. The Attachment page's Accessibility notes say so, and how an app can
 * draw it at full strength.
 */
export default ['[data-slot="attachment"][data-state="error"] [data-slot="attachment-description"]']
