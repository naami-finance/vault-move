todos (sequential);

move:
- create sharebucket metadata struct, so that people can add additional information (similiar to CoinMetadata)
- create events so that we can index ShareBucket<T>

.net:
- build indexing logic for ShareBucket and ShareRegistry
  -> First iteration: Index only Type + Metadata
- -> SQL