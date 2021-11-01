require "coffeescript/register"

path= require "path"
config= require "./config"
SassAsset= require "./sassAsset"
CoffeeAsset= require "./coffeeAsset"
PugAsset= require "./pugAsset"
{flatten, findWhere, map}= require "underscore"

sassAssets= config.entries.sass.map (e)->new SassAsset e
coffeeAssets= config.entries.coffee.map (e)->new CoffeeAsset e

pugAssets= config.entries.pug.map (e)->new PugAsset e

PugAsset.assets.sass.push asset for asset in sassAssets
PugAsset.assets.coffee.push asset for asset in coffeeAssets

do ->
  await Promise.all flatten [
    sassAssets.map (a)-> new Promise (done)->
      await a.compile()
      done(); if not config.purge? then a.write()
    coffeeAssets.map (a)-> new Promise (done)->
      await a.compile()
      done(); a.write()
  ]

  await Promise.all pugAssets.map (a)-> new Promise (done)->
    await a.compile()
    done(); if not config.purge? then a.write()

  if config.purge?
    await Promise.all map config.purge, (pugAssetNames, assetName)->
      asset= findWhere sassAssets, {name: assetName}
      .purge pugAssetNames.map (name)->findWhere(pugAssets, {name}).code

    sassAssets.forEach (a)->a.write()
    pugAssets.forEach (a)->await a.compile(); a.write()
