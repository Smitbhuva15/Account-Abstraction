// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "../../src/ethereum/ MinimalAccount.sol";
import {DeployMinimal} from "../../script/DeployMinimal.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SendPackedUserOp} from "../../script/SendPackedUserOp.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    HelperConfig helperConfig;
    MinimalAccount minimalAccount;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;

    uint256 missingAccountFunds=1e18;

    address randomuser = makeAddr("randomUser");

    uint256 constant AMOUNT = 1e18;

    function setUp() public {
        DeployMinimal deployMinimal = new DeployMinimal();
        (helperConfig, minimalAccount) = deployMinimal.deployMinimalAccount();
        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }

    function testOwnerCanExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );
        // Act
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);

        // Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testInvalidOwnerCanExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        // Act

        vm.startPrank(randomuser);
        vm.expectRevert(
            MinimalAccount.MinimalAccount__OnlyEntryPointOrOwner.selector
        );
        minimalAccount.execute(dest, value, functionData);

        vm.stopPrank();
    }

    function testRecoverSignedOp() public view{
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );


        (address entryPoint, address account) = helperConfig
            .localNetworkConfig();
        HelperConfig.NetworkConfig memory localnetwork = HelperConfig.NetworkConfig({
            entryPoint: entryPoint,
            account: account
        });

        bytes memory executeCallData = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            dest,
            value,
            functionData
        );
        PackedUserOperation memory packeduserOp = sendPackedUserOp
            ._generatesignedUserOperation(executeCallData,localnetwork, address(minimalAccount));

        bytes32 userOperationHash = IEntryPoint(entryPoint).getUserOpHash(
            packeduserOp
        );

      
        address actualSigner = ECDSA.recover(
            userOperationHash.toEthSignedMessageHash(),
            packeduserOp.signature
        );

    
        assertEq(actualSigner, minimalAccount.owner());
    }


    function testValidationOfUserOps() public{
          assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );


        (address entryPoint, address account) = helperConfig
            .localNetworkConfig();
        HelperConfig.NetworkConfig memory localnetwork = HelperConfig.NetworkConfig({
            entryPoint: entryPoint,
            account: account
        });

        bytes memory executeCallData = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            dest,
            value,
            functionData
        );
        PackedUserOperation memory packeduserOp = sendPackedUserOp
            ._generatesignedUserOperation(executeCallData,localnetwork,address(minimalAccount));

        bytes32 userOperationHash = IEntryPoint(entryPoint).getUserOpHash(
            packeduserOp
        );
  
        vm.startPrank(address(entryPoint));
        uint256 validationData=minimalAccount.validateUserOp(packeduserOp,userOperationHash,missingAccountFunds);
        assertEq(validationData, 0);
        vm.stopPrank();

    }


      function testEntryPointCanExecuteCommands() public  {
      
       assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );


        (address entryPoint, address account) = helperConfig
            .localNetworkConfig();
        HelperConfig.NetworkConfig memory localnetwork = HelperConfig.NetworkConfig({
            entryPoint: entryPoint,
            account: account
        });

        bytes memory executeCallData = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            dest,
            value,
            functionData
        );
        PackedUserOperation memory packeduserOp = sendPackedUserOp
            ._generatesignedUserOperation(executeCallData,localnetwork,address(minimalAccount));

        vm.deal(address(minimalAccount), 1e18);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packeduserOp;

    
        vm.prank(randomuser);
        IEntryPoint(entryPoint).handleOps(ops, payable(randomuser));

       
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }
}
