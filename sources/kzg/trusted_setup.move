module starknet_addr::trusted_setup {
    // This is the trusted setup for the KZG commitment. It is not generated from the Aptos core
    // but is loaded from an external source. The logic of the trusted setup is referenced from the following repo:
    // https://github.com/sota-zk-labs/zkp-implementation/tree/main/kzg

    use aptos_std::bls12381_algebra::{FormatG1Compr, FormatG2Compr, G1, G2};
    use aptos_std::crypto_algebra::{deserialize, Element};

    const G2_SETUP: vector<u8> = x"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8";
    const G2S_SETUP: vector<u8> = x"b5bfd7dd8cdeb128843bc287230af38926187075cbfbefa81009a2ce615ac53d2914e5870cb452d2afaaab24f3499f72185cbfee53492714734429b7b38608e23926c911cceceac9a36851477ba4c60b087041de621000edc98edada20c1def2";
    const G1_GENERATOR: vector<u8> = x"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb";

    public fun get_g2s(): Element<G2> {
        std::option::extract(&mut deserialize<G2, FormatG2Compr>(&G2S_SETUP))
    }

    public fun get_g2(): Element<G2> {
        std::option::extract(&mut deserialize<G2, FormatG2Compr>(&G2_SETUP))
    }

    public fun get_g1_generator(): Element<G1> {
        std::option::extract(&mut deserialize<G1, FormatG1Compr>(&G1_GENERATOR))
    }
}