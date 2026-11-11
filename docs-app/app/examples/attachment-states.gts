import { Check, Clock, FileText, FileWarning, RefreshCw, X } from 'lucide'
import { Attachment, Icon, Spinner } from '@ember-joinery/ember'

<template>
  <div class="mx-auto flex w-full max-w-sm flex-col gap-2 py-12">
    <Attachment @state="idle" class="w-full" as |at|>
      <at.Media>
        <Icon @icon={{Clock}} />
      </at.Media>
      <at.Content>
        <at.Title>selected-file.pdf</at.Title>
        <at.Description>Ready to upload</at.Description>
      </at.Content>
      <at.Actions>
        <at.Action aria-label="Remove selected-file.pdf">
          <Icon @icon={{X}} />
        </at.Action>
      </at.Actions>
    </Attachment>
    <Attachment @state="uploading" class="w-full" as |at|>
      <at.Media>
        <Spinner />
      </at.Media>
      <at.Content>
        <at.Title>design-system.zip</at.Title>
        <at.Description>Uploading · 64%</at.Description>
      </at.Content>
      <at.Actions>
        <at.Action aria-label="Cancel upload">
          <Icon @icon={{X}} />
        </at.Action>
      </at.Actions>
    </Attachment>
    <Attachment @state="processing" class="w-full" as |at|>
      <at.Media>
        <Icon @icon={{FileText}} />
      </at.Media>
      <at.Content>
        <at.Title>market-research.pdf</at.Title>
        <at.Description>Processing document</at.Description>
      </at.Content>
      <at.Actions>
        <at.Action aria-label="Remove market-research.pdf">
          <Icon @icon={{X}} />
        </at.Action>
      </at.Actions>
    </Attachment>
    <Attachment @state="error" class="w-full" as |at|>
      <at.Media>
        <Icon @icon={{FileWarning}} />
      </at.Media>
      <at.Content>
        <at.Title>financial-model.xlsx</at.Title>
        <at.Description>
          Upload failed. Try again.
        </at.Description>
      </at.Content>
      <at.Actions>
        <at.Action aria-label="Retry upload">
          <Icon @icon={{RefreshCw}} />
        </at.Action>
        <at.Action aria-label="Remove financial-model.xlsx">
          <Icon @icon={{X}} />
        </at.Action>
      </at.Actions>
    </Attachment>
    <Attachment @state="done" class="w-full" as |at|>
      <at.Media>
        <Icon @icon={{Check}} />
      </at.Media>
      <at.Content>
        <at.Title>uploaded-report.pdf</at.Title>
        <at.Description>Uploaded · 1.8 MB</at.Description>
      </at.Content>
      <at.Actions>
        <at.Action aria-label="Remove uploaded-report.pdf">
          <Icon @icon={{X}} />
        </at.Action>
      </at.Actions>
    </Attachment>
  </div>
</template>
