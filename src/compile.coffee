require 'coffeescript/register'
{entries, purge}= require "./config"
{flatten}= require "underscore"
SassAsset= require "./sassAsset"
CoffeeAsset= require "./coffeeAsset"
PugAsset= require "./pugAsset"

sassAssets= entries.sass.map (entry)->new SassAsset entry
coffeeAssets= entries.coffee.map (entry)->new CoffeeAsset entry
pugAssets= entries.pug.map (entry)->new PugAsset entry


compilePugs= ->
  Promise.all pugAssets.map (a)->
    a.updateAssets sass: sassAssets, coffee: coffeeAssets
    a.compile()

do ->
  await Promise.all flatten [
    sassAssets.map (a)->
      await a.compile()
      if not purge? then a.write()
    coffeeAssets.map (a)->
      await a.compile()
      a.write()
  ]
  await compilePugs()

  ###
    "global": ["index.php", "hoo.php", "bar.html"]
  ###
  if purge?
    {map, findWhere}= require "underscore"
    await Promise.all map purge, (pugAssetNames, name)->
      sassAsset= findWhere sassAssets, {name}
      await sassAsset.purge pugAssetNames.map (name)->
        findWhere(pugAssets, {name}).code
    compilePugs()
    sassAssets.map (a)->a.write()
