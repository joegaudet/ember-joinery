/*
 * Nice tick values for a numeric axis, as recharts 3 computes them
 * (recharts/src/util/scale/getNiceTickValues.ts, its "adaptive" algorithm): ticks that are easy
 * to read, which may reach past the data's own range. recharts does the arithmetic with
 * decimal.js-light; here every result is rounded to 12 significant digits, which gives the same
 * numbers for any axis a chart draws.
 *
 * recharts is MIT licensed; its notice is in NOTICE, and the build keeps it in the module that
 * ships this (see rollup.config.mjs).
 */

/** Rounds away floating-point noise: 0.1 + 0.2 becomes 0.3. */
function clean(value: number): number {
  return Number.isFinite(value) ? Number(value.toPrecision(12)) : value
}

/** The number of digits before the decimal point (1 for 0). */
export function getDigitCount(value: number): number {
  if (value === 0) return 1
  return Math.floor(Math.log10(Math.abs(value))) + 1
}

/** The adaptive step: the rough step rounded up to a multiple of 0.05 (or 0.1) of its magnitude. */
export function getAdaptiveStep(
  roughStep: number,
  allowDecimals: boolean,
  correctionFactor: number,
): number {
  if (roughStep <= 0) return 0
  const digitCount = getDigitCount(roughStep)
  const digitCountValue = 10 ** digitCount
  const stepRatio = clean(roughStep / digitCountValue)
  const stepRatioScale = digitCount !== 1 ? 0.05 : 0.1
  const amendStepRatio = clean(
    (Math.ceil(clean(stepRatio / stepRatioScale)) + correctionFactor) * stepRatioScale,
  )
  const formatStep = clean(amendStepRatio * digitCountValue)
  return allowDecimals ? formatStep : Math.ceil(formatStep)
}

/** Ticks around a single value. */
export function getTickOfSingleValue(
  value: number,
  tickCount: number,
  allowDecimals: boolean,
): number[] {
  let step = 1
  let middle = value
  if (!Number.isInteger(value) && allowDecimals) {
    const absVal = Math.abs(value)
    if (absVal < 1) {
      step = 10 ** (getDigitCount(value) - 1)
      middle = clean(Math.floor(value / step) * step)
    } else if (absVal > 1) {
      middle = Math.floor(value)
    }
  } else if (value === 0) {
    middle = Math.floor((tickCount - 1) / 2)
  } else if (!allowDecimals) {
    middle = Math.floor(value)
  }
  const middleIndex = Math.floor((tickCount - 1) / 2)
  return Array.from({ length: tickCount }, (_, i) => clean(middle + (i - middleIndex) * step))
}

interface Step {
  step: number
  tickMin: number
  tickMax: number
}

function calculateStep(
  min: number,
  max: number,
  tickCount: number,
  allowDecimals: boolean,
  correctionFactor = 0,
): Step {
  if (!Number.isFinite((max - min) / (tickCount - 1))) return { step: 0, tickMin: 0, tickMax: 0 }
  const step = getAdaptiveStep(
    clean((max - min) / (tickCount - 1)),
    allowDecimals,
    correctionFactor,
  )
  let middle: number
  if (min <= 0 && max >= 0) {
    middle = 0
  } else {
    middle = clean((min + max) / 2)
    middle = clean(middle - (middle % step))
  }
  let belowCount = Math.ceil(clean((middle - min) / step))
  let upCount = Math.ceil(clean((max - middle) / step))
  const scaleCount = belowCount + upCount + 1
  if (scaleCount > tickCount) {
    return calculateStep(min, max, tickCount, allowDecimals, correctionFactor + 1)
  }
  if (scaleCount < tickCount) {
    upCount = max > 0 ? upCount + (tickCount - scaleCount) : upCount
    belowCount = max > 0 ? belowCount : belowCount + (tickCount - scaleCount)
  }
  return {
    step,
    tickMin: clean(middle - belowCount * step),
    tickMax: clean(middle + upCount * step),
  }
}

function rangeStep(start: number, end: number, step: number): number[] {
  const result: number[] = []
  let value = start
  for (let i = 0; value < end && i < 100000; i++) {
    result.push(value)
    value = clean(value + step)
  }
  return result
}

/**
 * The ticks of `[min, max]`, `tickCount` of them, rounded to nice values: `[0, 305]` with five
 * ticks gives `[0, 80, 160, 240, 320]`. The ticks can reach past the interval.
 */
export function getNiceTickValues(
  [min, max]: readonly [number, number],
  tickCount = 6,
  allowDecimals = true,
): number[] {
  const count = Math.max(tickCount, 2)
  const [cormin, cormax] = min > max ? [max, min] : [min, max]
  if (cormin === -Infinity || cormax === Infinity) {
    const values =
      cormax === Infinity
        ? [cormin, ...Array<number>(tickCount - 1).fill(Infinity)]
        : [...Array<number>(tickCount - 1).fill(-Infinity), cormax]
    return min > max ? values.reverse() : values
  }
  if (cormin === cormax) return getTickOfSingleValue(cormin, tickCount, allowDecimals)
  const { step, tickMin, tickMax } = calculateStep(cormin, cormax, count, allowDecimals)
  const values = rangeStep(tickMin, clean(tickMax + 0.1 * step), step)
  return min > max ? values.reverse() : values
}

/**
 * The ticks of a fixed `[min, max]`, kept inside it: for an axis whose domain is given as
 * numbers.
 */
export function getTickValuesFixedDomain(
  [min, max]: readonly [number, number],
  tickCount: number,
  allowDecimals = true,
): number[] {
  const [cormin, cormax] = min > max ? [max, min] : [min, max]
  if (cormin === -Infinity || cormax === Infinity) return [min, max]
  if (cormin === cormax) return [cormin]
  const count = Math.max(tickCount, 2)
  const step = getAdaptiveStep(clean((cormax - cormin) / (count - 1)), allowDecimals, 0)
  let values = [...rangeStep(cormin, cormax, step), cormax]
  if (!allowDecimals) values = values.map(value => Math.round(value))
  return min > max ? values.reverse() : values
}
