module vault::aggregator {
    use sui::object::UID;
    use sui::coin::Coin;
    use sui::balance::Balance;
    use sui::balance;
    use sui::coin;
    use sui::tx_context::{TxContext};
    use sui::object;

    use vault::aggregator_events;
    use vault::distributor::{Distribution, Self};

    friend vault::safe;

    struct Aggregator<phantom TCoin, phantom TShare> has key, store {
        id: UID,
        balance: Balance<TCoin>
    }

    public(friend) fun create<TCoin, TShare>(balance: Balance<TCoin>, ctx: &mut TxContext): Aggregator<TCoin, TShare> {
        let id = object::new(ctx);

        aggregator_events::aggregator_created<TCoin, TShare>(object::uid_to_inner(&id));

        Aggregator {
            id,
            balance
        }
    }

    // deposit { coin } into vault for a later distribution
    public fun deposit<TCoin, TShare>(aggregator: &mut Aggregator<TCoin, TShare>, coin: Coin<TCoin>) {
        let coin_balance = coin::value(&coin);
        aggregator_events::coin_deposited(
            object::uid_to_inner(&aggregator.id),
            coin_balance,
            balance::join(&mut aggregator.balance, coin::into_balance(coin))
        );
    }

    // take { amount } from the vault and create a distribution object
    public fun distribute<TCoin, TShare>(
        aggregator: &mut Aggregator<TCoin, TShare>,
        amount: u64,
        ctx: &mut TxContext
    ): Distribution<TCoin, TShare> {
        distributor::distribute(
            coin::from_balance(
                balance::split(&mut aggregator.balance, amount),
                ctx
            ), ctx
        )
    }
}