import { ImageUp } from 'lucide'
import { Icon, asButton } from '@ember-joinery/ember'
import { FileUpload } from '@ember-joinery/file-upload'

/** A stand-in for a photo: an SVG, so its preview has something to show. */
const picture = (name: string, from: string, to: string) =>
  new File(
    [
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40"><defs><linearGradient id="g" x2="1" y2="1"><stop offset="0" stop-color="${from}"/><stop offset="1" stop-color="${to}"/></linearGradient></defs><rect width="40" height="40" fill="url(#g)"/></svg>`,
    ],
    name,
    { type: 'image/svg+xml' },
  )

const photos = [
  picture('dawn.svg', '#f59e0b', '#ef4444'),
  picture('dusk.svg', '#0ea5e9', '#6366f1'),
]

<template>
  <FileUpload
    @name="photos"
    @multiple={{true}}
    @accept="image/*"
    @defaultValue={{photos}}
    class="w-full max-w-md"
    as |u|
  >
    <u.Dropzone class="min-h-48 justify-center" as |zone|>
      <span class="flex flex-col items-center gap-2">
        <Icon @icon={{ImageUp}} class="size-8 text-muted-foreground" />
        <span class="text-sm font-medium">
          {{if zone.isDragging "Drop your photos" "Drag photos here"}}
        </span>
        <span class="text-xs text-muted-foreground">PNG, JPG or SVG</span>
        {{! Not a button of its own: the whole zone opens the file picker. }}
        <span class="mt-2" {{asButton variant="outline" size="sm"}}>Browse photos</span>
      </span>
    </u.Dropzone>
    <p class="text-sm text-muted-foreground">Chosen: {{u.files.length}}</p>
    <u.List />
  </FileUpload>
</template>
