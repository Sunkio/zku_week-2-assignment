const hre = require('hardhat')
const { ethers, waffle } = hre
const { loadFixture } = waffle
const { expect } = require('chai')
const { utils } = ethers

const Utxo = require('../src/utxo')
const { transaction, registerAndTransact, prepareTransaction, buildMerkleTree } = require('../src/index')
const { toFixedHex, poseidonHash } = require('../src/utils')
const { Keypair } = require('../src/keypair')
const { encodeDataForBridge } = require('./utils')

const MERKLE_TREE_HEIGHT = 5
const l1ChainId = 1
const MINIMUM_WITHDRAWAL_AMOUNT = utils.parseEther(process.env.MINIMUM_WITHDRAWAL_AMOUNT || '0.05')
const MAXIMUM_DEPOSIT_AMOUNT = utils.parseEther(process.env.MAXIMUM_DEPOSIT_AMOUNT || '1')

it('should estimate, deposit, withdraw, and assert', async () => {
	async function deploy(contractName, ...args) {
	  const Factory = await ethers.getContractFactory(contractName)
	  const instance = await Factory.deploy(...args)
	  return instance.deployed()
	}

	const { merkleTreeWithHistory } = await loadFixture(fixture)
	const gas = await merkleTreeWithHistory.estimateGas.hashLeftRight(toFixedHex(123), toFixedHex(456))
	console.log()


/** @type {TornadoPool} */
const tornadoPoolImpl = await deploy(
	'TornadoPool',
	verifier2.address,
	verifier16.address,
	MERKLE_TREE_HEIGHT,
	hasher.address,
	token.address,
	omniBridge.address,
	l1Unwrapper.address,
	gov.address,
	l1ChainId,
	multisig.address,
  )

  const { data } = await tornadoPoolImpl.populateTransaction.initialize(
	MINIMUM_WITHDRAWAL_AMOUNT,
	MAXIMUM_DEPOSIT_AMOUNT,
  )
  const proxy = await deploy(
	'CrossChainUpgradeableProxy',
	tornadoPoolImpl.address,
	gov.address,
	data,
	amb.address,
	l1ChainId,
  )

  const tornadoPool = tornadoPoolImpl.attach(proxy.address)

  await token.approve(tornadoPool.address, utils.parseEther('10000'))
