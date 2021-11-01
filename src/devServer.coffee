require "coffeescript/register"

path= require "path"
config= require "./config"
SassAsset= require "./sassAsset"
CoffeeAsset= require "./coffeeAsset"
PugAsset= require "./pugAsset"
Watcher= require "./watcher"

sassAssets= config.entries.sass.map (e)->new SassAsset e
coffeeAssets= config.entries.coffee.map (e)->new CoffeeAsset e

pugAssets= config.entries.pug.map (e)->new PugAsset e

PugAsset.assets.sass.push asset for asset in sassAssets
PugAsset.assets.coffee.push asset for asset in coffeeAssets

http = require('http')
{send}= require "micro"
{router, get}= require "microrouter"
WS= require "ws"
process= require "process"
{host, port, wsport}= config.dev
{findWhere}= require "underscore"

ws_server= new WS.Server {host, port: wsport}
console.log "WebSocket server running at http://#{host}:#{wsport}"
process.on "SIGINT", ->ws_server.close(); process.exit(0)


server= new http.Server router(
  get '/:filename.js(.:map)', (req, res)->
    send res, 200, do ->
      asset= findWhere coffeeAssets, outputFilename: req.params.filename + ".js"
      asset[if req.params.map? then "map" else "code"]
  get '/:filename.css(.:map)', (req, res)->
    send res, 200, do ->
      asset= findWhere sassAssets, outputFilename: req.params.filename + ".css"
      asset[if req.params.map? then "map" else "code"]
)
server.listen port, host

sassWatcher= new Watcher targetDir: config.watch.sass, assets: sassAssets
coffeeWatcher= new Watcher targetDir: config.watch.coffee, assets: coffeeAssets
pugWatcher= new Watcher targetDir: config.watch.pug, assets: pugAssets
reload= ->ws_server.clients.forEach (c)->c.send "reload"

do ->
  await Promise.all [
    sassWatcher.watch {afterCompile: reload}
    coffeeWatcher.watch {afterCompile: reload}
  ]
  pugWatcher.watch afterCompile: ->
    await Promise.all @assets.map (a)->a.write()
    reload()
