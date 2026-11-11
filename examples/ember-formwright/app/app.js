import Application from '@ember/application'
import compatModules from '@embroider/virtual/compat-modules'
import Resolver from 'ember-resolver'
import loadInitializers from 'ember-load-initializers'
import { setupJoineryForms } from '@ember-joinery/formwright'
import config from 'ember-formwright/config/environment'
// Joinery's theme (shadcn's tokens), then its component CSS, in the `joinery` cascade layer,
// so the app's own CSS always wins. joinery.css styles Formwright's fields too.
import '@ember-joinery/ember/tokens.css'
import '@ember-joinery/ember/joinery.css'
import './styles/app.css'

// Every Joinery input as a Formwright control, and Joinery's Field layout for every field.
setupJoineryForms()

export default class App extends Application {
  modulePrefix = config.modulePrefix
  podModulePrefix = config.podModulePrefix
  Resolver = Resolver.withModules(compatModules)
}

loadInitializers(App, config.modulePrefix, compatModules)
