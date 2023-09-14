#===-------------------------------------------------------------*- make -*-===#
#
# This source file is part of the Swift Argument Parser open source project
#
# Copyright (c) 2023 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See https://swift.org/LICENSE.txt for license information
#
#===------------------------------------------------------------------------===#

CONFIGURATION = debug

SWIFT_FORMAT_CONFIGURATION := SupportingFiles/Tools/swift-format/.swift-format

.DEFAULT_GOAL=build

.PHONY: all
all: lint build test

.PHONY: lint
lint:
	@echo "linting..."
	@swift-format lint \
		--configuration SupportingFiles/Tools/swift-format/.swift-format \
		--recursive \
		Package.swift Sources Tests

.PHONY: format
format:
	@echo "formatting..."
	@swift-format format \
		--configuration SupportingFiles/Tools/swift-format/.swift-format \
		--recursive \
		--in-place \
		Package.swift Sources Tests

.PHONY: build
build: lint
	@echo "building..."
	@swift build --configuration $(CONFIGURATION)

.PHONY: test
test: build
	@echo "testing..."
	@swift test --parallel

.PHONY: clean
clean:
	@echo "cleaning..."
	@swift package clean
	@rm -rf .build
