pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../../../circomlib/circuits/mux1.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    signal hashers[2**n / 2];
    component poseidons[2**n / 2];

    for (var i = 0; i < 2**n; i += 2) {
        poseidons[i / 2] = Poseidon(2);
        poseidons[i / 2].inputs[0] <== leaves[i];
        poseidons[i / 2].inputs[1] <== leaves[i + 1];
        hashers[i / 2] <== poseidons[i / 2].out;
    }

    for (var level = 1; level < n; level++) {
        for (var i = 0; i < 2**(n - level); i += 2) {
            poseidons[i / 2] = Poseidon(2);
            poseidons[i / 2].inputs[0] <== hashers[i];
            poseidons[i / 2].inputs[1] <== hashers[i + 1];
            hashers[i / 2] <== poseidons[i / 2].out;
        }
    }

    root <== hashers[0];
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component poseidons[n];
    component mux[n];

    signal hashers[n + 1];
    hashers[0] <== leaf;

    for (var i = 0; i < n; i++) {
        poseidons[i] = Poseidon(2);

        mux[i].c[0][0] <== hashes[i];
        mux[i].c[0][1] <== path_elements[i];

        mux[i].c[1][0] <== path_elements[i];
        mux[i].c[1][1] <== hashes[i];

        mux[i].s <== path_index[i];

        poseidons[i].inputs[0] <== mux[i].out[0];
        poseidons[i].inputs[1] <== mux[i].out[1];

        hashers[i + 1] <== poseidons[i].out;
    }

    root <== hashers[n];
}