require 'coffeescript/register'
path= require "path"

{env, entries, dev, watch}= require "./config"
{select, contains}= require "underscore"

http = require('http')
{send}= require "micro"
{router, get}= require "microrouter"
chokidar= require "chokidar"; WS= require "ws"
process= require "process"

ws_server= new WS.Server {host: dev.host, port: dev.wsport}
console.log "WebSocket server running at http://#{dev.host}:#{dev.wsport}"
process.on "SIGINT", ->ws_server.close(); process.exit(0)
reload= ->ws_server.clients.forEach (c)->c.send "reload"

class Watcher
  constructor: (entries)->
    @assets= entries.map (e)=>new @constructor.Asset e
  compileAll: ->
    Promise.all @assets.map (a)->a.compile()
  compileAllIfDepends= (filepath)->
    Promise.all do =>
      select @assets, (a)->contains a.deps, filepath
      .map (a)->a.compile()
  @watch= ->(new @)._watch()
  _watch: ->
    target= path.resolve @constructor.targetDir
    return if not fs.existsSync target
    watcher= chokidar.watch target
    return new Promise (done)=>
      watcher.on "ready", =>
        await @compileAll()
        done @assets
        watcher.on "all", (e, filepath)=>
          return if not e.match /^(add|change|unlink)$/
          await @compileAllIfDepends filepath
          reload()

class SassWatcher extends Watcher
  @targetDir= watch.sass
  @Asset= require "./sassAsset"
class CoffeeWatcher extends Watcher
  @targetDir= watch.coffee
  @Asset= require "./coffeeAsset"

sassAssets= []; coffeeAssets=[]
do ->
  sassAssets= await SassWatcher.watch()
  coffeeAssets= await coffeeWatcher.watch()

  class PugWatcher extends Watcher
    @targetDir= watch.pug
    @Asset= require "./pugAsset"
    updateAssets: ->
      @assets.forEach (a)->a.updateAssets sass: sassAssets, coffee: coffeeAssets
    compileAll: ->
      @updateAssets();super()
    compileAllIfDepends: (filepath)->
      @updateAssets();super(filepath)

  PugWatcher.watch()

server= new http.Server router(
  get '/:key.js(.:map)', (req, res)->
    send res, 200, do ->

    send res, 200, coffeeCompiler[if req.params.map? then "sourceMaps" else "results"][req.params.key]
  get '/:key.css(.:map)', (req, res)->
    send res, 200, sassCompiler[if req.params.map? then "sourceMaps" else "results"][req.params.key]
)

server.listen dev.port, dev.host
