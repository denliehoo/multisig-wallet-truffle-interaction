const Wallet = artifacts.require("Wallet");

module.exports = function (deployer) {
  // constructor(address[] memory _owners, uint256 _approvalRequired)
  // usually we do deployer.deploy(Contractname)
  // but when there is constructor args, we do deployer.deploy(ContractName, arg1, arg2, arg3,...)
  deployer.deploy(Wallet, ['0x0C45d8d6a6B47BCeFE9917EA6Fc42327A0785213', '0xbF34702431d42F7BBC404DA4a0C38Fc9a0b22E1a', '0x957220B0EdABc5404aB77C0960bdAE05eafD6742'], 2);
};


/* constructor(address[] memory _owners, uint256 _approvalRequired) {
we get the addresses from doing accounts after doing truffle develop
['0x0C45d8d6a6B47BCeFE9917EA6Fc42327A0785213','0xbF34702431d42F7BBC404DA4a0C38Fc9a0b22E1a', '0x957220B0EdABc5404aB77C0960bdAE05eafD6742']

Usually, if no constructors it will be this

const Wallet = artifacts.require("Wallet");

module.exports = function (deployer) {
  deployer.deploy(Wallet);
};


truffle develop
truffle migrate

let Wallet = await Wallet.deployed()

Wallet.viewOwners() // shows the owners

// gets the wallet balance (this is a web3 method)
await web3.eth.getBalance('0x0C45d8d6a6B47BCeFE9917EA6Fc42327A0785213')

0 (owner 1): 0x0C45d8d6a6B47BCeFE9917EA6Fc42327A0785213
1 (owner 2): 0xbF34702431d42F7BBC404DA4a0C38Fc9a0b22E1a
2 (owner 3): 0x957220B0EdABc5404aB77C0960bdAE05eafD6742
3 (test pay to account): 0x35161ad2825F8B30b4EF08d4E2f25D617A4E10e1

//does a deposit of 1 ether from wallet 1 to the smart contract
await Wallet.deposit({value: web3.utils.toWei('1','ether'), from: accounts[1]})

// sees the smart contract address
Wallet.address

// sees the smart contract balance
why is my Wallet.getContractBalance() not giving correct???????
const res = await Wallet.getWalletBalance()
console.log(parseInt(res))
The reason why we have to do this is because we have a BigNumber
and when we have a BigNumber, we have to parse it or else we cant reallly see it
https://studygroup.moralis.io/t/learning-truffle/33848/75
search getWalletBalance

// requests a transfer
// we need to do {from} to specify which account is it from 
await Wallet.requestTransfer(web3.utils.toWei('1','ether'), accounts[3], {from: accounts[2]})

// views the transaction given a specific txId
await Wallet.viewTransaction(0)

// accepts the transfer; same thing need specify which account from
 await Wallet.approvePendingTransaction(0,{from: accounts[1]})

// views the account to verify if value has been sent
await web3.eth.getBalance(accounts[3])

*/