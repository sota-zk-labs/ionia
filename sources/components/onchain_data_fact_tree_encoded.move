module starknet_addr::onchain_data_fact {

    use std::bcs;
    use aptos_std::from_bcs;
    use std::vector;
    use aptos_std::aptos_hash::keccak256;

    const ONCHAIN_DATA_FACT_ADDITIONAL_WORDS: u64 = 2;

    struct DataAvailabilityFact has store, drop {
        onchain_data_hash: u256,
        onchain_data_size: u256
    }

    public fun encode_fact_with_onchain_data(
        program_output: vector<u256>,
        fact_data: DataAvailabilityFact
    ): vector<u8> {
        let main_public_input_length: u256 = (vector::length(&program_output) as u256);
        let main_public_input_hash: vector<u8> = keccak256(bcs::to_bytes(&program_output));
        let buffer = vector::empty<u8>();
        vector::append(&mut buffer, main_public_input_hash);
        vector::append(&mut buffer, bcs::to_bytes(&main_public_input_length));
        vector::append(&mut buffer, bcs::to_bytes(&fact_data.onchain_data_hash));
        vector::append(&mut buffer, bcs::to_bytes(&(main_public_input_length + fact_data.onchain_data_size)));
        let hash_result: vector<u8> = keccak256(buffer);
        let result = bcs::to_bytes(&(from_bcs::to_u256(hash_result) + 1));
        return result
    }

    public fun init_fact_data(onchain_data_hash: u256, onchain_data_size: u256): DataAvailabilityFact {
        let fact_data = DataAvailabilityFact { onchain_data_hash, onchain_data_size };
        fact_data
    }
}