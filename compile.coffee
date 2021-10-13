require 'coffeescript/register'
_= require "underscore"
path= require "path"; fs= require "fs"
sass= require "sass"; pug= require "pug"
rollup= require "rollup"
coffee = require "rollup-plugin-coffee-script"
{terser}= require "rollup-plugin-terser"
replace= require '@rollup/plugin-replace'
{nodeResolve}= require '@rollup/plugin-node-resolve'

http = require('http')
{send}= require "micro"
{router, get}= require "microrouter"
chokidar= require "chokidar"; WS= require "ws"
byteSize= require "byte-size"; process= require "process"

config= require(path.resolve("config.coffee"))
{env, entries, dev}= config

ws_server= new WS.Server {host: dev.host, port: dev.wsport}
console.log "WebSocket server running at http://#{dev.host}:#{dev.wsport}"
process.on "SIGINT", ->ws_server.close(); process.exit(0)
reload= ->ws_server.clients.forEach (c)->c.send "reload"

class Compiler
  constructor: (targetDir, @entries)->
    @targetDir= path.resolve(targetDir)
    @results= {}
    @deps= _.inject @entries, ((m, item)->m[item]= [];return m;), {}
    @sourceMaps= if env is "development" then _.mapObject @deps, ->""
  compileAll: ->await Promise.all @entries.map (entry)=> @compile entry
  watch: -> new Promise (done)=>
    watcher= chokidar.watch @targetDir
    watcher.on "ready", =>
      await @compileAll()
      reload()
      done()
      watcher.on "all", (e, filepath)=>
        return if not e.match /^(add|change|unlink)$/
        await Promise.all _.map @deps, (deps, entry)=>@compile entry if _.contains deps, filepath
        reload()

class SassCompiler extends Compiler
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

class CoffeeCompiler extends Compiler
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

class PugCompiler extends Compiler
  compile: (entry)->
    basename= path.basename(entry, ".pug")
    opts= {
      config...,
      pageTitle: "ほげほげ"
      filename: path.resolve(entry), self: on
      assetUrls:
        sass: _.mapObject sassCompiler.results, (item, key)->"#{config.compiledUrl}#{key}.css"
        coffee: _.mapObject coffeeCompiler.results, (item, key)->"#{config.compiledUrl}#{key}.js"
    }
    try
      pugString= fs.readFileSync(path.resolve(entry)).toString()
      {body, dependencies}= pug.compileClientWithDependenciesTracked(pugString, opts)
      @deps[entry]= dependencies
      @deps[entry].push path.resolve(entry) # dependencies doesnt include entry as a part of itself
      locals= JSON.stringify(opts)
      html= eval(body + "; template(#{locals})")
      fs.writeFileSync path.resolve(path.join(config.output, basename)), html
      console.log "Compiled: #{entry}"
    catch error
      console.log error

sassCompiler= new SassCompiler dev.watch.sass, entries.sass
coffeeCompiler= new CoffeeCompiler dev.watch.coffee, entries.coffee
pugCompiler= new PugCompiler dev.watch.pug, entries.pug
do ->
  await sassCompiler.watch()
  await coffeeCompiler.watch()
  pugCompiler.watch()

# module.exports= router(
#   get '/:key.js(.:map)', (req, res)->
#     send res, 200, coffeeCompiler[if req.params.map? then "sourceMaps" else "results"][req.params.key]
#   get '/:key.css(.:map)', (req, res)->
#     send res, 200, sassCompiler[if req.params.map? then "sourceMaps" else "results"][req.params.key]
# )



server= new http.Server router(
  get '/:key.js(.:map)', (req, res)->
    send res, 200, coffeeCompiler[if req.params.map? then "sourceMaps" else "results"][req.params.key]
  get '/:key.css(.:map)', (req, res)->
    send res, 200, sassCompiler[if req.params.map? then "sourceMaps" else "results"][req.params.key]
)

server.listen dev.port, dev.host
