import { get } from '@ember/helper'
import { Table } from '@ember-joinery/ember'

// Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
// Arabic: its preview opens in Arabic, and the frame has no language picker. These are its
// strings, upstream's `t`.
const text = {
  caption: 'قائمة بفواتيرك الأخيرة.',
  invoice: 'الفاتورة',
  status: 'الحالة',
  method: 'الطريقة',
  amount: 'المبلغ',
  paid: 'مدفوع',
  pending: 'قيد الانتظار',
  unpaid: 'غير مدفوع',
  creditCard: 'بطاقة ائتمانية',
  paypal: 'PayPal',
  bankTransfer: 'تحويل بنكي',
  total: 'المجموع',
}

const invoices = [
  {
    invoice: 'INV001',
    paymentStatus: 'paid',
    totalAmount: '$250.00',
    paymentMethod: 'creditCard',
  },
  {
    invoice: 'INV002',
    paymentStatus: 'pending',
    totalAmount: '$150.00',
    paymentMethod: 'paypal',
  },
  {
    invoice: 'INV003',
    paymentStatus: 'unpaid',
    totalAmount: '$350.00',
    paymentMethod: 'bankTransfer',
  },
  {
    invoice: 'INV004',
    paymentStatus: 'paid',
    totalAmount: '$450.00',
    paymentMethod: 'creditCard',
  },
  {
    invoice: 'INV005',
    paymentStatus: 'paid',
    totalAmount: '$550.00',
    paymentMethod: 'paypal',
  },
  {
    invoice: 'INV006',
    paymentStatus: 'pending',
    totalAmount: '$200.00',
    paymentMethod: 'bankTransfer',
  },
  {
    invoice: 'INV007',
    paymentStatus: 'unpaid',
    totalAmount: '$300.00',
    paymentMethod: 'creditCard',
  },
] as const

<template>
  <Table as |t|>
    <t.Caption>{{text.caption}}</t.Caption>
    <t.Header>
      <t.Row>
        <t.Head class="w-[100px]">{{text.invoice}}</t.Head>
        <t.Head>{{text.status}}</t.Head>
        <t.Head>{{text.method}}</t.Head>
        <t.Head class="text-right">{{text.amount}}</t.Head>
      </t.Row>
    </t.Header>
    <t.Body>
      {{#each invoices as |invoice|}}
        <t.Row>
          <t.Cell class="font-medium">{{invoice.invoice}}</t.Cell>
          <t.Cell>{{get text invoice.paymentStatus}}</t.Cell>
          <t.Cell>{{get text invoice.paymentMethod}}</t.Cell>
          <t.Cell class="text-right">{{invoice.totalAmount}}</t.Cell>
        </t.Row>
      {{/each}}
    </t.Body>
    <t.Footer>
      <t.Row>
        <t.Cell colspan="3">{{text.total}}</t.Cell>
        <t.Cell class="text-right">$2,500.00</t.Cell>
      </t.Row>
    </t.Footer>
  </Table>
</template>
