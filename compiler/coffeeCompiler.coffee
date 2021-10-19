{compact} = require "underscore"
byteSize= require "byte-size"
config= require "../config"
Compiler= require "./compiler"
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
module.exports= class extends Compiler
  @ext= "js"
  compile: (entry)->
    try
      bundle= await rollup.rollup {plugins, input: path.resolve(entry)}
      {output}= await bundle.generate format: "iife", sourcemap: opts.sourceMap
      @results[entry]= result= output[0].code
      outputFilename= do ->
        name= path.basename(entry)
        if opts.hashBust then name += "-" + (require "./hash")(result)
        return name + ".js"
      @outputFilenames[entry]= outputFilename
      if opts.sourceMap
        @results[entry] += "\n //#sourceMappingURL=#{outputFilename}.map"
        @sourceMaps[entry]= output[0].map.toString()

      size= byteSize(Buffer.byteLength(result)).toString()
      @deps[entry]= bundle.watchFiles
      console.log "Compiled: #{entry}, #{size}"
    catch error
      console.log error
