#!/bin/bash
echo "clearing files"
rm circuit.r1cs
rm circuit.wasm
rm circuit.sym
rm circuit_0000.zkey
rm circuit_0001.zkey
rm pot12_0000.ptau
rm pot12_0001.ptau
rm pot12_final.ptau
rm verification_key.json
rm verifier.sol
rm proof.json
rm public.json
rm witness.wtns
rm -rf circuit_js
echo "compiling circuit to r1cs..." &&
date &&
circom circuit.circom --r1cs --wasm --sym &&
echo "computing the witness with webassembly..." &&
node circuit_js/generate_witness.js circuit_js/circuit.wasm input.json witness.wtns &&
echo "creating the trusted setup..." &&
echo "phase 1 with the power of tao ceremony which is circuit independent..." &&
date &&
snarkjs powersoftau new bn128 12 pot12_0000.ptau -v &&
snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="zkuOne" -v &&
echo "phase 2 which is circuit specific..." &&
date &&
snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v &&
snarkjs groth16 setup circuit.r1cs pot12_final.ptau circuit_0000.zkey &&
snarkjs zkey contribute circuit_0000.zkey circuit_0001.zkey --name="Tosin" -v &&
snarkjs zkey export verificationkey circuit_0001.zkey verification_key.json &&
echo "generating proof..." &&
date &&
snarkjs groth16 prove circuit_0001.zkey witness.wtns proof.json public.json
echo "verifying proof..." &&
date &&
snarkjs groth16 verify verification_key.json public.json proof.json &&
echo "compiling smart contract..." &&
date &&
snarkjs zkey export solidityverifier circuit_0001.zkey verifier.sol &&
echo "done!" &&
date