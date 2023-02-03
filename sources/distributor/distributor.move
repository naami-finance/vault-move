module naami::distributor {
    use sui::coin::Coin;
    use sui::balance::Balance;
    use sui::object::UID;
    use sui::coin;
    use sui::tx_context;
    use sui::tx_context::TxContext;
    use sui::object;
    use sui::balance;
    use sui::dynamic_field;

    use naami::distributor_events;
    use naami::math_safe_precise;
    use naami::registry;
    use naami::bucket;
    use naami::bucket::ShareBucket;
    use naami::registry::ShareRegistry;

    const DecayPeriodInEpoch: u64 = 1;

    struct Distribution<phantom TCoin, phantom TShare> has key, store {
        id: UID,
        balance: Balance<TCoin>,
        timestamp: u64,

        // distribution can be claimed by governance, owner etc. if decay_period is exceeded
        decay_period: u64
    }

    public fun distribute<TCoin, TShare>(coin: Coin<TCoin>, ctx: &mut TxContext): Distribution<TCoin, TShare> {
        // this is where we are taking fees (TODO)

        let amount = coin::value(&coin);
        let distribution = Distribution {
            balance: coin::into_balance(coin),
            timestamp: tx_context::epoch(ctx),
            decay_period: tx_context::epoch(ctx) + DecayPeriodInEpoch,
            id: object::new(ctx)
        };

        distributor_events::distribution_created<TCoin, TShare>(
            amount,
            object::uid_to_inner(&distribution.id)
        );

        distribution
    }

    public fun claim<TCoin, TShare>(
        distribution: &mut Distribution<TCoin, TShare>,
        share_bucket: &ShareBucket<TShare>,
        registry: &ShareRegistry<TShare>,
        ctx: &mut TxContext
    ): Coin<TCoin> {
        let field_key = object::id_to_bytes(bucket::id(share_bucket));

        // ensure user is not trying to claim the distribution for a second time.
        let already_claimed = dynamic_field::exists_(&distribution.id, field_key);
        assert!(!already_claimed, 0);

        // ensure user is not trying to claim with a newer Bucket
        assert!(distribution.timestamp > bucket::last_modification(share_bucket), 0);

        let remaining = balance::value(&distribution.balance);
        let shares_balance = bucket::shares(share_bucket);
        let total_share_supply = registry::total_supply(registry);

        let claimable = math_safe_precise::mul_div(remaining, total_share_supply, shares_balance);
        let claimed = balance::split(&mut distribution.balance, claimable);

        // create "claimed" tag for this specific bucket
        dynamic_field::add(&mut distribution.id, field_key, tx_context::epoch(ctx));

        distributor_events::distribution_claimed(
            object::uid_to_inner(&distribution.id),
            balance::value(&distribution.balance)
        );

        coin::from_balance(claimed, ctx)
    }

    public fun redistribute_decayed<TCoin, TShare>(
        distribution: Distribution<TCoin, TShare>,
        ctx: &mut TxContext
    ): Distribution<TCoin, TShare> {
        let Distribution { balance, timestamp: _, decay_period, id } = distribution;
        assert!(decay_period < tx_context::epoch(ctx), 0);

        object::delete(id);

        distribute(coin::from_balance(balance, ctx), ctx)
    }
}