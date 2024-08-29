#!/bin/bash
dfx stop
dfx start --background --clean
dfx deploy 
dfx canister call flow runTest
