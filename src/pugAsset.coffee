path= require "path"; fs= require "fs"
pug= require "pug"
config= require "config"
{defaults}= require "underscore"
Asset= require "./asset"
sassAssets= (require "./sassAsset").assets
coffeeAssets= (require "./coffeeAsset").assets

buildAssetUrls= ->
  coffeeAssets.reduce (m, a)->
    m[a.name]= config.assetUrl + a.outputFilename
  , {}
  coffeeAssets.reduce (m, a)->
    m[a.name]= config.assetUrl + a.outputFilename
  , {}

module.exports= class extends Compiler
  compile: ->
    try
      pugString= fs.readFileSync(path.resolve(@entry)).toString()
      {body, dependencies}= pug.compileClientWithDependenciesTracked pugString, filename: path.resolve(@entry), self: config.compilerOpts.pug.self
      @deps= dependencies
      @deps.push path.resolve(@entry) # dependencies doesnt include entry as a part of itself
      locals= defaults (config.compilerOpts.pug.locals),
        env: config.env, dev: config.dev
      locals.assets= buildAssetUrls()
      locals= JSON.stringify(locals)
      @results[key]= eval(body + "; template(#{locals})")
      console.log "Compiled: #{entry}"

    catch error
      console.log error
