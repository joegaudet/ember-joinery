import { FileUpload } from '@ember-joinery/file-upload'

const contract = [
  new File([new Uint8Array(312_000)], 'signed-contract.pdf', { type: 'application/pdf' }),
]

<template>
  <FileUpload
    @name="contract"
    @disabled={{true}}
    @defaultValue={{contract}}
    @prompt="Uploads are closed"
    @description="The contract has been signed"
    class="w-full max-w-md"
  />
</template>
