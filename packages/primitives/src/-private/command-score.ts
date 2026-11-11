/*!
 * The command score below is ported from cmdk 1.1.1 (https://github.com/dip/cmdk), which
 * Joinery's Command follows as shadcn/ui's does.
 *
 * MIT License
 *
 * Copyright (c) 2022 Paco Coursey
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

// How well a search matches an item's text: cmdk's `command-score`, itself after Superhuman's
// command-score, ported line for line so a Joinery Command ranks its items as shadcn's does.
// Bundled into command.gts. cmdk's notice is above and in NOTICE.

// The score when the characters match one after another, from the start.
const SCORE_CONTINUE_MATCH = 1
// The search jumps to the start of a word after a space or a dash ("cut-|paste").
const SCORE_SPACE_WORD_JUMP = 0.9
// It jumps to the start of a word after a symbol ("src/|index").
const SCORE_NON_SPACE_WORD_JUMP = 0.8
// It jumps to a character in the middle of a word.
const SCORE_CHARACTER_JUMP = 0.17
// Two characters of the search are swapped ("teh" for "the").
const SCORE_TRANSPOSITION = 0.1
// Each character, or word break, skipped on the way.
const PENALTY_SKIPPED = 0.999
// A character matches, but not in case.
const PENALTY_CASE_MISMATCH = 0.9999
// The search is used up before the text is.
const PENALTY_NOT_COMPLETE = 0.99

const IS_GAP_REGEXP = /[\\/_+.#"@[({&]/
const COUNT_GAPS_REGEXP = /[\\/_+.#"@[({&]/g
const IS_SPACE_REGEXP = /[\s-]/
const COUNT_SPACE_REGEXP = /[\s-]/g

function commandScoreInner(
  string: string,
  abbreviation: string,
  lowerString: string,
  lowerAbbreviation: string,
  stringIndex: number,
  abbreviationIndex: number,
  memoizedResults: Record<string, number>,
): number {
  if (abbreviationIndex === abbreviation.length) {
    if (stringIndex === string.length) return SCORE_CONTINUE_MATCH
    return PENALTY_NOT_COMPLETE
  }

  const memoizeKey = `${stringIndex},${abbreviationIndex}`
  const memoized = memoizedResults[memoizeKey]
  if (memoized !== undefined) return memoized

  const abbreviationChar = lowerAbbreviation.charAt(abbreviationIndex)
  let index = lowerString.indexOf(abbreviationChar, stringIndex)
  let highScore = 0

  while (index >= 0) {
    let score = commandScoreInner(
      string,
      abbreviation,
      lowerString,
      lowerAbbreviation,
      index + 1,
      abbreviationIndex + 1,
      memoizedResults,
    )
    if (score > highScore) {
      if (index === stringIndex) {
        score *= SCORE_CONTINUE_MATCH
      } else if (IS_GAP_REGEXP.test(string.charAt(index - 1))) {
        score *= SCORE_NON_SPACE_WORD_JUMP
        const wordBreaks = string.slice(stringIndex, index - 1).match(COUNT_GAPS_REGEXP)
        if (wordBreaks && stringIndex > 0) score *= Math.pow(PENALTY_SKIPPED, wordBreaks.length)
      } else if (IS_SPACE_REGEXP.test(string.charAt(index - 1))) {
        score *= SCORE_SPACE_WORD_JUMP
        const spaceBreaks = string.slice(stringIndex, index - 1).match(COUNT_SPACE_REGEXP)
        if (spaceBreaks && stringIndex > 0) score *= Math.pow(PENALTY_SKIPPED, spaceBreaks.length)
      } else {
        score *= SCORE_CHARACTER_JUMP
        if (stringIndex > 0) score *= Math.pow(PENALTY_SKIPPED, index - stringIndex)
      }

      if (string.charAt(index) !== abbreviation.charAt(abbreviationIndex)) {
        score *= PENALTY_CASE_MISMATCH
      }
    }

    if (
      (score < SCORE_TRANSPOSITION &&
        lowerString.charAt(index - 1) === lowerAbbreviation.charAt(abbreviationIndex + 1)) ||
      (lowerAbbreviation.charAt(abbreviationIndex + 1) ===
        lowerAbbreviation.charAt(abbreviationIndex) &&
        lowerString.charAt(index - 1) !== lowerAbbreviation.charAt(abbreviationIndex))
    ) {
      const transposedScore = commandScoreInner(
        string,
        abbreviation,
        lowerString,
        lowerAbbreviation,
        index + 1,
        abbreviationIndex + 2,
        memoizedResults,
      )
      if (transposedScore * SCORE_TRANSPOSITION > score) {
        score = transposedScore * SCORE_TRANSPOSITION
      }
    }

    if (score > highScore) highScore = score

    index = lowerString.indexOf(abbreviationChar, index + 1)
  }

  memoizedResults[memoizeKey] = highScore
  return highScore
}

function formatInput(string: string): string {
  // convert all valid space characters to space so they match each other
  return string.toLowerCase().replace(COUNT_SPACE_REGEXP, ' ')
}

/**
 * How well `abbreviation` (what was typed) matches `string` (an item's value), from 0 (not at
 * all) to 1 (exactly). Each typed character must appear in order; matches that run on, or start
 * a word, score higher than ones that skip about. An item's keywords count as more of its text.
 */
export function commandScore(
  string: string,
  abbreviation: string,
  aliases?: readonly string[],
): number {
  const text = aliases && aliases.length > 0 ? `${string} ${aliases.join(' ')}` : string
  return commandScoreInner(
    text,
    abbreviation,
    formatInput(text),
    formatInput(abbreviation),
    0,
    0,
    {},
  )
}
