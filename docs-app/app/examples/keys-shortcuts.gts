import { Key, KeyCombo } from '@ember-joinery/primitives/keys'

<template>
  <p>Press <Key @name="escape">Esc</Key> to close.</p>
  <p>Search with <KeyCombo @name="search" @keys="Ctrl+K" @mac="⌘+K" />.</p>
</template>
