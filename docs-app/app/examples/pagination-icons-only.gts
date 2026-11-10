import { Field, FieldLabel, Pagination, Select } from '@ember-joinery/ember'

<template>
  <div class="flex items-center justify-between gap-4">
    <Field @orientation="horizontal" class="w-fit">
      <FieldLabel for="select-rows-per-page">Rows per page</FieldLabel>
      <Select @defaultValue="25" as |s|>
        <s.Trigger class="w-20" id="select-rows-per-page">
          <s.Value />
        </s.Trigger>
        <s.Content @align="start">
          <s.Group>
            <s.Item @value="10">10</s.Item>
            <s.Item @value="25">25</s.Item>
            <s.Item @value="50">50</s.Item>
            <s.Item @value="100">100</s.Item>
          </s.Group>
        </s.Content>
      </Select>
    </Field>
    <Pagination class="mx-0 w-auto" as |p|>
      <p.Content>
        <p.Item>
          <p.Previous href="#" />
        </p.Item>
        <p.Item>
          <p.Next href="#" />
        </p.Item>
      </p.Content>
    </Pagination>
  </div>
</template>
