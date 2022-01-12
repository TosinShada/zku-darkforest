const fs = require("fs");
const Web3 = require("web3");
const inquirer = require("inquirer");
const ip = require("./initializePlayer.js");
const mp = require("./movePlayer.js");
const cc = require("./contractCalls.js");

//connection with node
var web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:8545/"));
// contractAddress and abi are setted after contract deploy
var contractAddress = "0x46593B03a098d0fd9494CFc7804609B505C78631";
var abi = JSON.parse(fs.readFileSync("./abi.json"));
//contract instance
contract = new web3.eth.Contract(abi, contractAddress);

const main = async () => {
	console.log("Welcome to DarkForest!");

	var index;
	await inquirer
		.prompt([
			{
				type: "input",
				name: "name",
				message: "Pick an account from 0-9",
			},
		])
		.then((acct) => {
			index = acct.name;
		});

	var accounts = await web3.eth.getAccounts();
	var account = accounts[index];

	console.log("Game Menu Options");
	console.log("1. Spawn a player");
	console.log("2. Move player");
	console.log("3. Get planet");
	console.log("4. Get player");
	console.log("5. Mine resources");
	console.log("6. Initialize planet");
	var start;
	await inquirer
		.prompt([
			{
				type: "input",
				name: "name",
				message: "Pick an option?",
			},
		])
		.then((input) => {
			start = input.name;
		});

	switch (parseInt(start)) {
		case 1:
			await ip.initialize(contract, account);
			break;
		case 2:
			await mp.move(contract, account);
			break;
		case 3:
			await cc.getPlanet(contract);
			break;
		case 4:
			await cc.getPlayer(contract, account);
			break;
		case 5:
			await cc.mineResources(contract, account);
			break;
		case 6:
			await cc.initializePlanet(contract, account);
			break;
		default:
			break;
	}
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
