const gw = require("./generateInitWitness.js");
const inquirer = require("inquirer");
const ff = require("ffjavascript");
const snarkjs = require("snarkjs");

const zkey = "./circuit/init/circuit_0001.zkey";
const WITNESS_FILE = "initWitness.wtns";
const {unstringifyBigInts} = ff.utils;

module.exports = {
	async initialize(contract, account) {
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
		};
		await gw.generateInitWitness(inputSignals);

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
		let input = eval(calldataSplit.slice(8, 11).join());

		await contract.methods
			.initializePlayer(a, b, c, input)
			.send({ from: account, gas: 3000000 })
			.then(console.log);
	},
};
