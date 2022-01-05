const snarkjs = require("snarkjs");
const fs = require("fs");
var Web3 = require("web3");
var inquirer = require("inquirer");

const wc = require("./circuit/init/circuit_js/witness_calculator.js");
const wasm = "./circuit/init/circuit_js/circuit.wasm";
const zkey = "./circuit/init/circuit_0001.zkey";
const INPUTS_FILE = "/tmp/inputs";
const WITNESS_FILE = "witness.wtns";

//connection with node
var web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:8545/"));
// contractAddress and abi are setted after contract deploy
var contractAddress = "0x2baB28594D99BCf9feC77213Cb104455B2Aad892";
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

	// This function is returning a different call data than the one from the compiler and giving value out of bounds error
	// Instead I am picking the call data from the compiler and therefore I'm not able to simulate other coordinate from the console
	const calldata = await snarkjs.groth16.exportSolidityCallData(
		proof,
		publicSignals
	);

	const calldataSplit = calldata.split(",");
	let a = eval(calldataSplit.slice(0, 2).join());
	let b = eval(calldataSplit.slice(2, 6).join());
	let c = eval(calldataSplit.slice(6, 8).join());
	let input = eval(calldataSplit.slice(8, 12).join());

	await contract.methods
		.initializePlayer(["0x2c509839c1440e982eba099542d125e1a08f73a1e2fb91c5163eed56fa17a250","0x20a31ea719ba3ae839c63ca3c385161617ca9b50799596e24952736f56380b00"],[["0x0c94f6cfb362483d224b44be033056345138a416be10126a167c36b65bf74080","0x1b4391fa4f4f652b92eda3612f8c866efa042c5dead8d9e9fced63b946bd57e1"],["0x1a520ea4ca940d7ee3e4a0605e4d4f76362071081d9a693e3533e3c55b2f834c","0x11887791d8320fbcb32f1072b8626644abed57691fcafd36765756dc4bcc8230"]],["0x19fd81c32ef9d963ba9490079b910f0ceecf7ec0ac54a6176e047eb3b9949e8a","0x23b1c4f778bbe8e57c1b70c47596005ec269982b2e6077776a95d91604099939"],["0x1e8ac9de1c884abcee0b1330728c5218a6cc2bfeaf42b07837e826ff112192e8","0x0000000000000000000000000000000000000000000000000000000000000040","0x0000000000000000000000000000000000000000000000000000000000000020","0x0000000000000000000000000000000000000000000000000000000000000007"])
		.send({ from: accounts[0], gas: 3000000 });

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
