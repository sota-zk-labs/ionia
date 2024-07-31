module starknet_addr::kzg_helper {

    use std::hash;
    use std::vector;

    use starknet_addr::starknet_err;

    const VERSIONED_HASH_VERSION_KZG: vector<u8> = x"01";

    const BLS_MODULUS: u256 = 52435875175126190479447740508185965837690552500527637822603658699938581184513;

    const POINT_EVALUATION_PRECOMPILE_OUTPUT: vector<u8> = x"b2157d3a40131b14c4c675335465dffde802f0ce5218ad012284d7f275d1b37c";

    public fun get_point_evaluation_precompile_output(): vector<u8> {
        return POINT_EVALUATION_PRECOMPILE_OUTPUT
    }

    public fun get_bls_modulus(): u256 {
        return BLS_MODULUS
    }

    public fun get_versioned_hash_version_kzg(): vector<u8> {
        return VERSIONED_HASH_VERSION_KZG
    }

    public fun kzg_to_versioned_hash(commitment: &vector<u8>): vector<u8> {
        assert!(
            vector::length(commitment) == 48,
            starknet_err::err_invalid_kzg_commitment()
        );
        let versioned_hash_version_kzg = get_versioned_hash_version_kzg();
        let hash_commitment = hash::sha2_256(*commitment);
        let hash_commitment_silce = vector::slice(&hash_commitment, 1, vector::length(&hash_commitment));

        let result = vector::empty<u8>();
        vector::append(&mut result, versioned_hash_version_kzg);
        vector::append(&mut result, hash_commitment_silce);

        return result
    }
}