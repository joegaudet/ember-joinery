/**
 * Whether the page is running inside a frame (an `<iframe>`, or an embed on another site).
 * Call it in JavaScript or in a template:
 *
 *   {{#if (inIframe)}}<a href={{this.fullPageURL}} target="_top">Open the full page</a>{{/if}}
 *
 * It is ember-primitives' `inIframe`.
 */
export function inIframe(): boolean {
  return window.self !== window.top
}

/** Whether the page is the top-level window, not inside a frame: the opposite of `inIframe`. */
export function notInIframe(): boolean {
  return !inIframe()
}
