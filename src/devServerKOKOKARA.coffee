require 'coffeescript/register'
_= require "underscore"
path= require "path"

{env, entries, dev, watch}= require "./config.coffee"


http = require('http')
{send}= require "micro"
{router, get}= require "microrouter"
chokidar= require "chokidar"; WS= require "ws"
process= require "process"

ws_server= new WS.Server {host: dev.host, port: dev.wsport}
console.log "WebSocket server running at http://#{dev.host}:#{dev.wsport}"
process.on "SIGINT", ->ws_server.close(); process.exit(0)
reload= ->ws_server.clients.forEach (c)->c.send "reload"


# {Compiler, SassCompiler, CoffeeCompiler, PugCompiler}= require "./compiler.coffee"

# Compiler::watch= (targetDir)->new Promise (done)=>
#   watcher= chokidar.watch path.resolve(targetDir)
#   watcher.on "ready", =>
#     await @compileAll()
#     reload()
#     done()
#     watcher.on "all", (e, filepath)=>
#       return if not e.match /^(add|change|unlink)$/
#       await Promise.all _.map @deps, (deps, entry)=>@compile entry if _.contains deps, filepath
#       reload()
#
# PugCompiler::watch= (targetDir)->new Promise (done)=>

# do ->
#   await if fs.existsSync(watch.sass) then sassCompiler.watch(watch.sass)
#   await if fs.existsSync(watch.coffee) then coffeeCompiler.watch(watch.coffee)
#   if fs.existsSync(watch.pug) then pugCompiler.watch(watch.pug)


SassAsset= require "./sassAsset"
CoffeeAsset= require "./coffeeAsset"
PugAsset= require "./pugAsset"

sassAssets= entries.sass.map (entry)->new SassAsset entry
coffeeAssets= entries.coffee.map (entry)->new CoffeeAsset entry
pugAssets= entries.pug.map (entry)->new PugAsset entry




server= new http.Server router(
  get '/:key.js(.:map)', (req, res)->
    send res, 200, coffeeCompiler[if req.params.map? then "sourceMaps" else "results"][req.params.key]
  get '/:key.css(.:map)', (req, res)->
    send res, 200, sassCompiler[if req.params.map? then "sourceMaps" else "results"][req.params.key]
)

server.listen dev.port, dev.host
