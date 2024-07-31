module starknet_addr::pre_compile {

    use std::vector;

    use starknet_addr::bytes;
    use starknet_addr::kzg_helper;
    use starknet_addr::kzg_verify;
    use starknet_addr::starknet_err;

    #[test_only]
    use aptos_std::aptos_hash::keccak256;

    const FIELD_ELEMENTS_PER_BLOB: u256 = 4096;

    public fun point_evaluation_precompile(bytes: vector<u8>): (vector<u8>, bool) {

        assert!(
            vector::length(&bytes) == 192,
            starknet_err::err_invalid_pre_compile_input_size()
        );

        let versioned_hash = vector::slice(&bytes, (0u64), (32u64));
        let z = vector::slice(&bytes, (32u64), (64u64));
        let y = vector::slice(&bytes, (64u64), (96u64));
        let commitment = vector::slice(&bytes, (96u64), (144u64));
        let proof = vector::slice(&bytes, (144u64), (192u64));

        vector::reverse(&mut z);
        vector::reverse(&mut y);


        // Verify commitment matches versioned_hash
        assert!(
            kzg_helper::kzg_to_versioned_hash(&commitment) == versioned_hash,
            starknet_err::err_unexpected_version_hash()
        );

        // Verify KZG proof with z and y in big-endian format (LSB format in Aptos)
        assert!(
            kzg_verify::verify_kzg_proof_impl(commitment, z, y, proof),
            starknet_err::err_invalid_kzg_commitment()
        );

        let bls_modulus = kzg_helper::get_bls_modulus();
        let output = vector::empty<u8>();
        vector::append(&mut output, bytes::num_to_bytes_be(&FIELD_ELEMENTS_PER_BLOB));
        vector::append(&mut output, bytes::num_to_bytes_be(&bls_modulus));
        return (output, true)
    }

    #[test]
    fun test_point_evaluation_precompile() {
        let input = x"010b37b597b57e4c7d3df9c81ceb00130e2cca57679e6ddae2144503c5f751a105c51420f471fd9ca7dcf11d1873ea02a50969fdd602a4d59f8257c13264ef291b6916a50314993489fa27347e781129474c58fb9fe76a970dd2dd5d05b0e1a5996396e6cd13b33a9cc52ebd69e0aadca543794a449dd39de01d0cb2c09747709afe0e5a38dc2222185dbf7eba5f50888664b3057bc3aefaf110db484fdc0c422c58209c7f8a331a4c5f853a9e37d0de5f02ec0289d7d0634e49ef813fb8e84d";
        let (output, result) = point_evaluation_precompile(input);
        assert!(
            result,
            1
        );
        assert!(
            keccak256(output) == kzg_helper::get_point_evaluation_precompile_output(),
            2
        );
    }
}