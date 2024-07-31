module starknet_addr::kzg {
    use std::vector;
    use aptos_std::bls12381_algebra::{FormatFrLsb, FormatG1Compr, Fr, G1, G2, Gt};
    use aptos_std::crypto_algebra::{deserialize, eq, pairing, scalar_mul, sub};
    use aptos_framework::event::emit;

    use starknet_addr::starknet_err;
    use starknet_addr::trusted_setup;

    const BYTES_PER_COMMITMENT: u64 = 48;
    const BYTES_PER_FIELD_ELEMENT: u64 = 32;
    const BYTES_PER_PROOF: u64 = 48;

    #[event]
    struct KZGProofVerification has store, drop {
        success: bool,
    }

    public entry fun verify_kzg_proof(
        commitment_bytes: vector<u8>,
        z: vector<u8>,
        y: vector<u8>,
        proof_bytes: vector<u8>,
    ) {
        assert!(
            vector::length(&commitment_bytes) == BYTES_PER_COMMITMENT,
            starknet_err::err_invalid_kzg_commitment()
        );
        assert!(
            vector::length(&proof_bytes) == BYTES_PER_PROOF,
            starknet_err::err_invalid_kzg_proof_size()
        );
        assert!(
            // Return error invalid field element
            vector::length(&z) == BYTES_PER_FIELD_ELEMENT,
            starknet_err::err_invalid_y_value()
        );
        assert!(
            // Return error invalid field element
            vector::length(&y) == BYTES_PER_FIELD_ELEMENT,
            starknet_err::err_invalid_y_value()
        );

        let field_z = std::option::extract(&mut deserialize<Fr, FormatFrLsb>(&z));
        let field_y = std::option::extract(&mut deserialize<Fr, FormatFrLsb>(&y));
        let field_commitment = std::option::extract(&mut deserialize<G1, FormatG1Compr>(&commitment_bytes));
        let field_proof = std::option::extract(&mut deserialize<G1, FormatG1Compr>(&proof_bytes));

        let g2s = trusted_setup::get_g2s();
        let g2 = trusted_setup::get_g2();
        let a = sub<G2>(&g2s, &scalar_mul<G2, Fr>(&g2, &field_z));
        let b = sub<G1>(&field_commitment, &scalar_mul<G1, Fr>(&trusted_setup::get_g1_generator(), &field_y));

        let lhs = pairing<G1, G2, Gt>(&field_proof, &a);
        let rhs = pairing<G1, G2, Gt>(&b, &g2);
        emit<KZGProofVerification>(KZGProofVerification {
            success: eq(&lhs, &rhs)
        });
    }

    #[test]
    fun test_verify_kzg_proof() {
        let comitment = x"b28ff7af1552ad83a1abf352c3a6bba86511c69d495cdfd7fc81681767c5b516f477436efffbd1ae2a31eb1dbbe5c291";
        let z_bytes = x"0400000000000000000000000000000000000000000000000000000000000000";
        let y_bytes = x"5100000000000000000000000000000000000000000000000000000000000000";
        let proof = x"85d5c5ddc49c8b44bace634bed4dd1c2f3ddc5982b459f702a7756e8896b8f29ae5db9c933ccbb9241af9c01587f3896";
        assert!(
            verify_kzg_proof(comitment, z_bytes, y_bytes, proof),
            1
        );
    }

    #[test]
    fun test_incorrect_kzg_proof() {
        let comitment = x"b28ff7af1552ad83a1abf352c3a6bba86511c69d495cdfd7fc81681767c5b516f477436efffbd1ae2a31eb1dbbe5c291";
        let z_bytes = x"0500000000000000000000000000000000000000000000000000000000000000";
        let y_bytes = x"5100000000000000000000000000000000000000000000000000000000000000";
        let proof = x"85d5c5ddc49c8b44bace634bed4dd1c2f3ddc5982b459f702a7756e8896b8f29ae5db9c933ccbb9241af9c01587f3896";

        assert!(
            !verify_kzg_proof(comitment, z_bytes, y_bytes, proof),
            1
        );
    }
}
