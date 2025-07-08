// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script,console} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    uint256 constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant LOCAL_CHAIN_ID = 31337;

    address constant BURNER_WALLET = 0x68D36c207B846422cb924C54FcE2085eb8eD5A78;
    uint256 constant ARBITRUM_MAINNET_CHAIN_ID = 42_161;
    uint256 constant ZKSYNC_MAINNET_CHAIN_ID = 324;
    // address constant FOUNDRY_DEFAULT_WALLET = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    address constant ANVIL_DEFAULT_ACCOUNT =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    NetworkConfig public localNetworkConfig;

    constructor() {
        if (block.chainid == LOCAL_CHAIN_ID) {
            // localNetworkConfig=getorCreateNetworkConfig();
        } else if (block.chainid == ETH_MAINNET_CHAIN_ID) {
            localNetworkConfig = getMainnetNetworkConfig();
        } else if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            localNetworkConfig = getSepoliaNetworkConfig();
        } else if (block.chainid == ARBITRUM_MAINNET_CHAIN_ID) {
            localNetworkConfig = getArbitrumMainnetNetworkConfig();
        } else if (block.chainid == ZKSYNC_MAINNET_CHAIN_ID) {
            localNetworkConfig = getZkSyncMainnetNetworkConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getMainnetNetworkConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
                account: BURNER_WALLET
            });
    }

    function getSepoliaNetworkConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
                account: BURNER_WALLET
            });
    }

    function getArbitrumMainnetNetworkConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
                account: BURNER_WALLET
            });
    }

    function getZkSyncMainnetNetworkConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entryPoint: address(0), // no entry point needed
                account: BURNER_WALLET
            });
    }

    function getorCreateNetworkConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);
        EntryPoint entryPoint = new EntryPoint();

        vm.stopBroadcast();
        return
            NetworkConfig({
                entryPoint: address(entryPoint),
                account: ANVIL_DEFAULT_ACCOUNT
            });
    }
}
