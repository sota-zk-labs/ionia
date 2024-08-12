module starknet_addr::kzg_verify {
    // This line is used for generating constants DO NOT REMOVE!
    // 48
    const BYTES_PER_COMMITMENT: u64 = 0x30;
    // 32
    const BYTES_PER_FIELD_ELEMENT: u64 = 0x20;
    // 48
    const BYTES_PER_PROOF: u64 = 0x30;
    // 327687
    const EINVALID_KZG_COMMITMENT_SIZE: u64 = 0x50007;
    // 327683
    const EINVALID_KZG_PROOF_SIZE: u64 = 0x50003;
    // 327686
    const EINVALID_Y_VALUE: u64 = 0x50006;
    // 327688
    const EINVALID_Z_VALUE: u64 = 0x50008;
    // G1 Generator
    const G1_GENERATOR: vector<u8> = x"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb";
    // G2 secret
    const G2S_SETUP: vector<u8> = x"b5bfd7dd8cdeb128843bc287230af38926187075cbfbefa81009a2ce615ac53d2914e5870cb452d2afaaab24f3499f72185cbfee53492714734429b7b38608e23926c911cceceac9a36851477ba4c60b087041de621000edc98edada20c1def2";
    // G2 generator
    const G2_GENERATOR: vector<u8> = x"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8";
    // End of generating constants!

    use std::vector;
    use aptos_std::bls12381_algebra::{FormatFrLsb, FormatG1Compr, Fr, G1, G2, Gt, FormatG2Compr};
    use aptos_std::crypto_algebra::{deserialize, eq, pairing, scalar_mul, sub};

    public fun verify_kzg_proof(
        commitment_bytes: vector<u8>,
        z: vector<u8>,
        y: vector<u8>,
        proof_bytes: vector<u8>,
    ): bool {
        assert!(
            vector::length(&commitment_bytes) == BYTES_PER_COMMITMENT,
            EINVALID_KZG_COMMITMENT_SIZE
        );
        assert!(
            vector::length(&proof_bytes) == BYTES_PER_PROOF,
            EINVALID_KZG_PROOF_SIZE
        );
        assert!(
            vector::length(&z) == BYTES_PER_FIELD_ELEMENT,
            EINVALID_Y_VALUE
        );
        assert!(
            vector::length(&y) == BYTES_PER_FIELD_ELEMENT,
            EINVALID_Z_VALUE
        );

        let field_z = std::option::extract(&mut deserialize<Fr, FormatFrLsb>(&z));
        let field_y = std::option::extract(&mut deserialize<Fr, FormatFrLsb>(&y));
        let field_commitment = std::option::extract(&mut deserialize<G1, FormatG1Compr>(&commitment_bytes));
        let field_proof = std::option::extract(&mut deserialize<G1, FormatG1Compr>(&proof_bytes));

        let g2s = std::option::extract(&mut deserialize<G2, FormatG2Compr>(&G2S_SETUP));
        let g2 = std::option::extract(&mut deserialize<G2, FormatG2Compr>(&G2_GENERATOR));
        let g1 = std::option::extract(&mut deserialize<G1, FormatG1Compr>(&G1_GENERATOR));

        let a = sub<G2>(&g2s, &scalar_mul<G2, Fr>(&g2, &field_z));
        let b = sub<G1>(&field_commitment, &scalar_mul<G1, Fr>(&g1, &field_y));

        let lhs = pairing<G1, G2, Gt>(&field_proof, &a);
        let rhs = pairing<G1, G2, Gt>(&b, &g2);

        eq(&lhs, &rhs)
    }

    #[test]
    fun test_verify_incorrect_kzg_proof() {
        let comitment = x"b28ff7af1552ad83a1abf352c3a6bba86511c69d495cdfd7fc81681767c5b516f477436efffbd1ae2a31eb1dbbe5c291";
        let z_bytes = x"0500000000000000000000000000000000000000000000000000000000000000";
        let y_bytes = x"5100000000000000000000000000000000000000000000000000000000000000";
        let proof = x"85d5c5ddc49c8b44bace634bed4dd1c2f3ddc5982b459f702a7756e8896b8f29ae5db9c933ccbb9241af9c01587f3896";

        assert!(
            !verify_kzg_proof(comitment, z_bytes, y_bytes, proof),
            1
        );
    }

    #[test]
    fun test_verify_kzg_proof() {
        let commitment = x"996396e6cd13b33a9cc52ebd69e0aadca543794a449dd39de01d0cb2c09747709afe0e5a38dc2222185dbf7eba5f5088";
        let proof = x"8664b3057bc3aefaf110db484fdc0c422c58209c7f8a331a4c5f853a9e37d0de5f02ec0289d7d0634e49ef813fb8e84d";
        let z = x"29ef6432c157829fd5a402d6fd6909a502ea73181df1dca79cfd71f42014c505";
        let y = x"a5e1b0055dddd20d976ae79ffb584c472911787e3427fa8934991403a516691b";
        assert!(
            verify_kzg_proof(commitment, z, y, proof),
            1
        );
    }
}
