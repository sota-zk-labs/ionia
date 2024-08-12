module starknet_addr::kzg_helper {
    use std::hash;
    use std::vector;

    // This line is used for generating constants DO NOT REMOVE!
    // 327685
    const EINVALID_KZG_COMMITMENT: u64 = 0x50005;
    // 01
    const VERSIONED_HASH_VERSION_KZG: u8 = 0x1;
    // End of generating constants!

    public fun kzg_to_versioned_hash(commitment: &vector<u8>): vector<u8> {
        assert!(
            vector::length(commitment) == 48,
            EINVALID_KZG_COMMITMENT
        );

        let hash_commitment = hash::sha2_256(*commitment);
        *vector::borrow_mut(&mut hash_commitment, 0) = VERSIONED_HASH_VERSION_KZG;

        return hash_commitment
    }
}