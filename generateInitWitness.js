const wc = require("./circuit/init/circuit_js/witness_calculator.js");
const fs = require("fs");

const wasm = "./circuit/init/circuit_js/circuit.wasm";
const WITNESS_FILE = "initWitness.wtns";

module.exports = {
	async generateInitWitness(inputs) {
		const buffer = fs.readFileSync(wasm);
		const witnessCalculator = await wc(buffer);
		const buff = await witnessCalculator.calculateWTNSBin(inputs, 0);
		fs.writeFileSync(WITNESS_FILE, buff);
	}
};
