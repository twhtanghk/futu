{defineConfig} = require '@vue/cli-service'

module.exports = defineConfig
  transpileDependencies: true
  lintOnSave: false
  chainWebpack: (config) ->
    config
      .plugin 'polyfills'
      .use require 'node-polyfill-webpack-plugin'
