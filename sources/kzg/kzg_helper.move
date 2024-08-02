module starknet_addr::kzg_helper {
    // This line is used for generating constants DO NOT REMOVE!
    // 52435875175126190479447740508185965837690552500527637822603658699938581184513
    const BLS_MODULUS: u256 = 52435875175126190479447740508185965837690552500527637822603658699938581184513;
    // 0x50005
    const EINVALID_KZG_COMMITMENT: u64 = 0x50005;
    // b2157d3a40131b14c4c675335465dffde802f0ce5218ad012284d7f275d1b37c
    const POINT_EVALUATION_PRECOMPILE_OUTPUT: vector<u8> = x"b2157d3a40131b14c4c675335465dffde802f0ce5218ad012284d7f275d1b37c";
    // 01
    const VERSIONED_HASH_VERSION_KZG: vector<u8> = x"01";
    // End of generating constants!


    use std::hash;
    use std::vector;

    public fun kzg_to_versioned_hash(commitment: &vector<u8>): vector<u8> {
        assert!(
            vector::length(commitment) == 48,
            EINVALID_KZG_COMMITMENT
        );
        let versioned_hash_version_kzg = VERSIONED_HASH_VERSION_KZG;
        let hash_commitment = hash::sha2_256(*commitment);
        let hash_commitment_silce = vector::slice(&hash_commitment, 1, vector::length(&hash_commitment));

        let result = vector::empty<u8>();
        vector::append(&mut result, versioned_hash_version_kzg);
        vector::append(&mut result, hash_commitment_silce);

        return result
    }
}