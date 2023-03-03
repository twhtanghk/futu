{defineConfig} = require '@vue/cli-service'

module.exports = defineConfig
  devServer:
    proxy: 'http://172.19.0.6:3000'
  outputDir: '../backend/dist'
  transpileDependencies: true
  lintOnSave: false
  chainWebpack: (config) ->
    config
      .plugin 'polyfills'
      .use require 'node-polyfill-webpack-plugin'
