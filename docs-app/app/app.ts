import Application from '@ember/application'
import compatModules from '@embroider/virtual/compat-modules'
import Resolver from 'ember-resolver'
import loadInitializers from 'ember-load-initializers'
import config from 'docs-app/config/environment'
// The guide's CSS first: it declares the cascade layers, so Joinery's rules win over the guide's.
import './styles/app.css'
import '@ember-joinery/ember/joinery.css'

export default class App extends Application {
  modulePrefix = config.modulePrefix
  podModulePrefix = config.podModulePrefix
  Resolver = Resolver.withModules(compatModules)
}

loadInitializers(App, config.modulePrefix, compatModules)
