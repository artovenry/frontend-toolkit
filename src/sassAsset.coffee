path= require "path"
config= require "../config"
byteSize= require "byte-size"
Asset= require "./asset"
sass= require "sass"

module.exports= class extends Asset
  @assets= []
  compile: ->
    opts=
      outFile: path.basename(@entry) + ".css"
      file: path.resolve(@entry)
      includePaths: config.compilerOpts.sass.includePaths
      sourceMap: config.compilerOpts.sass.sourcemap
    try
      {css, map, stats}= sass.renderSync opts
      @code= css.toString()
      @map= map?.toString()
      size= byteSize(Buffer.byteLength(@code)).toString()
      @deps= stats.includedFiles
      console.log "Compiled: #{@entry} in #{stats.duration}ms, #{size}"
    catch error
      console.log error.formatted
