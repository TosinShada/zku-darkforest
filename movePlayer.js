const gw = require("./generateMoveWitness.js");
const inquirer = require("inquirer");
const ff = require("ffjavascript");
const snarkjs = require("snarkjs");

const zkey = "./circuit/move/circuit_0001.zkey";
const WITNESS_FILE = "moveWitness.wtns";
const {unstringifyBigInts} = ff.utils;

module.exports = {
	async move(contract, account) {
		var x1Coor;
		var y1Coor;
		var x2Coor;
		var y2Coor;

		await inquirer
			.prompt([
				{
					type: "input",
					name: "name",
					message: "Enter your present X Coordinate?",
				},
			])
			.then((x1) => {
				x1Coor = x1.name;
			});

		await inquirer
			.prompt([
				{
					type: "input",
					name: "name",
					message: "Enter your present Y Coordinate?",
				},
			])
			.then((y1) => {
				y1Coor = y1.name;
			});

		await inquirer
			.prompt([
				{
					type: "input",
					name: "name",
					message: "Enter your next X Coordinate?",
				},
			])
			.then((x2) => {
				x2Coor = x2.name;
			});

		await inquirer
			.prompt([
				{
					type: "input",
					name: "name",
					message: "Enter your next Y Coordinate?",
				},
			])
			.then((y2) => {
				y2Coor = y2.name;
			});

		const inputSignals = {
			x1: parseInt(x1Coor),
			y1: parseInt(y1Coor),
			x2: parseInt(x2Coor),
			y2: parseInt(y2Coor),
			maxR: 128,
			distMax: 16,
		};

		await gw.generateMoveWitness(inputSignals);

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
			.move(a, b, c, input)
			.send({ from: account, gas: 3000000 })
			.then(console.log);
	},
};
