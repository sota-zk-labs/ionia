// TODO: Add Navori as a dependency
module starknet_addr::fact_registry {

    use aptos_std::smart_table;
    use aptos_std::smart_table::{ SmartTable, borrow, upsert, new };

    struct VerifierFact has key, store {
        verified_fact: SmartTable<vector<u8>, bool>,
        any_fact_registered: bool
    }

    fun init_fact_registry(s: &signer) {
        move_to(s, VerifierFact {
            verified_fact: new<vector<u8>, bool>(),
            any_fact_registered: false
        });
    }

    #[view]
    public fun is_valid(fact: vector<u8>): bool acquires VerifierFact {
        let verifier_fact = borrow_global<VerifierFact>(@starknet_addr);
        *smart_table::borrow_with_default(&verifier_fact.verified_fact, fact, &false)
    }

    #[view]
    public fun fast_check(fact: vector<u8>): bool acquires VerifierFact {
        *borrow(&borrow_global<VerifierFact>(@starknet_addr).verified_fact, fact)
    }

    public entry fun register_fact(signer: &signer, fact_hash: vector<u8>) acquires VerifierFact {
        if (exists<VerifierFact>(@starknet_addr) == false) {
            init_fact_registry(signer);
        };
        let verifier_fact = borrow_global_mut<VerifierFact>(@starknet_addr);
        upsert(&mut verifier_fact.verified_fact, fact_hash, true);

        if (verifier_fact.any_fact_registered == false) {
            verifier_fact.any_fact_registered = true;
        }
    }

    fun has_registered_fact(): bool acquires VerifierFact {
        borrow_global<VerifierFact>(@starknet_addr).any_fact_registered
    }
}