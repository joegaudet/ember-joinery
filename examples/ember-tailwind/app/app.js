import Application from '@ember/application'
import compatModules from '@embroider/virtual/compat-modules'
import Resolver from 'ember-resolver'
import loadInitializers from 'ember-load-initializers'
import config from 'ember-tailwind/config/environment'
// The Tailwind entry point; it puts Joinery's layer between Tailwind's base and utilities.
import './styles/app.css'
// Joinery's theme (shadcn's tokens), then its component CSS, in the `joinery` cascade layer.
import '@ember-joinery/ember/tokens.css'
import '@ember-joinery/ember/joinery.css'

export default class App extends Application {
  modulePrefix = config.modulePrefix
  podModulePrefix = config.podModulePrefix
  Resolver = Resolver.withModules(compatModules)
}

loadInitializers(App, config.modulePrefix, compatModules)
