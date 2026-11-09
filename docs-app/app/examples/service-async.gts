import Component from '@glimmer/component'
import { asyncService } from '@ember-joinery/primitives/service'

/** The loader is the key: every caller that shares it shares the one instance. */
const loadRates = () => import('./lazy/exchange-rates.ts')

class Price extends Component<{ Args: { euros: number; currency: string } }> {
  get rates() {
    return asyncService(this, loadRates)
  }

  get converted() {
    const rates = this.rates.resolved
    if (!rates) return undefined
    return rates.convert(this.args.euros, 'EUR', this.args.currency).toFixed(2)
  }

  <template>
    <li data-test-jn="price" data-test-jn-name={{@currency}}>
      {{#if this.rates.isLoading}}
        Loading the rates…
      {{else if this.rates.error}}
        The rates didn't load:
        {{this.rates.error.reason}}
      {{else}}
        €{{@euros}}
        is
        {{this.converted}}
        {{@currency}}
      {{/if}}
    </li>
  </template>
}

<template>
  <ul>
    <Price @euros={{20}} @currency="USD" />
    <Price @euros={{20}} @currency="GBP" />
    <Price @euros={{20}} @currency="JPY" />
  </ul>
</template>
