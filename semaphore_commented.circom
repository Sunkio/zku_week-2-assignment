pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "./tree.circom";

/**
* The Semaphore circuits allow you to prove 3 things:
* 1 - via Merkle tree: that the identity commitment exists in the Merkle tree,
* 2 - via Nullifiers: that the signal was only broadcasted once,
* 3 - via Signal: that the signal was truly broadcasted by the user who generated the proof.
*/

/**
* @identityNullifier - privat input, a random 32-byte value which the user should save
* @identityTrapdoor - privat input, a random 32-byte value which the user should save as well
* @Poseidon - use of the Poseidon hashing algorithm to create the hashes of identityNullifier and indentityTrapdoor
* this will be used to generate the commitment
*/
template CalculateSecret() {
    signal input identityNullifier;
    signal input identityTrapdoor;

    signal output out;

    component poseidon = Poseidon(2);

    poseidon.inputs[0] <== identityNullifier;
    poseidon.inputs[1] <== identityTrapdoor;

    out <== poseidon.out;
}

/**
* @secret is the poseidon output signal of the CalculateSecret function which has already been created with the Poseidon hashing algorithm
* and gets hashed here with Poseidon once again to oscure it even more
*/
template CalculateIdentityCommitment() {
    signal input secret;

    signal output out;

    component poseidon = Poseidon(1);

    poseidon.inputs[0] <== secret;

    out <== poseidon.out;
}

/**
* @externalNullifier - public input, 32-byte external nullifier
* @identityNullifier - private input, a random 32-byte value which the user should save
* @out - public output, the hash of the identity nullifier and the external nullifier (= nullifierHash)
* generated via Poseidon hashing algorithm
*/
template CalculateNullifierHash() {
    signal input externalNullifier;
    signal input identityNullifier;

    signal output out;

    component poseidon = Poseidon(2);

    poseidon.inputs[0] <== externalNullifier;
    poseidon.inputs[1] <== identityNullifier;

    out <== poseidon.out;
}

// nLevels must be < 32.
template Semaphore(nLevels) {
    signal input identityNullifier;
    signal input identityTrapdoor;
    signal input treePathIndices[nLevels]; // privat input, the direction (0/1) per tree level
    signal input treeSiblings[nLevels]; // private input, the values along the Merkle path to the user's identity commitment

    signal input signalHash;
    signal input externalNullifier;

    signal output root;
    signal output nullifierHash;

    component calculateSecret = CalculateSecret();
    calculateSecret.identityNullifier <== identityNullifier;
    calculateSecret.identityTrapdoor <== identityTrapdoor;

    signal secret;
    secret <== calculateSecret.out;

    component calculateIdentityCommitment = CalculateIdentityCommitment();
    calculateIdentityCommitment.secret <== secret;

	// The circuit hashes the identity nullifier and the external nullifier. The it checks that it matches the given nullifiers hash. 
	// Additionally, the smart contract ensures that it has not previously seen this nullifiers hash. This way, double-signalling is impossible.
    component calculateNullifierHash = CalculateNullifierHash();
    calculateNullifierHash.externalNullifier <== externalNullifier;
    calculateNullifierHash.identityNullifier <== identityNullifier;

	// Verification of the Merkle proof against the Merkle root and the identity commitment.
    component inclusionProof = MerkleTreeInclusionProof(nLevels);
    inclusionProof.leaf <== calculateIdentityCommitment.out;

    for (var i = 0; i < nLevels; i++) {
        inclusionProof.siblings[i] <== treeSiblings[i];
        inclusionProof.pathIndices[i] <== treePathIndices[i];
    }
	// @root - public output, the Merkle root of the identity tree
    root <== inclusionProof.root;

    // Dummy square to prevent tampering signalHash.
	// signalHash is the hash of the user's signal.
    signal signalHashSquared;
    signalHashSquared <== signalHash * signalHash;

    nullifierHash <== calculateNullifierHash.out;
}

component main {public [signalHash, externalNullifier]} = Semaphore(20);
