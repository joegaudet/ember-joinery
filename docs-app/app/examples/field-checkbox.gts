import {
  Checkbox,
  Field,
  FieldContent,
  FieldDescription,
  FieldGroup,
  FieldLabel,
  FieldLegend,
  FieldSeparator,
  FieldSet,
} from '@ember-joinery/ember'

<template>
  {{!
    Upstream puts defaultChecked on the first FieldLabel, where it does nothing (a label has no
    checked state), so it is left off here too: every checkbox in the set starts unchecked.
  }}
  <FieldGroup class="w-full max-w-xs">
    <FieldSet>
      <FieldLegend @variant="label">
        Show these items on the desktop
      </FieldLegend>
      <FieldDescription>
        Select the items you want to show on the desktop.
      </FieldDescription>
      <FieldGroup class="gap-3">
        <Field @orientation="horizontal">
          <Checkbox id="finder-pref-9k2-hard-disks-ljj" />
          <FieldLabel for="finder-pref-9k2-hard-disks-ljj" class="font-normal">
            Hard disks
          </FieldLabel>
        </Field>
        <Field @orientation="horizontal">
          <Checkbox id="finder-pref-9k2-external-disks-1yg" />
          <FieldLabel for="finder-pref-9k2-external-disks-1yg" class="font-normal">
            External disks
          </FieldLabel>
        </Field>
        <Field @orientation="horizontal">
          <Checkbox id="finder-pref-9k2-cds-dvds-fzt" />
          <FieldLabel for="finder-pref-9k2-cds-dvds-fzt" class="font-normal">
            CDs, DVDs, and iPods
          </FieldLabel>
        </Field>
        <Field @orientation="horizontal">
          <Checkbox id="finder-pref-9k2-connected-servers-6l2" />
          <FieldLabel for="finder-pref-9k2-connected-servers-6l2" class="font-normal">
            Connected servers
          </FieldLabel>
        </Field>
      </FieldGroup>
    </FieldSet>
    <FieldSeparator />
    <Field @orientation="horizontal">
      <Checkbox id="finder-pref-9k2-sync-folders-nep" @defaultChecked={{true}} />
      <FieldContent>
        <FieldLabel for="finder-pref-9k2-sync-folders-nep">
          Sync Desktop &amp; Documents folders
        </FieldLabel>
        <FieldDescription>
          Your Desktop &amp; Documents folders are being synced with iCloud Drive. You can access
          them from other devices.
        </FieldDescription>
      </FieldContent>
    </Field>
  </FieldGroup>
</template>
