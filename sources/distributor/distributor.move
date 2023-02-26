module vault::distributor {
    use sui::coin::Coin;
    use sui::balance::Balance;
    use sui::object::UID;
    use sui::coin;
    use sui::tx_context;
    use sui::tx_context::TxContext;
    use sui::object;
    use sui::balance;
    use sui::dynamic_field;

    use vault::distributor_events;
    use vault::math_safe_precise;
    use shares::registry;
    use shares::bucket;
    use shares::bucket::ShareBucket;
    use shares::registry::ShareRegistry;

    // a distribution becomes decayed after a while and can be re-distributed
    const DecayPeriodInEpoch: u64 = 100;

    // a distribution can be merged with another one from the same epoch during this timespan
    const MergingPhaseEpochDuration: u64 = 10;

    struct Distribution<phantom TCoin, phantom TShare> has key, store {
        id: UID,
        initial_balance: u64,
        remaining_balance: Balance<TCoin>,
        timestamp: u64,
    }

    public fun distribute<TCoin, TShare>(coin: Coin<TCoin>, ctx: &mut TxContext): Distribution<TCoin, TShare> {
        let amount = coin::value(&coin);
        let current_epoch = tx_context::epoch(ctx);

        let distribution = Distribution {
            initial_balance: coin::value(&coin),
            remaining_balance: coin::into_balance(coin),
            timestamp: current_epoch,
            id: object::new(ctx)
        };

        distributor_events::distribution_created<TCoin, TShare>(
            amount,
            object::uid_to_inner(&distribution.id),
            distribution.timestamp
        );

        distribution
    }

    public fun claim<TCoin, TShare>(
        distribution: &mut Distribution<TCoin, TShare>,
        share_bucket: &ShareBucket<TShare>,
        registry: &ShareRegistry<TShare>,
        ctx: &mut TxContext
    ): Coin<TCoin> {
        // ensure distribution is outisde of the merging phase
        let current_epoch = tx_context::epoch(ctx);
        assert!(current_epoch > distribution.timestamp + MergingPhaseEpochDuration, 1234);

        let field_key = object::id_to_bytes(&bucket::id(share_bucket));

        // ensure user is not trying to claim the distribution for a second time.
        let already_claimed = dynamic_field::exists_(&distribution.id, field_key);
        assert!(!already_claimed, 0);

        // (TODO: add merging period) ensure user is not trying to claim with a newer Bucket
        assert!(distribution.timestamp > bucket::last_modification(share_bucket), 0);

        let initial_distribution_balance = distribution.initial_balance;
        let shares_balance = bucket::shares(share_bucket);
        let total_share_supply = registry::total_supply(registry);

        let claimable = math_safe_precise::mul_div(initial_distribution_balance, total_share_supply, shares_balance);
        let claimed = balance::split(&mut distribution.remaining_balance, claimable);

        // create "claimed" tag for this specific bucket
        dynamic_field::add(&mut distribution.id, field_key, current_epoch);

        distributor_events::distribution_claimed(
            object::uid_to_inner(&distribution.id),
            balance::value(&distribution.remaining_balance),
            bucket::id(share_bucket)
        );

        coin::from_balance(claimed, ctx)
    }

    public fun redistribute_decayed<TCoin, TShare>(
        distribution: Distribution<TCoin, TShare>,
        ctx: &mut TxContext
    ): Distribution<TCoin, TShare> {
        let Distribution { remaining_balance, initial_balance: _, timestamp, id } = distribution;
        assert!(timestamp + DecayPeriodInEpoch < tx_context::epoch(ctx), 0);

        object::delete(id);

        distribute(coin::from_balance(remaining_balance, ctx), ctx)
    }
}