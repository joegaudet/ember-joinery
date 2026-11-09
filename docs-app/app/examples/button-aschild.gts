import { asButton } from '@ember-joinery/ember'

<template>
  {{!-- Upstream's <Button asChild><Link href="/login">: the asButton modifier on your own
        link. With the router, it's <LinkTo @route="login" {{asButton}}>. --}}
  <a href="/login" {{asButton}}>Login</a>
</template>
