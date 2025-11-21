default: build

test: build
	cargo test --all --tests

build:
	mkdir -p target/wasm32-unknown-unknown/optimized
	cargo rustc --manifest-path=Cargo.toml --crate-type=cdylib --target=wasm32-unknown-unknown --release
	stellar contract optimize \
		--wasm target/wasm32-unknown-unknown/release/oracle_aggregator.wasm \
		--wasm-out target/wasm32-unknown-unknown/optimized/oracle_aggregator.wasm

deploy: build
	stellar contract deploy --network $$STELLAR_NETWORK --source $$STELLAR_SOURCE --wasm $$WASM --fee $$FEE -- --admin $$ADMIN --base $$BASE --decimals $$DECIMALS --max-age $$MAX_AGE
	
