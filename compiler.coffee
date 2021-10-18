_= require "underscore"
path= require "path"; fs= require "fs"
byteSize= require "byte-size"

sass= require "sass"; pug= require "pug"
rollup= require "rollup"
coffee = require "rollup-plugin-coffee-script"
{terser}= require "rollup-plugin-terser"
replace= require '@rollup/plugin-replace'
{nodeResolve}= require '@rollup/plugin-node-resolve'

{env, dev, output}= require "./config.coffee"

class Compiler
  constructor: (@entries= [])->
    @results= {}
    @deps= _.inject @entries, ((m, item)->m[item]= [];return m;), {}
    @sourceMaps= _.mapObject @deps, ->""
  compileAll: ->Promise.all @entries.map (entry)=> @compile entry
  writeAll: ->
    Promise.all @entries.map (entry)=>@write entry, @result

    Promise.all _.keys(@results).map (key)=>
      ext= if @constructor.ext then ".#{@constructor.ext}" else ""
      outputTo= path.resolve(path.join(output, key) + ext)
      new Promise (done)=>fs.writeFile outputTo, @results[key], done

  write: (entry, data)->
    ext= if @constructor.ext then ".#{@constructor.ext}" else ""
    outputTo= path.resolve(path.join(output, path.basename(entry)) + ext)
    new Promise (done)=>fs.writeFile outputTo, data, done

module.exports.Compiler= Compiler

module.exports.SassCompiler= class extends Compiler
  @ext= "css"
  compile: (entry)->
    key= path.basename(entry, ".scss")
    opts= outFile: key + ".css", file: path.resolve(entry), includePaths: ["node_modules"], sourceMap: if env is "development" then yes else no
    try
      {css, map, stats}= sass.renderSync opts
      @results[key]= result= css.toString()
      @sourceMaps[key]= map?.toString()
      size= byteSize(Buffer.byteLength(result)).toString()
      @deps[entry]= stats.includedFiles
      console.log "Compiled: #{entry} in #{stats.duration}ms, #{size}"
    catch error
      console.log error.formatted

module.exports.CoffeeCompiler= class extends Compiler
  @ext= "js"
  compile: (entry)->
    plugins= _.compact [
      coffee()
      if env isnt "development" then terser()
      replace(
        preventAssignment: no
        values: 'process.env.NODE_ENV': JSON.stringify(env)
      )
      nodeResolve moduleDirectories: ['node_modules']
    ]
    try
      key= path.basename(entry, ".coffee")
      bundle= await rollup.rollup {plugins, input: path.resolve(entry)}
      {output}= await bundle.generate format: "iife", sourcemap: if env is "development" then yes else no
      @results[key]= result= output[0].code + "\n //# sourceMappingURL=#{key}.js.map"
      @sourceMaps[key]= output[0].map.toString()
      size= byteSize(Buffer.byteLength(result)).toString()
      @deps[entry]= bundle.watchFiles
      console.log "Compiled: #{entry}, #{size}"
    catch error
      console.log error

module.exports.PugCompiler= class extends Compiler
  compile: (entry)->
    key= path.basename(entry, ".pug")
    opts= {
      env, dev,
      pageTitle: "ほげほげ"
      filename: path.resolve(entry), self: on
      assetUrls:
        sass: _.mapObject @sassCompiler.results, (item, key)->"http://#{dev.host}:#{dev.port}/#{key}.css"
        coffee: _.mapObject @coffeeCompiler.results, (item, key)->"http://#{dev.host}:#{dev.port}/#{key}.js"
    }
    try
      pugString= fs.readFileSync(path.resolve(entry)).toString()
      {body, dependencies}= pug.compileClientWithDependenciesTracked(pugString, opts)
      @deps[entry]= dependencies
      @deps[entry].push path.resolve(entry) # dependencies doesnt include entry as a part of itself
      locals= JSON.stringify(opts)
      @results[key]= eval(body + "; template(#{locals})")

      console.log "Compiled: #{entry}"
    catch error
      console.log error
