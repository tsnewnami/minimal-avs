// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IDelegationManager} from "eigenlayer-contracts/src/contracts/interfaces/IDelegationManager.sol";
import {IAllocationManager, IAllocationManagerTypes} from "eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IStrategyManager} from "eigenlayer-contracts/src/contracts/interfaces/IStrategyManager.sol";
import {ISlashingRegistryCoordinator, ISlashingRegistryCoordinatorTypes} from "eigenlayer-middleware/src/interfaces/ISlashingRegistryCoordinator.sol";
import {IStrategy} from "eigenlayer-contracts/src/contracts/interfaces/IStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IKeyRegistrar} from "eigenlayer-contracts/src/contracts/interfaces/IKeyRegistrar.sol";
import {console} from "forge-std/console.sol";
import {OperatorSet} from "eigenlayer-contracts/src/contracts/libraries/OperatorSetLib.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract Register is Script {
    using BN254 for BN254.G1Point;
    using Strings for uint256;

    // Eigenlayer Core Contracts
    IDelegationManager public DELEGATION_MANAGER =
        IDelegationManager(0xD4A7E1Bd8015057293f0D0A557088c286942e84b);
    IAllocationManager public ALLOCATION_MANAGER =
        IAllocationManager(0x42583067658071247ec8CE0A516A58f682002d07);
    IStrategyManager public STRATEGY_MANAGER =
        IStrategyManager(0x2E3D6c0744b10eb0A4e6F679F71554a39Ec47a5D);
    IKeyRegistrar public KEY_REGISTRAR =
        IKeyRegistrar(0xA4dB30D08d8bbcA00D40600bee9F029984dB162a);

    // Token and Strategy
    IStrategy public STRATEGY_WETH =
        IStrategy(0x424246eF71b01ee33aA33aC590fd9a0855F5eFbc);
    IERC20 public WETH = IERC20(0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9);

    // Operator Set
    uint32 public OPERATOR_SET_ID = 0;

    function _registerAsEigenOperator() internal {
        DELEGATION_MANAGER.registerAsOperator(
            address(0),
            10,
            "https://operator.test.xyz"
        );
    }

    function _depositIntoStrategy() internal {
        WETH.approve(address(STRATEGY_MANAGER), type(uint256).max);
        STRATEGY_MANAGER.depositIntoStrategy(
            IStrategy(STRATEGY_WETH),
            IERC20(WETH),
            0.000001 ether
        );
    }

    function _registerOperatorKey(
        uint256 ecdsaPrivateKey,
        address operator,
        address avs
    ) internal {
        // Define the operator set
        OperatorSet memory operatorSet = OperatorSet({
            avs: avs,
            id: OPERATOR_SET_ID
        });

        // Encode the keydata
        bytes memory keyData = abi.encodePacked(operator);

        // Create BLS signature
        bytes32 messageHash = KEY_REGISTRAR.getECDSAKeyRegistrationMessageHash(
            operator,
            operatorSet,
            operator
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ecdsaPrivateKey, messageHash);
        bytes memory signatureBytes = abi.encodePacked(r, s, v);

        // Register the key
        KEY_REGISTRAR.registerKey(
            operator,
            operatorSet,
            keyData,
            signatureBytes
        );
    }

    function _registerToOperatorSet(
        address operator,
        address avs,
        uint32 operatorSetId
    ) internal {
        uint32[] memory operatorSetIds = new uint32[](1);
        operatorSetIds[0] = uint32(operatorSetId);

        IAllocationManagerTypes.RegisterParams
            memory registerParams = IAllocationManagerTypes.RegisterParams({
                avs: avs,
                operatorSetIds: operatorSetIds,
                data: bytes("")
            });

        ALLOCATION_MANAGER.registerForOperatorSets(operator, registerParams);
    }

    function run() public {
        uint256 operatorPrivateKey = vm.envUint("ECDSA_PRIV_KEY");
        uint256 avsPrivateKey = vm.envUint("AVS_PRIV_KEY");
        address avs = vm.addr(avsPrivateKey);
        address operator = vm.addr(operatorPrivateKey);
        console.log("Operator address:", operator);
        console.log("AVS address:", avs);

        vm.startBroadcast(operatorPrivateKey);

        // _registerAsEigenOperator();
        // _depositIntoStrategy();
        _registerOperatorKey(
            operatorPrivateKey,
            operator,
            avs
        );
        _registerToOperatorSet(
            operator,
            avs,
            OPERATOR_SET_ID
        );
        vm.stopBroadcast();
    }
}
