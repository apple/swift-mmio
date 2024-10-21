Sources/MMIOMacros.wasm:
	SWIFT_BUILD_MACRO_WASM=1 TOOLCHAINS=org.swift.61202409251a swift build --swift-sdk DEVELOPMENT-SNAPSHOT-2024-09-26-a-wasm32-unknown-wasi --product MMIOMacros -c release -Xswiftc -Osize
	cp -a .build/wasm32-unknown-wasi/release/MMIOMacros.wasm Sources/MMIOMacros.wasm
	command -v wasm-opt && wasm-opt -Os Sources/MMIOMacros.wasm -o Sources/MMIOMacros.wasm || :

