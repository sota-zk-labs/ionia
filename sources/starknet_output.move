module starknet_addr::commitment_tree_update_output {
    use std::vector;

    public fun get_prev_root(commitment_tree_update_data: vector<u256>): u256 {
        *vector::borrow(&commitment_tree_update_data, 0)
    }

    public fun get_new_root(commitment_tree_update_data: vector<u256>): u256 {
        *vector::borrow(&commitment_tree_update_data, 1)
    }
}