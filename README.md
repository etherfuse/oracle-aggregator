# Oracle Aggregator

Example Oracle Aggregator that can be used with Blend pools. This contract allows one Blend pool to access multiple oracle prices sources from one location via `lastprice` method.

### Supported Oracles

This Oracle Aggregator contract makes a few assumptions about the oracles it can support, and was written specifically to support a small number of Reflector-like oracles:

* Oracle must have the same base asset as the aggregator (e.g. USD)
* Oracle must support SEP-40 `price(asset: Address, timestamp: u64) -> Option<PriceData>`, and it should either return the exact price at the timestamp if the `resolution` is respected, or the most recent price from that timestamp, or `None` if no relevant price exists
* Oracle must support `last_timestamp(): u64` to return the last round the oracle has reported prices for
* Oracles must support a `resolution(): u32` and `decimals(): u32` functions, and these cannot change for the life of the oracle
* Oracle must report in a reasonable amount of decimals if `max_dev` is used. At least 7 is recommended.

### Config

The oracle aggregator uses some global configuration defined through the constructor:

* admin `Address` - The admin has the ability to add additional assets to the oracle aggregator. This should be done cautiosly, as they can never be removed or edited.
* base `Asset` - The base asset the oracle aggregator will report prices in
* decimals `u32` - The decimals the oracle aggregator will report prices in
* max_age `u64` - The maximum age (in seconds) of a fetched price the oracle aggregator will return from the current ledger timestamp. This must be between 360s (6m) and 3600s (60m).

Each supported asset is defined via an AssetConfig:

**Asset Config**
* asset `Asset` - The asset to be used when fetching the price from the source oracle
* oracle_index `u32` - The index of the source oracle used
* max_dev `u32` - The maximum deviation allowed for two consecutive price updates, as a percentage with 0 decimals (e.g. 5 => 5%). If this is 0 or >=100. the oracle will just fetch the last price from the source oracle.

Up to 20 additional assets can be supported.

**Base-like Assets**

The agggregator can also support multiple base assets. These are tokens that, while they might not have a safe oracle price yet, can be redeemed 1-to-1 for the base asset. Thus, the aggregator will always report a fixed point price of `1` with `decimals` decimals.

This should be used sparingly, as it assumes a lot of trust for the issuer of the asset that it can always be redeemed 1-to-1 for the asset the oracle reports the price in.

If an additional base asset is added, it can be given an `AssetConfig` at any time by the admin.

Assets that have an `AssetConfig` cannot be set as base assets.

### Last Price Method

The aggregator attempts to fetch the price from the source oracle as defined by the internal `oracles` and the `oracle_index` within the `AssetConfig`.

1. If the `Asset` is the base asset, or is a base-like asset, a price of 1 is returned, as a fixed point number with `decimals` decimals, and the current timestamp.
2. The last round timestamp is fetched from the source oracle with `last_timestamp()`
3. If last round timestamp is older than `max_age`, `None` will be returned
4. The price for `Asset` is attempted to be fetched from the source oracle based on the last round timestamp with `price(asset, last_timestamp)`.
    *  If `None`, attempt to move back `resolution` time steps, up to or equal to `max_age` in the past, and try and fetch the price at each step. If no price found, return `None`
5. If the asset is configured to check max_dev, attempt to get the previous price using the same method as 4, but starting from the price's reported timestamp
    * If the aggregator cannot fetch a previous price within `max_age` of the price's reported timestamp or it is outside the deviation bounds, return `None`
6. If the price from 4's timestamp is within `max_age`, return `price`

## Safety

Oracle Aggregator has not had an audit conducted. If an audit is conducted, it will appear here.

Oracle Aggregator is made available under the MIT License, which disclaims all warranties in relation to the project and which limits the liability of those that contribute and maintain the project, including Script3. You acknowledge that you are solely responsible for any use of Oracle Aggregator and you assume all risks associated with any such use.

## Deployment

mise configuration for testnet

```
STELLAR_NETWORK = "testnet"
STELLAR_SOURCE = "blend-test-net"
WASM = "target/wasm32-unknown-unknown/optimized/oracle_aggregator.wasm"
ADMIN = "GBH62ESUWAJGVIDWMQTIJ4T24IWIGMYM2LGGVCBZGAZY7EYHDYMMA7HX"
BASE = '{"Other":"USD"}'
DECIMALS = 14
MAX_AGE = 600
ORACLE_ID = "CCNAFGAGXRP4RURGW6ISNTT2H7EA5HMNC6VKFHPL3Q2ALEADEMPMPZZ3"
```

