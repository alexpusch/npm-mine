#! /usr/bin/env node
parseArgs = require("minimist")
_ = require("lodash")
NpmMine = require("../lib/index")
function validateAction(action){
  return ["metadata", "download", "count"].indexOf(action) >= 0
}

function validateArgs(action, args){
  switch(action){
    case "download": 
      if(args.path === undefined){
        console.log("Missing argument: path");
        return false;
      }
  }

  return true;
}

function printUsage(){
  var usage = "usage: npm-mine <command> [--threshold=threshold] [--path=path]\n\n"
  usage += "commands:\n"
  usage += "\tmetadata \t mines npms metadata and downloads from npm's repository\n"
  usage += "\tdownload \t downloads all npms with more than [threshold] downloads last month\n"
  usage += "\tcount \t\t counts all npms with more than [threshold] downloads last month\n"

  console.log(usage);
}

var args = parseArgs(process.argv.slice(3));
var action = process.argv[2];

args = _.defaults(args, {
  threshold: 500,
})

if(validateAction(action) && validateArgs(action, args))
  NpmMine[action].call(null, args);
else
  printUsage();
