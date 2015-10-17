#! /usr/bin/env node
parseArgs = require("minimist")
_ = require("lodash")

NpmMine = require("../lib/index")

var args = parseArgs(process.argv.slice(3));
var action = process.argv[2];

var legal = true;

switch(action){
  case "count":
    args = _.defaults(args, {
      threshold: 500,
    })

    break;
    
  case "download":
    args = _.defaults(args, {
      threshold: 500,
    })

    if(args.path === undefined){
      console.log("Missing argument: path");     
      legal = false
    }

    break;
}

if(legal)
  NpmMine[action].call(null, args);