const inquirer = require("inquirer");

module.exports = {
	async mineResources(contract, account) {
		var amount;
		await inquirer
			.prompt([
				{
					type: "input",
					name: "name",
					message: "Enter the amount?",
				},
			])
			.then((x1) => {
				amount = x1.name;
			});
		await contract.methods.mineResources(amount).send({ from: account, gas: 3000000 }).then(console.log);
	},
	async getPlanet(contract) {
		var index;
		await inquirer
			.prompt([
				{
					type: "input",
					name: "name",
					message: "Enter the planet index?",
				},
			])
			.then((x2) => {
				index = x2.name;
			});
		await contract.methods.GetPlanet(index).call().then(console.log);
	},
	async getPlayer(contract, account) {
		await contract.methods.GetPlayer().call({ from: account }).then(console.log);
	},
	async initializePlanet(contract, account) {
		await contract.methods.initializePlanet([0,1,2,3]).send({ from: account, gas: 3000000 }).then(console.log);
	},
};
