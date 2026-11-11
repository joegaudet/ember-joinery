import { tracked } from '@glimmer/tracking'

/**
 * Upstream adds `lorem-ipsum`'s random paragraphs; these take turns, so the text is the same
 * on every run.
 */
const PARAGRAPHS = [
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
  'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
  'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
  'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
]

/** The paragraphs the examples add and remove: upstream's `TrackedArray`, as a tracked list. */
export class Content {
  @tracked paragraphs: string[] = []

  addContent = (): void => {
    this.paragraphs = [...this.paragraphs, PARAGRAPHS[this.paragraphs.length % PARAGRAPHS.length]!]
  }

  removeContent = (): void => {
    this.paragraphs = this.paragraphs.slice(0, -1)
  }
}
