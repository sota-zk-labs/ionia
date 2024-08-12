module starknet_addr::named_storage {

    use aptos_std::table;
    use aptos_std::table::Table;
    use starknet_addr::starknet_err;

    struct Table_Storage has store, key {
        bytes_to_u256: Table<vector<u8>, u256>,
        bytes_to_addr: Table<vector<u8>, address>,
        u256_to_addr: Table<u256, address>,
        addr_to_bool: Table<address, bool>,
    }

    struct Storage<phantom T: copy + drop + store> has store, key {
        handle: Table<vector<u8>, T>,
    }

    public fun init_table_storage(s: &signer) {
        move_to(s, Table_Storage {
            bytes_to_u256: table::new<vector<u8>, u256>(),
            bytes_to_addr: table::new<vector<u8>, address>(),
            u256_to_addr: table::new<u256, address>(),
            addr_to_bool: table::new<address, bool>(),
        });
    }

    public fun init_storage<T: copy + store + drop>(s: &signer) {
        move_to(s, Storage {
            handle: table::new<vector<u8>, T>(),
        })
    }

    public fun get_value<T: copy + drop + store>(tag: vector<u8>): T acquires Storage {
        let storage = borrow_global_mut<Storage<T>>(@starknet_addr);
        *table::borrow(&storage.handle, tag)
    }

    public fun set_value<T: copy + drop + store>(tag: vector<u8>, value: T) acquires Storage {
        let storage = borrow_global_mut<Storage<T>>(@starknet_addr);
        table::upsert(&mut storage.handle, tag, value);
    }

    public fun set_exclusive_value<T: copy + drop + store>(tag: vector<u8>, value: T) acquires Storage {
        let storage = borrow_global_mut<Storage<T>>(@starknet_addr);
        assert!(table::contains(&mut storage.handle, tag), starknet_err::err_named_storage_already_set());
        table::add(&mut storage.handle, tag, value);
    }
}