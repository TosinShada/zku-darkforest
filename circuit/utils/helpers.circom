pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";

template GCD() {
    signal input in1;
    signal input in2;

    var x = in1;
    var y = in2;
    var rem = 0;

    while ((x % y) > 0)  {
        rem = x % y;
        x = y;
        y = rem;
    }

    component gcdLower = LessThan(64);
    gcdLower.in[0] <== 1;
    gcdLower.in[1] <-- rem;
    gcdLower.out === 1;

    component gcdIsNotPrime = IsNotPrime();
    gcdIsNotPrime.in <-- rem;
    gcdIsNotPrime.out === 1;
}

template IsNotPrime() {
    signal input in;
    signal output out;

    var p = 1;
    var num = in;

    for(var i = 2; i < num; i++){
        // If num is prime then num modulo any number below it will never equal to zero
        // Therefore p = 0 when num is not prime
        if (num % i == 0) {
            p = 0;
        }
    }
    // This equation will make out = 1 if num is not prime and vice versa
    out <-- in * p + 1;
}

template NotInSet(length) {
    signal input element;
    signal input set[length];

    signal output out;

    signal product[length + 1];
    signal inv;
    product[0] <== 1;

    component isEqualChecker[length];
    component isZeroChecker[length];

    for(var i = 0; i < length; i++) {
        isEqualChecker[i] = IsEqual();
        isZeroChecker[i] = IsZero();

        isEqualChecker[i].in[0] <== element;
        isEqualChecker[i].in[1] <== set[i];

        isZeroChecker[i].in <== isEqualChecker[i].out;

        product[i + 1] <== product[i] * isZeroChecker[i].out;
    }

    inv <-- product[length] != 0 ? 1/product[length] : 0;

    out <== product[length] * inv;
}