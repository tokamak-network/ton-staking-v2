
const {ethers} = require("ethers")
const { Wallet }  = require("ethers")
const Promise = require('bluebird');
const fs = Promise.promisifyAll(require('fs'));
require('dotenv').config()

let wallets;

function promisify(fn) {
  return function promisified(...params) {
    return new Promise((resolve, reject) => fn(...params.concat([(err, ...args) => err ? reject(err) : resolve( args.length < 2 ? args[0] : args )])))
  }
}

const readdirAsync = promisify(fs.readdir)

const readContracts = async (folder)  => {
  let abis = {}
  let names = []
  await readdirAsync(folder).then(filenames => {
    for(i=0; i< filenames.length; i++){
      let e = filenames[i]
      if (e.indexOf(".json") > 0) {
        names.push(e.substring(0, e.indexOf(".json")))
        abis[e.substring(0, e.indexOf(".json"))] = require(folder+"/"+e)
      }
    }
  })
  return  {names, abis}
}

async function deployedContracts(names, abis, provider){
    let deployed = {}
    for (i = 0; i< names.length; i++){
      let name = names[i];
      deployed[name] = new ethers.Contract(abis[name].address, abis[name].abi, provider)
    }
    return deployed;
}

module.exports = {
    readContracts,
    deployedContracts
}
