# Npm-Mine

**Goal:** Create a private npm repository, storing only popular npms.

**How:** Figure out what are the popular npms by mining the npm repository and downloads count API. With this data we then download all the best npms as tar.gz.

**Additional tools to reach goal:** 
 - [Sinopia](https://github.com/rlidwka/sinopia) - host npm repository, storing downloaded npms
 - [Fishman](https://github.com/idosh/Fishman) - download a list of wanted npms

config
-------------
All data is stored in a mongoDB database. Config your db in config.json:

```json
{
  "mongoDBUri": "mongodb://localhost:27017/npm-mine"
}
```


usage
------
```
npm-mine <command> [--threshold=threshold] [--path=path]

commands:
  metadata   mines npms metadata and downloads count from npm's repository
  download   downloads all npms with more than [threshold] downloads last month
  count      counts all npms with more than [threshold] downloads last month

```
