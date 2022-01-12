const wc = require("./circuit/move/circuit_js/witness_calculator.js");
const fs = require("fs");

const wasm = "./circuit/move/circuit_js/circuit.wasm";
const WITNESS_FILE = "moveWitness.wtns";

module.exports = {
	async generateMoveWitness(inputs) {
		const buffer = fs.readFileSync(wasm);
		const witnessCalculator = await wc(buffer);
		const buff = await witnessCalculator.calculateWTNSBin(inputs, 0);
		fs.writeFileSync(WITNESS_FILE, buff);
	}
};
