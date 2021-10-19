path= require "path"
byteSize= require "byte-size"
sass= require "sass"
Compiler= require "./compiler"
config= require "../config"

module.exports= class extends Compiler
  @ext= "css"
  compile: (entry)->
    opts=
      outFile: path.basename(entry) + ".css"
      file: path.resolve(entry)
      includePaths: config.compilerOpts.sass.includePaths
      sourceMap: config.compilerOpts.sass.sourcemap
    try
      {css, map, stats}= sass.renderSync opts
      @results[entry]= result= css.toString()
      @sourceMaps[entry]= map?.toString()
      size= byteSize(Buffer.byteLength(result)).toString()
      @deps[entry]= stats.includedFiles
      console.log "Compiled: #{entry} in #{stats.duration}ms, #{size}"
    catch error
      console.log error.formatted
