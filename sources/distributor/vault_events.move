module naami::vault_events {
    use sui::object::ID;
    use sui::event;

    friend naami::vault;

    struct VaultCreated<phantom TCoin, phantom TShare> has copy, drop {
        id: ID
    }

    public(friend) fun vault_created<TCoin, TShare>(id: ID) {
        event::emit(VaultCreated<TCoin, TShare> {
            id
        });
    }

    struct CoinDeposited has copy, drop {
        vault_id: ID,
        amount: u64,
        new_vault_amount: u64
    }

    public(friend) fun coin_deposited(vault_id: ID, amount: u64, new_vault_amount: u64) {
        event::emit(CoinDeposited {
            vault_id,
            amount,
            new_vault_amount
        });
    }
}