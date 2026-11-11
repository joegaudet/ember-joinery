import { Table } from '@ember-joinery/ember'

const invoices = [
  {
    invoice: 'INV001',
    paymentStatus: 'Paid',
    totalAmount: '$250.00',
    paymentMethod: 'Credit Card',
  },
  {
    invoice: 'INV002',
    paymentStatus: 'Pending',
    totalAmount: '$150.00',
    paymentMethod: 'PayPal',
  },
  {
    invoice: 'INV003',
    paymentStatus: 'Unpaid',
    totalAmount: '$350.00',
    paymentMethod: 'Bank Transfer',
  },
  {
    invoice: 'INV004',
    paymentStatus: 'Paid',
    totalAmount: '$450.00',
    paymentMethod: 'Credit Card',
  },
  {
    invoice: 'INV005',
    paymentStatus: 'Paid',
    totalAmount: '$550.00',
    paymentMethod: 'PayPal',
  },
  {
    invoice: 'INV006',
    paymentStatus: 'Pending',
    totalAmount: '$200.00',
    paymentMethod: 'Bank Transfer',
  },
  {
    invoice: 'INV007',
    paymentStatus: 'Unpaid',
    totalAmount: '$300.00',
    paymentMethod: 'Credit Card',
  },
]

<template>
  <Table as |t|>
    <t.Caption>A list of your recent invoices.</t.Caption>
    <t.Header>
      <t.Row>
        <t.Head class="w-[100px]">Invoice</t.Head>
        <t.Head>Status</t.Head>
        <t.Head>Method</t.Head>
        <t.Head class="text-right">Amount</t.Head>
      </t.Row>
    </t.Header>
    <t.Body>
      {{#each invoices as |invoice|}}
        <t.Row>
          <t.Cell class="font-medium">{{invoice.invoice}}</t.Cell>
          <t.Cell>{{invoice.paymentStatus}}</t.Cell>
          <t.Cell>{{invoice.paymentMethod}}</t.Cell>
          <t.Cell class="text-right">{{invoice.totalAmount}}</t.Cell>
        </t.Row>
      {{/each}}
    </t.Body>
    <t.Footer>
      <t.Row>
        <t.Cell colspan="3">Total</t.Cell>
        <t.Cell class="text-right">$2,500.00</t.Cell>
      </t.Row>
    </t.Footer>
  </Table>
</template>
