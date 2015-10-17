#! /usr/bin/env node
parseArgs = require("minimist")

NpmMine = require("../lib/index")

var args = parseArgs(process.argv.slice(3));
var action = process.argv[2];

NpmMine[action]();