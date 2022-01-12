#!/bin/bash
echo "compiling solidity files..." &&
truffle compile --all &&
echo "deploying contracts..." &&
truffle migrate