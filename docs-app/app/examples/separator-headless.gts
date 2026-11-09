import { Separator } from '@ember-joinery/primitives/separator'

<template>
  {{! ember-primitives' breadcrumb example: decorative slashes between a trail's links. }}
  <div class="flex flex-col gap-4 text-sm">
    <nav aria-label="Breadcrumb">
      <ol class="m-0 flex list-none gap-2 p-0">
        <li><a href="#home">Home</a></li>
        <Separator @as="li" @decorative={{true}}>/</Separator>
        <li><a href="#docs">Docs</a></li>
        <Separator @as="li" @decorative={{true}}>/</Separator>
        <li aria-current="page">Separator</li>
      </ol>
    </nav>
    <Separator />
    <p class="m-0">An &lt;hr&gt; above, unstyled: the browser's own line.</p>
  </div>
</template>
