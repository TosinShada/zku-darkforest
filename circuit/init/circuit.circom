pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/mimcsponge.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../utils/helpers.circom";

template Main(length) {
    signal input x;
    signal input y;
    signal input maxR;
    signal input minR;

    signal output pub;

    /* check abs(x), abs(y) <= 2^31 */
    component n2bx = Num2Bits(32);
    n2bx.in <== x + (1 << 31);
    component n2by = Num2Bits(32);
    n2by.in <== y + (1 << 31);

    // check the (x - 0)^2 + (y - 0)^2 < 64^2
    // Simplified as x^2 + y^2 < 64^2
    component compUpper = LessThan(64);
    signal xSq;
    signal ySq;
    signal maxRSq;
    xSq <== x * x;
    ySq <== y * y;
    maxRSq <== maxR * maxR;
    compUpper.in[0] <== xSq + ySq;
    compUpper.in[1] <== maxRSq;
    compUpper.out === 1;

    // check the (x - 0)^2 + (y - 0)^2 > 32^2
    // Simplified as x^2 + y^2 > 32^2
    component compLower = LessThan(64);
    signal minRSq;
    minRSq <== minR * minR;
    compLower.in[0] <== minRSq;
    compLower.in[1] <== xSq + ySq;
    compLower.out === 1;

    //check MiMCSponge(x,y) = pub 
    // verify that the hash value is the mimc hash of the input coordinates
    component mimc = MiMCSponge(2, 220, 1);

    mimc.ins[0] <== x;
    mimc.ins[1] <== y;
    mimc.k <== 0;

    pub <== mimc.outs[0];

    // check that the gcd of x and y is greater than one and not a prime number
    component gcdCheck = GCD();
    gcdCheck.in1 <== x;
    gcdCheck.in2 <== y;
}

component main {public [maxR,minR]} = Main(10);
