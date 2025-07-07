// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from './HelperConfig.s.sol';
import {MinimalAccount} from "../src/ethereum/ MinimalAccount.sol";

contract DeployMinimal is Script{
      function run() public {
        deployMinimalAccount();
    }

   function deployMinimalAccount() public returns (HelperConfig, MinimalAccount) {
        HelperConfig helperConfig = new HelperConfig();
          (address entryPoint,address account)= helperConfig.localNetworkConfig();

        vm.startBroadcast(account);
        MinimalAccount minimalAccount = new MinimalAccount(entryPoint);
        minimalAccount.transferOwnership(account);
        vm.stopBroadcast();
        return (helperConfig, minimalAccount);
    }

}