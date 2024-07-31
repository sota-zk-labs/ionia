module starknet_addr::pre_compile {

    use std::bcs;
    use std::vector;

    use starknet_addr::bls;
    use starknet_addr::helper;
    use starknet_addr::kzg;
    use starknet_addr::starknet_err;

    const FIELD_ELEMENTS_PER_BLOB: u256 = 4096;

    public fun point_evaluation_precompile(bytes: vector<u8>): (vector<u8>, bool) {

        assert!(
            vector::length(&bytes) == 192,
            starknet_err::err_invalid_pre_compile_input_size()
        );

        let versioned_hash = vector::slice(&bytes, (0u64), (31 as u64));
        let z = vector::slice(&bytes, (32 as u64), (63 as u64));
        let y = vector::slice(&bytes, (64 as u64), (95 as u64));
        let commitment = vector::slice(&bytes, (96 as u64), (143 as u64));
        let proof = vector::slice(&bytes, (144 as u64), (192 as u64));

        // Verify commitment matches versioned_hash
        assert!(
            helper::kzg_to_versioned_hash(commitment) == versioned_hash,
            starknet_err::err_unexpected_version_hash()
        );

        // Verify KZG proof with z and y in big-endian format (LSB format in Aptos)

        // assert!(
        //     kzg::verify_kzg_proof(commitment, z, y, proof),
        //     starknet_err::err_invalid_kzg_commitment()
        // );

        let bls_modulus = bls::get_bls_modulus();

        return (bcs::to_bytes(&(FIELD_ELEMENTS_PER_BLOB + bls_modulus)), true)
    }
}