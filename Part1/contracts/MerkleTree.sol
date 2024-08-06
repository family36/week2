// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; // an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; // inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        uint256 numLeaves = 8;
        uint256 treeDepth = 3; // log2(8) = 3
        uint256 numNodes = 2 * numLeaves - 1; // Full binary tree with 8 leaves

        hashes = new uint256[](numNodes);
        for (uint256 i = 0; i < numLeaves; i++) {
            hashes[i] = 0; // Initializing leaves with blank (0) values
        }

        // Compute the internal nodes
        uint256 offset = numLeaves;
        for (uint256 level = 1; level <= treeDepth; level++) {
            uint256 numPairs = numLeaves / 2**level;
            for (uint256 i = 0; i < numPairs; i++) {
                hashes[offset + i] = PoseidonT3.poseidon([hashes[offset - numPairs * 2 + 2 * i], hashes[offset - numPairs * 2 + 2 * i + 1]]);
            }
            offset += numPairs;
        }

        root = hashes[hashes.length - 1]; // The root is the last element in the array
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        require(index < 8, "Merkle tree is full");

        uint256 numLeaves = 8;
        uint256 treeDepth = 3;

        // Insert the new leaf
        hashes[index] = hashedLeaf;

        // Update the internal nodes
        uint256 currentIdx = index;
        uint256 offset = numLeaves;

        for (uint256 level = 1; level <= treeDepth; level++) {
            uint256 pairIdx = currentIdx / 2;
            hashes[offset + pairIdx] = PoseidonT3.poseidon([hashes[offset - numLeaves + 2 * pairIdx], hashes[offset - numLeaves + 2 * pairIdx + 1]]);
            currentIdx = pairIdx;
            offset += numLeaves / 2**level;
        }

        // Update the root
        root = hashes[hashes.length - 1];

        index++;
        return root;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {
        // [assignment] verify an inclusion proof and check that the proof root matches current root
        require(input[0] == root, "Proof root does not match current root");
        return verifyProof(a, b, c, input);
    }
}
