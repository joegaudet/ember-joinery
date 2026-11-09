import {
  Field,
  FieldContent,
  FieldDescription,
  FieldGroup,
  FieldLabel,
  FieldTitle,
  Switch,
} from '@ember-joinery/ember'

<template>
  {{!
    Each switch names itself by its card's title with aria-labelledby, which upstream's leave
    off: axe can't read a name through the field's role="group" inside the label, though
    browsers do, so the audit would fail without it.
  }}
  <FieldGroup class="w-full max-w-sm">
    <FieldLabel for="switch-share">
      <Field @orientation="horizontal">
        <FieldContent>
          <FieldTitle id="switch-share-title">Share across devices</FieldTitle>
          <FieldDescription>
            Focus is shared across devices, and turns off when you leave the app.
          </FieldDescription>
        </FieldContent>
        <Switch id="switch-share" aria-labelledby="switch-share-title" />
      </Field>
    </FieldLabel>
    <FieldLabel for="switch-notifications">
      <Field @orientation="horizontal">
        <FieldContent>
          <FieldTitle id="switch-notifications-title">Enable notifications</FieldTitle>
          <FieldDescription>
            Receive notifications when focus mode is enabled or disabled.
          </FieldDescription>
        </FieldContent>
        <Switch
          id="switch-notifications"
          @defaultChecked={{true}}
          aria-labelledby="switch-notifications-title"
        />
      </Field>
    </FieldLabel>
  </FieldGroup>
</template>
