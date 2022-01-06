const snarkjs = require("snarkjs");
const ff = require("ffjavascript");
const fs = require("fs");
var Web3 = require("web3");
var inquirer = require("inquirer");

const wc = require("./circuit/init/circuit_js/witness_calculator.js");
const wasm = "./circuit/init/circuit_js/circuit.wasm";
const zkey = "./circuit/init/circuit_0001.zkey";
const INPUTS_FILE = "/tmp/inputs";
const WITNESS_FILE = "witness.wtns";
const {unstringifyBigInts} = ff.utils;

//connection with node
var web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:8545/"));
// contractAddress and abi are setted after contract deploy
var contractAddress = "0xA068C7D060023F1a616b0a6335C8B10Ad89e5799";
var abi = JSON.parse(fs.readFileSync("./abi.json"));
//contract instance
contract = new web3.eth.Contract(abi, contractAddress);

const generateWitness = async (inputs) => {
	const buffer = fs.readFileSync(wasm);
	const witnessCalculator = await wc(buffer);
	const buff = await witnessCalculator.calculateWTNSBin(inputs, 0);
	fs.writeFileSync(WITNESS_FILE, buff);
};

const main = async () => {
	var accounts = await web3.eth.getAccounts();
	var xCoor;
	var yCoor;
	await inquirer
		.prompt([
			{
				type: "input",
				name: "name",
				message: "Enter your X Coordinate?",
			},
		])
		.then((x) => {
			xCoor = x.name;
		});

	await inquirer
		.prompt([
			{
				type: "input",
				name: "name",
				message: "Enter your Y Coordinate?",
			},
		])
		.then((y) => {
			yCoor = y.name;
		});

	const inputSignals = {
		x: parseInt(xCoor),
		y: parseInt(yCoor),
		maxR: 64,
		minR: 32,
		HASH_KEY: 7,
	};
	await generateWitness(inputSignals);

	const { proof, publicSignals } = await snarkjs.groth16.prove(
		zkey,
		WITNESS_FILE
	);

    const editedPublicSignals = unstringifyBigInts(publicSignals);
    const editedProof = unstringifyBigInts(proof);

	const calldata = await snarkjs.groth16.exportSolidityCallData(
		editedProof,
		editedPublicSignals
	);

	const calldataSplit = calldata.split(",");
	let a = eval(calldataSplit.slice(0, 2).join());
	let b = eval(calldataSplit.slice(2, 6).join());
	let c = eval(calldataSplit.slice(6, 8).join());
	let input = eval(calldataSplit.slice(8, 12).join());

	await contract.methods
		.initializePlayer(a,b,c,input)
		.send({ from: accounts[0], gas: 3000000 })
		.then(console.log);

	console.log("Calling the smart contract function to get the number of players in the game and confirm it has received this player")
	await contract.methods.GetPlayerCount().call().then(console.log);
};

const runMain = async () => {
	try {
		await main();
		process.exit(0);
	} catch (error) {
		console.log(error);
		process.exit(1);
	}
};

runMain();
