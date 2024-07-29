module starknet_addr::helper {

    use std::hash;
    use std::vector;

    use starknet_addr::starknet_err;

    const VERSIONED_HASH_VERSION_KZG: vector<u8> = x"01";

    public fun get_versioned_hash_version_kzg(): vector<u8> {
        return VERSIONED_HASH_VERSION_KZG
    }

    public fun kzg_to_versioned_hash(commitment: vector<u8>): vector<u8> {
        assert!(
            vector::length(&commitment) == 48,
            starknet_err::err_invalid_kzg_commitment()
        );
        let versioned_hash_version_kzg = get_versioned_hash_version_kzg();
        let hash_commitment = hash::sha2_256(commitment);
        let result = vector::empty<u8>();
        vector::append(&mut result, versioned_hash_version_kzg);
        vector::append(&mut result, hash_commitment);
        return result
    }
}

module starknet_addr::bls {

    const BLS_MODULUS: u256 = 52435875175126190479447740508185965837690552500527637822603658699938581184513;

    public fun get_bls_modulus(): u256 {
        return BLS_MODULUS
    }
}