#!/bin/bash
dfx stop
dfx start --background --clean
dfx deploy mocked_reputation_test
dfx canister call mocked_reputation_test runAllTests
