path= require "path"
fs= require "fs"
config= require "./config"
byteSize= require "byte-size"
Asset= require "./asset"
sass= require "sass"
opts= config.compilerOpts.sass

purge= (code)->
  {PurgeCSS}= require "purgecss"



module.exports= class extends Asset
  @assets= []
  compile: ->
    try
      {css, map, stats}= sass.renderSync
        outFile: path.basename(@entry) + ".css"
        file: path.resolve(@entry)
        includePaths: opts.includePaths
        outputStyle: if opts.minify then "compressed" else "expanded"
        sourceMap: if opts.purge then off else if opts.sourceMap then on else off
      @code= css.toString()
      @code= await if opts.purge then purge(@code)

      @map= map?.toString()
      size= byteSize(Buffer.byteLength(@code)).toString()
      @deps= stats.includedFiles
      console.log "Compiled: #{@entry} in #{stats.duration}ms, #{size}"
    catch error
      console.log error.formatted
