module vault::distributor_entries {
    use sui::coin::Coin;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use vault::distributor;
    use vault::distributor::Distribution;
    use shares::bucket::ShareBucket;
    use shares::registry::ShareRegistry;
    use sui::tx_context;

    public entry fun distribute<TCoin, TShare>(coin: Coin<TCoin>, ctx: &mut TxContext) {
        transfer::share_object<Distribution<TCoin, TShare>>(distributor::distribute(coin, ctx))
    }

    public entry fun claim<TCoin, TShare>(
        distribution: &mut Distribution<TCoin, TShare>,
        share_bucket: &ShareBucket<TShare>,
        registry: &ShareRegistry<TShare>,
        ctx: &mut TxContext
    ) {
        transfer::transfer(
            distributor::claim(distribution, share_bucket, registry, ctx),
            tx_context::sender(ctx)
        );
    }

    // TODO: this needs some rethinking
    public entry fun redistribute_decayed<TCoin, TShare>(
        distribution: Distribution<TCoin, TShare>,
        ctx: &mut TxContext
    ) {
        transfer::share_object(distributor::redistribute_decayed(distribution, ctx))
    }
}