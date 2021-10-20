{compact} = require "underscore"
byteSize= require "byte-size"
config= require "../config"
Asset= require "./asset"
rollup= require "rollup"
coffee = require "rollup-plugin-coffee-script"
replace= require '@rollup/plugin-replace'
{nodeResolve}= require '@rollup/plugin-node-resolve'
opts= config.compilerOpts.coffee

plugins= compact [
  coffee()
  if opts.minify then (require "rollup-plugin-terser").terser()
  replace(
    preventAssignment: no
    values: opts.define
  )
  nodeResolve moduleDirectories: opts.resolve
]

module.exports= class extends Asset
  @assets= []
  compile: ->
    try
      bundle= await rollup.rollup {plugins, input: path.resolve(@entry)}
      {output}= await bundle.generate format: "iife", sourcemap: opts.sourceMap
      {code, map}= output[0]
      @code= code
      @outputFilename= do ->
        name= @name
        if opts.hashBust then name += "-" + (require "./hash")(code)
        return name + ".js"
      if opts.sourceMap and map?
        @code += "\n //#sourceMappingURL=#{@outputFilename}.map"
        @map= map.toString()

      size= byteSize(Buffer.byteLength(code)).toString()
      @deps= bundle.watchFiles
      console.log "Compiled: #{@entry}, #{size}"
    catch error
      console.log error
