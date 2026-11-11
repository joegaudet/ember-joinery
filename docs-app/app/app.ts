import Application from '@ember/application'
import compatModules from '@embroider/virtual/compat-modules'
import Resolver from 'ember-resolver'
import loadInitializers from 'ember-load-initializers'
import config from 'docs-app/config/environment'
import { setupJoineryForms } from '@ember-joinery/formwright'
// The guide's CSS first: it declares the cascade layers, so Joinery's rules win over the guide's.
import './styles/app.css'
// The default theme, for anything outside a preview; each preview sets its own (example.gts).
import '@ember-joinery/ember/tokens.css'
// Every style, each scoped to the previews that pick it (joinery-css.mjs).
import 'virtual:joinery-styles.css'
// The examples' layout utilities.
import './styles/examples.css'

export default class App extends Application {
  modulePrefix = config.modulePrefix
  podModulePrefix = config.podModulePrefix
  Resolver = Resolver.withModules(compatModules)
}

loadInitializers(App, config.modulePrefix, compatModules)

// Formwright's forms in Joinery: Joinery's inputs as controls, and Joinery's field layout.
setupJoineryForms()
