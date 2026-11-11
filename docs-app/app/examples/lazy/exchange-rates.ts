/**
 * What `service-async` loads on demand: a service big enough (imagine a table of every
 * currency) that most pages shouldn't pay for it.
 */
export default class ExchangeRates {
  readonly #perEuro: Record<string, number> = { EUR: 1, USD: 1.08, GBP: 0.85, JPY: 162.4 }

  convert(amount: number, from: string, to: string): number {
    return (amount / this.#perEuro[from]!) * this.#perEuro[to]!
  }
}
