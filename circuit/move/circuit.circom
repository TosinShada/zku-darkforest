/*
    Prove: I know (x1,y1,x2,y2,maxR,distMax) such that:
    - x2^2 + y2^2 <= maxR^2
    - (x1-x2)^2 + (y1-y2)^2 <= distMax^2
    - MiMCSponge(x1,y1) = pub1
    - MiMCSponge(x2,y2) = pub2
*/
pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/mimcsponge.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";

template Main() {
    signal input x1;
    signal input y1;
    signal input x2;
    signal input y2;
    signal input maxR;
    signal input distMax;

    signal output pub1;
    signal output pub2;

    /* check x2^2 + y2^2 < maxR^2 */

    component comp2 = LessThan(32);
    signal x2Sq;
    signal y2Sq;
    signal maxRSq;
    x2Sq <== x2 * x2;
    y2Sq <== y2 * y2;
    maxRSq <== maxR * maxR;
    comp2.in[0] <== x2Sq + y2Sq;
    comp2.in[1] <== maxRSq;
    comp2.out === 1;

    /* check (x1-x2)^2 + (y1-y2)^2 <= distMax^2 */

    signal diffX;
    diffX <== x1 - x2;
    signal diffY;
    diffY <== y1 - y2;

    component ltDist = LessThan(32);
    signal firstDistSquare;
    signal secondDistSquare;
    firstDistSquare <== diffX * diffX;
    secondDistSquare <== diffY * diffY;
    ltDist.in[0] <== firstDistSquare + secondDistSquare;
    ltDist.in[1] <== distMax * distMax + 1;
    ltDist.out === 1;

    /* check MiMCSponge(x1,y1) = pub1, MiMCSponge(x2,y2) = pub2 */
    component mimc1 = MiMCSponge(2, 220, 1);
    component mimc2 = MiMCSponge(2, 220, 1);

    mimc1.ins[0] <== x1;
    mimc1.ins[1] <== y1;
    mimc1.k <== 0;
    mimc2.ins[0] <== x2;
    mimc2.ins[1] <== y2;
    mimc2.k <== 0;

    pub1 <== mimc1.outs[0];
    pub2 <== mimc2.outs[0];
}

component main {public [distMax,maxR]} = Main();