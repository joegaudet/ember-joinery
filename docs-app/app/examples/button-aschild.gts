import { button } from '@ember-joinery/ember'

<template>
  {{!-- Upstream's <Button asChild><Link href="/login">: the button modifier on your own link.
        With the router, it's <LinkTo @route="login" {{button}}>. --}}
  <a href="/login" {{button}}>Login</a>
</template>
