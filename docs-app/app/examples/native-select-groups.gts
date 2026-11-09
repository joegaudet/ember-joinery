import { NativeSelect } from '@ember-joinery/ember'

<template>
  {{! Upstream's select has no name; Joinery's gets aria-label, so the audit passes. }}
  <NativeSelect aria-label="Department" as |s|>
    <s.Option @value="">Select department</s.Option>
    <s.OptGroup label="Engineering">
      <s.Option @value="frontend">Frontend</s.Option>
      <s.Option @value="backend">Backend</s.Option>
      <s.Option @value="devops">DevOps</s.Option>
    </s.OptGroup>
    <s.OptGroup label="Sales">
      <s.Option @value="sales-rep">Sales Rep</s.Option>
      <s.Option @value="account-manager">
        Account Manager
      </s.Option>
      <s.Option @value="sales-director">
        Sales Director
      </s.Option>
    </s.OptGroup>
    <s.OptGroup label="Operations">
      <s.Option @value="support">
        Customer Support
      </s.Option>
      <s.Option @value="product-manager">
        Product Manager
      </s.Option>
      <s.Option @value="ops-manager">
        Operations Manager
      </s.Option>
    </s.OptGroup>
  </NativeSelect>
</template>
