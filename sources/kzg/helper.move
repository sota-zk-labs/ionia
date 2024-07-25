module starknet_addr::helper {

    use std::vector;
    use std::hash;
    use starknet_addr::starknet_err;
    use starknet_addr::starknet_validity;

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
    use aptos_std::bls12381_algebra::{G2, G1};
    use aptos_std::crypto_algebra;
    use aptos_std::crypto_algebra::Element;
    use aptos_std::from_bcs;

    const G1_FR: vector<u8> = x"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb";
    const G2_FR: vector<u8> = x"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8";
    const BLS_MODULUS: u256 = 52435875175126190479447740508185965837690552500527637822603658699938581184513;

    public fun get_bls_modulus(): u256 {
        return BLS_MODULUS
    }

    public fun g1(): Element<G1> {
        return bytes_to_G1(G1_FR)
    }

    public fun g2(): Element<G2> {
        return bytes_to_G2(G2_FR)
    }

    public fun bytes_to_G2(element: vector<u8>): Element<G2> {
        let u64_element = from_bcs::to_u64(element);
        crypto_algebra::from_u64<G2>(u64_element)
    }

    public fun bytes_to_G1(element: vector<u8>): Element<G1> {
        let u64_element = from_bcs::to_u64(element);
        crypto_algebra::from_u64<G1>(u64_element)

    }
}