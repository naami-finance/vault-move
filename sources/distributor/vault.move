module naami::vault {
    use sui::object::UID;
    use sui::coin::Coin;
    use sui::balance::Balance;
    use sui::balance;
    use sui::coin;
    use sui::tx_context::{TxContext};
    use sui::object;

    use naami::vault_events;
    use naami::distributor::{Distribution, Self};

    friend naami::vault_registry;

    struct Vault<phantom TCoin, phantom TShare> has key, store {
        id: UID,
        balance: Balance<TCoin>
    }

    public(friend) fun create<TCoin, TShare>(ctx: &mut TxContext): Vault<TCoin, TShare> {
        let id = object::new(ctx);

        vault_events::vault_created<TCoin, TShare>(object::uid_to_inner(&id));

        Vault {
            id,
            balance: balance::zero<TCoin>()
        }
    }

    // deposit { coin } into vault for a later distribution
    public fun deposit<TCoin, TShare>(vault: &mut Vault<TCoin, TShare>, coin: Coin<TCoin>) {
        let coin_balance = coin::value(&coin);
        vault_events::coin_deposited(
            object::uid_to_inner(&vault.id),
            coin_balance,
            balance::join(&mut vault.balance, coin::into_balance(coin))
        );
    }

    // take { amount } from the vault and create a distribution object
    public fun distribute<TCoin, TShare>(
        vault: &mut Vault<TCoin, TShare>,
        amount: u64,
        ctx: &mut TxContext
    ): Distribution<TCoin, TShare> {
        distributor::distribute(
            coin::from_balance(
                balance::split(&mut vault.balance, amount),
                ctx
            ), ctx
        )
    }
}