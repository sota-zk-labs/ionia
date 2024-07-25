module starknet_addr::kzg {

    use std::vector;
    use aptos_std::bls12381_algebra::{G2, G1, Gt, Fr};
    use aptos_std::crypto_algebra;
    use aptos_std::crypto_algebra::Element;
    use aptos_std::from_bcs;
    use starknet_addr::bls;
    use starknet_addr::trusted_setup;
    use starknet_addr::starknet_err;

    const BYTES_PER_COMMITMENT: u64 = 48;
    const BYTES_PER_FIELD_ELEMENT: u64 = 32;
    const BYTES_PER_PROOF: u64 = 48;

    public fun verify_kzg_proof(
        commitment_bytes: vector<u8>,
        z: vector<u8>,
        y: vector<u8>,
        proof_bytes: vector<u8>,
    ): bool {
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

        let bls_modulus = bls::get_bls_modulus();
        let fr_g2 = crypto_algebra::from_u64<Fr>(((bls_modulus - from_bcs::to_u256(z)) % bls_modulus as u64));
        let fr_g1 = crypto_algebra::from_u64<Fr>(((bls_modulus - from_bcs::to_u256(y)) % bls_modulus as u64));

        let x_minus_z: Element<G2> = crypto_algebra::add<G2>(
            &bls::bytes_to_G2(trusted_setup::get_g2_point(1)),
            &crypto_algebra::scalar_mul<G2, Fr>(&bls::g2(), &fr_g2)
        );

        let p_minus_y: Element<G1> = crypto_algebra::add(
            &bls::bytes_to_G1(commitment_bytes),
            &crypto_algebra::scalar_mul<G1, Fr>(&bls::g1(), &fr_g1)
        );

        let lhs = crypto_algebra::pairing<G1, G2, Gt>(
            &p_minus_y,
            &crypto_algebra::neg(&bls::g2())
        );

        let rhs = crypto_algebra::pairing<G1, G2, Gt>(
            &bls::bytes_to_G1(proof_bytes),
            &x_minus_z
        );

        return crypto_algebra::eq<Gt>(&lhs, &rhs)
    }
}
