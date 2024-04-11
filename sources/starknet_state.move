module starknet_addr::starket_state {

    use std::vector;
    use starknet_addr::commitment_tree_update_output;
    use starknet_addr::starknet_err;
    use starknet_addr::starknet_output;

    struct State has copy, drop, store {
        global_root: u256,
        block_number: u256,
        block_hash: u256,
    }

    public fun new(global_root: u256, block_number: u256, block_hash: u256): State {
        return State {
            global_root,
            block_number,
            block_hash,
        }
    }

    public fun set_global_root(state: &mut State, global_root: u256) {
        state.global_root = global_root;
    }

    public fun set_block_number(state: &mut State, block_number: u256) {
        state.block_number = block_number;
    }

    public fun set_block_hash(state: &mut State, block_hash: u256) {
        state.block_hash = block_hash;
    }

    public fun get_global_root(state: State): u256 {
        return state.global_root
    }

    public fun get_block_number(state: State): u256 {
        return state.block_number
    }

    public fun get_block_hash(state: State): u256 {
        return state.block_hash
    }

    public fun update(state: &mut State, starknet_output: vector<u256>) {
        state.block_number = state.block_number + 1;
        assert!(
            state.block_number == *vector::borrow(&starknet_output, starknet_output::get_block_number_offset()),
            starknet_err::err_invalid_block_number()
        );

        state.block_hash = *vector::borrow(&starknet_output, starknet_output::get_block_hash_offset());

        let commitment_tree_update = starknet_output::get_merkle_update(starknet_output);
        assert!(
            state.global_root == commitment_tree_update_output::get_prev_root(commitment_tree_update),
            starknet_err::err_invalid_prev_root()
        );
        state.global_root = commitment_tree_update_output::get_new_root(commitment_tree_update);
    }

    #[test]
    fun update_state() {
        let state = State {
            global_root: 0,
            block_number: 0,
            block_hash: 0,
        };

        assert!(get_global_root(state) == 0, 0x1);
        assert!(get_block_number(state) == 0, 0x1);
        assert!(get_block_hash(state) == 0, 0x1);

        update(&mut state, vector[0x0000, 0xFFFF, 1, 0x1111]);

        assert!(get_global_root(state) == 0xFFFF, 0x2);
        assert!(get_block_number(state) == 1, 0x2);
        assert!(get_block_hash(state) == 0x1111, 0x2);
    }

    #[test]
    fun set_state() {
        let state = State {
            global_root: 0,
            block_number: 0,
            block_hash: 0,
        };

        assert!(get_global_root(state) == 0, 1);
        assert!(get_block_number(state) == 0, 1);
        assert!(get_block_hash(state) == 0, 1);

        set_global_root(&mut state, 1);
        set_block_number(&mut state, 2);
        set_block_hash(&mut state, 3);

        assert!(get_global_root(state) == 1, 2);
        assert!(get_block_number(state) == 2, 2);
        assert!(get_block_hash(state) == 3, 2);
    }
}