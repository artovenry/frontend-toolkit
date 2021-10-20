require 'coffeescript/register'
{flatten}= require "underscore"
SassAsset= require "./sassAsset"
CoffeeAsset= require "./coffeeAsset"
PugAsset= require "./pugAsset"

SassAsset.assets= entries.sass.map (entry)->new SassAsset entry
CoffeeAsset.assets= entries.coffee.map (entry)->new CoffeeAsset entry
pugAssets= entries.pug.map (entry)->new PugAsset entry

do ->
  await Promise.all flatten [
    SassAsset.assets.map (a)->await a.compile(); a.write()
    CoffeeAsset.assets.map (a)->await a.compile(); a.write()
  ]
  Promise.all pugAssets.map (a)->await a.compile(); a.write()
