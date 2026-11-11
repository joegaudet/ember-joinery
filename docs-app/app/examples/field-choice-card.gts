import {
  Field,
  FieldContent,
  FieldDescription,
  FieldGroup,
  FieldLabel,
  FieldLegend,
  FieldSet,
  FieldTitle,
  RadioGroup,
} from '@ember-joinery/ember'

<template>
  {{!
    Each radio names itself by its card's title with aria-labelledby, which upstream's leave
    off: axe can't read a name through the field's role="group" inside the label, though
    browsers do, so the audit would fail without it.
  }}
  <FieldGroup class="w-full max-w-xs">
    <FieldSet>
      <FieldLegend @variant="label">Compute Environment</FieldLegend>
      <FieldDescription>
        Select the compute environment for your cluster.
      </FieldDescription>
      <RadioGroup @defaultValue="kubernetes" as |group|>
        <FieldLabel for="kubernetes-r2h">
          <Field @orientation="horizontal">
            <FieldContent>
              <FieldTitle id="kubernetes-r2h-title">Kubernetes</FieldTitle>
              <FieldDescription>
                Run GPU workloads on a K8s cluster.
              </FieldDescription>
            </FieldContent>
            <group.Item
              @value="kubernetes"
              id="kubernetes-r2h"
              aria-labelledby="kubernetes-r2h-title"
            />
          </Field>
        </FieldLabel>
        <FieldLabel for="vm-z4k">
          <Field @orientation="horizontal">
            <FieldContent>
              <FieldTitle id="vm-z4k-title">Virtual Machine</FieldTitle>
              <FieldDescription>
                Access a cluster to run GPU workloads.
              </FieldDescription>
            </FieldContent>
            <group.Item @value="vm" id="vm-z4k" aria-labelledby="vm-z4k-title" />
          </Field>
        </FieldLabel>
      </RadioGroup>
    </FieldSet>
  </FieldGroup>
</template>
