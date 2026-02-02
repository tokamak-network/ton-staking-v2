#!/bin/bash
cd /Users/zena/tokamak-projects/ton-staking-v2/op-e2e
go clean -testcache
GOWORK=off go test -v -run TestSimpleRAT_ValidatorRegistration ./faultproofs
