#!/bin/bash
dfx stop
dfx start --background --clean
dfx deploy 
dfx canister call mocked_reputation_test runAllTests