mainnet

```
STELLAR_NETWORK = "mainnet"
STELLAR_SOURCE = "blend-mainnet"
WASM = "target/wasm32-unknown-unknown/optimized/oracle_aggregator.wasm"
ADMIN = "GDH3FRHOOWXYXEASH43N2VOVFOPJSVJF3EQFSLBLJYFPHOUAF4N4AETH"
BASE = '{"Other":"USD"}'
DECIMALS = 14
MAX_AGE = 600
FEE = 5000000
CONTRACT_ID = "CAVRP26CWW6IUEXBRA3Q2T2SHBUVBC2DF43M4E23LEZGW5ZEIB62HALS"
```

## Add Oracles

mainnet

```
stellar contract invoke --id $CONTRACT_ID --fee 500000 -- add_oracle --oracle_id CBWUSO5XZICR4FPKAQ4YDIYNZ2T26QMKUHWOSMPMWTXHFP3SJTAXGNCK
stellar contract invoke --id $CONTRACT_ID --fee 500000 -- add_oracle --oracle_id CAFJZQWSED6YAWZU3GWRTOCNPPCGBN32L7QV43XX5LZLFTK6JLN34DLN
```

## Add Assets

mainnet

```
# Cetes
stellar contract invoke --id $CONTRACT_ID --fee 1000000 -- add_asset --oracle_asset '{"Stellar":"CAL6ER2TI6CTRAY6BFXWNWA7WTYXUXTQCHUBCIBU5O6KM3HJFG6Z6VXV"}' --max_dev 5 --asset '{"Stellar":"CAL6ER2TI6CTRAY6BFXWNWA7WTYXUXTQCHUBCIBU5O6KM3HJFG6Z6VXV"}' --oracle_id CBWUSO5XZICR4FPKAQ4YDIYNZ2T26QMKUHWOSMPMWTXHFP3SJTAXGNCK

# USTRY
stellar contract invoke --id $CONTRACT_ID --fee 1000000 -- add_asset --oracle_asset '{"Stellar":"CBLV4ATSIWU67CFSQU2NVRKINQIKUZ2ODSZBUJTJ43VJVRSBTZYOPNUR"}' --max_dev 5 --asset '{"Stellar":"CBLV4ATSIWU67CFSQU2NVRKINQIKUZ2ODSZBUJTJ43VJVRSBTZYOPNUR"}' --oracle_id CBWUSO5XZICR4FPKAQ4YDIYNZ2T26QMKUHWOSMPMWTXHFP3SJTAXGNCK

# TESOURO
stellar contract invoke --id $CONTRACT_ID --fee 1000000 -- add_asset --oracle_asset '{"Stellar":"CD6M4R2322BYCY2LNWM74PEBQAQ63SA3DUJLI3L4225U4ZVCLMSCBCIS"}' --max_dev 5 --asset '{"Stellar":"CD6M4R2322BYCY2LNWM74PEBQAQ63SA3DUJLI3L4225U4ZVCLMSCBCIS"}' --oracle_id CBWUSO5XZICR4FPKAQ4YDIYNZ2T26QMKUHWOSMPMWTXHFP3SJTAXGNCK

# USDC
stellar contract invoke --id $CONTRACT_ID --fee 1000000 -- add_asset --oracle_asset '{"Other":"USDC"}' --max_dev 5 --asset '{"Stellar":"CCW67TSZV3SSS2HXMBQ5JFGCKJNXKZM7UQUWUZPUTHXSTZLEO7SJMI75"}' --oracle_id CAFJZQWSED6YAWZU3GWRTOCNPPCGBN32L7QV43XX5LZLFTK6JLN34DLN

# XLM
stellar contract invoke --id $CONTRACT_ID --fee 1000000 -- add_asset --oracle_asset '{"Other":"XLM"}' --max_dev 10 --asset '{"Stellar":"CAS3J7GYLGXMF6TDJBBYYSE3HQ6BBSMLNUQ34T6TZMYMW2EVH34XOWMA"}' --oracle_id CAFJZQWSED6YAWZU3GWRTOCNPPCGBN32L7QV43XX5LZLFTK6JLN34DLN
```