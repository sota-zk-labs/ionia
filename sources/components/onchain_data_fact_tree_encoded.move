module starknet_addr::onchain_data_fact_tree_encoded {
    use std::bcs::to_bytes;
    use std::vector;
    use aptos_std::aptos_hash::keccak256;

    use starknet_addr::bytes;

    struct DataAvailabilityFact has store, drop {
        onchain_data_hash: u256,
        onchain_data_size: u256
    }

    public fun encode_fact_with_onchain_data(
        program_output: &vector<u256>,
        fact_data: DataAvailabilityFact
    ): vector<u8> {
        let main_public_input_length: u256 = (vector::length(program_output) as u256);
        let main_public_input_hash: vector<u8> = keccak256(bytes::vec_to_bytes_be(program_output));
        vector::reverse_append(&mut main_public_input_hash, to_bytes(&main_public_input_length));
        vector::append(&mut main_public_input_hash, bytes::num_to_bytes_be(&fact_data.onchain_data_hash));
        vector::append(
            &mut main_public_input_hash,
            bytes::num_to_bytes_be(&(main_public_input_length + fact_data.onchain_data_size))
        );
        let hash_result: vector<u8> = keccak256(main_public_input_hash);
        let result = bytes::num_to_bytes_be(&(bytes::u256_from_bytes_be(&hash_result) + 1));
        return result
    }

    public fun new(onchain_data_hash: u256, onchain_data_size: u256): DataAvailabilityFact {
        let fact_data = DataAvailabilityFact { onchain_data_hash, onchain_data_size };
        fact_data
    }

    #[test]
    fun test_encode_fact_with_onchain_data() {
        let fact_data = new(
            4643044994485936859054407373370718990191010183076115682089501129170u256,
            17360712499668091053135558285859368683200285152058604480060410253312987758592u256,
        );

        let program_output: vector<u256> = vector[
            1970272326382990453316397420342340810466901058626735958618873840050980391150,
            3458474516901043875685413386881507261498565942069144376940366111442758962633,
            608891,
            492947369139090042378802255177414102958465992946764632218968988097869936180,
            2590421891839256512113614983194993186457498815986333310670788206383913888162,
            0,
            0,
            0
        ];

        let state_transition_fact = encode_fact_with_onchain_data(&program_output, fact_data);
        assert!(
            state_transition_fact == x"9cf790b74003cb773e64dac3fb45f3669c766972eb601d47e331c5ad25fd8e20",
            1
        );
    }
}