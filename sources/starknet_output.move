module starknet_addr::commitment_tree_update_output {
    use std::vector;

    public fun get_prev_root(commitment_tree_update_data: vector<u256>): u256 {
        *vector::borrow(&commitment_tree_update_data, 0)
    }

    public fun get_new_root(commitment_tree_update_data: vector<u256>): u256 {
        *vector::borrow(&commitment_tree_update_data, 1)
    }
}

module starknet_addr::starknet_output {

    use std::vector;
    use starknet_addr::starknet_err;

    const MERKLE_UPDATE_OFFSET: u64 = 0;
    const BLOCK_NUMBER_OFFSET: u64 = 2;
    const BLOCK_HASH_OFFSET: u64 = 3;
    const CONFIG_HASH_OFFSET: u64 = 4;
    const HEADER_SIZE: u64 = 5;

    const MESSAGE_TO_L1_FROM_ADDRESS_OFFSET: u64 = 0;
    const MESSAGE_TO_L1_TO_ADDRESS_OFFSET: u64 = 1;
    const MESSAGE_TO_L1_PAYLOAD_SIZE_OFFSET: u64 = 2;
    const MESSAGE_TO_L1_PREFIX_SIZE: u64 = 3;

    const MESSAGE_TO_L2_FROM_ADDRESS_OFFSET: u64 = 0;
    const MESSAGE_TO_L2_TO_ADDRESS_OFFSET: u64 = 1;
    const MESSAGE_TO_L2_NONCE_OFFSET: u64 = 2;
    const MESSAGE_TO_L2_SELECTOR_OFFSET: u64 = 3;
    const MESSAGE_TO_L2_PAYLOAD_SIZE_OFFSET: u64 = 4;
    const MESSAGE_TO_L2_PREFIX_SIZE: u64 = 5;

    public fun get_merkle_update_offset(): u64 {
        return MERKLE_UPDATE_OFFSET
    }

    public fun get_block_number_offset(): u64 {
        return BLOCK_NUMBER_OFFSET
    }

    public fun get_block_hash_offset(): u64 {
        return BLOCK_HASH_OFFSET
    }

    public fun get_config_hash_offset(): u64 {
        return CONFIG_HASH_OFFSET
    }

    public fun get_header_size(): u64 {
        return HEADER_SIZE
    }

    public fun get_message_to_l1_from_address_offset(): u64 {
        return MESSAGE_TO_L1_FROM_ADDRESS_OFFSET
    }

    public fun get_message_to_l1_to_address_offset(): u64 {
        return MESSAGE_TO_L1_TO_ADDRESS_OFFSET
    }

    public fun get_message_to_l1_payload_size_offset(): u64 {
        return MESSAGE_TO_L1_PAYLOAD_SIZE_OFFSET
    }

    public fun get_message_to_l1_prefix_size(): u64 {
        return MESSAGE_TO_L1_PREFIX_SIZE
    }

    public fun get_message_to_l2_from_address_offset(): u64 {
        return MESSAGE_TO_L2_FROM_ADDRESS_OFFSET
    }

    public fun get_message_to_l2_to_address_offset(): u64 {
        return MESSAGE_TO_L2_TO_ADDRESS_OFFSET
    }

    public fun get_message_to_l2_nonce_offset(): u64 {
        return MESSAGE_TO_L2_NONCE_OFFSET
    }

    public fun get_message_to_l2_selector_offset(): u64 {
        return MESSAGE_TO_L2_SELECTOR_OFFSET
    }

    public fun get_message_to_l2_payload_size_offset(): u64 {
        return MESSAGE_TO_L2_PAYLOAD_SIZE_OFFSET
    }

    public fun get_message_to_l2_prefix_size(): u64 {
        return MESSAGE_TO_L2_PREFIX_SIZE
    }

    public fun validate(output_data: vector<u256>) {
        assert!(vector::length(&output_data) >= HEADER_SIZE, starknet_err::err_starknet_output_too_short())
    }

    public fun get_merkle_update(output_data: vector<u256>): vector<u256> {
        return vector::slice(&output_data, MERKLE_UPDATE_OFFSET, MERKLE_UPDATE_OFFSET + 2)
    }

}