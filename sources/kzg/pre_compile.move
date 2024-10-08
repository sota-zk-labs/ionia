module starknet_addr::pre_compile {
    // This line is used for generating constants DO NOT REMOVE!
    // 52435875175126190479447740508185965837690552500527637822603658699938581184513
    const BLS_MODULUS: u256 = 52435875175126190479447740508185965837690552500527637822603658699938581184513;
    // 0x50005
    const EINVALID_KZG_COMMITMENT: u64 = 0x50005;
    // 0x50004
    const EINVALID_PRE_COMPILE_INPUT_SIZE: u64 = 0x50004;
    // 0x70002
    const EUNEXPECTED_VERSION_HASH: u64 = 0x70002;
    // 4096
    const FIELD_ELEMENTS_PER_BLOB: u256 = 0x1000;
    // b2157d3a40131b14c4c675335465dffde802f0ce5218ad012284d7f275d1b37c
    const POINT_EVALUATION_PRECOMPILE_OUTPUT: vector<u8> = x"b2157d3a40131b14c4c675335465dffde802f0ce5218ad012284d7f275d1b37c";
    // End of generating constants!

    use std::vector;

    use starknet_addr::bytes;
    use starknet_addr::kzg_helper;
    use starknet_addr::kzg_verify;

    #[test_only]
    use aptos_std::aptos_hash::keccak256;

    public fun point_evaluation_precompile(bytes: vector<u8>): (vector<u8>, bool) {
        assert!(
            vector::length(&bytes) == 192,
            EINVALID_PRE_COMPILE_INPUT_SIZE
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
            EUNEXPECTED_VERSION_HASH
        );
        // Verify KZG proof with z and y in big-endian format (LSB format in Aptos)
        assert!(
            kzg_verify::verify_kzg_proof_impl(commitment, z, y, proof),
            EINVALID_KZG_COMMITMENT
        );

        let bls_modulus = BLS_MODULUS;
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
            keccak256(output) == POINT_EVALUATION_PRECOMPILE_OUTPUT,
            2
        );
    }
}