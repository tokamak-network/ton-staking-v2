import { ethers, deployments, getNamedAccounts, network } from 'hardhat'
import dotenv from 'dotenv'
dotenv.config()
import Promise from 'bluebird'
import f from 'fs'


const fs = Promise.promisifyAll(f);

function promisify(fn) {
  return function promisified(...params) {
    return new Promise((resolve, reject) => fn(...params.concat([(err, ...args) => err ? reject(err) : resolve( args.length < 2 ? args[0] : args )])))
  }
}

const readdirAsync = promisify(fs.readdir)

export const readContracts = async (folder) => {
  let abis = {}
  let names = []
  let i;

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

export const deployedContracts = async(names, abis, provider) => {
    let deployed = {}
    for (i = 0; i< names.length; i++){
      let name = names[i];
      deployed[name] = new ethers.Contract(abis[name].address, abis[name].abi, provider)
    }
    return deployed;
}
