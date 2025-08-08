// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ICrossChainRegistry, ICrossChainRegistryTypes} from "eigenlayer-contracts/src/contracts/interfaces/ICrossChainRegistry.sol";
import {OperatorSet} from "eigenlayer-contracts/src/contracts/libraries/OperatorSetLib.sol";
import {IKeyRegistrar, IKeyRegistrarTypes} from "eigenlayer-contracts/src/contracts/interfaces/IKeyRegistrar.sol";
import {IECDSATableCalculator} from "eigenlayer-middleware/src/interfaces/IECDSATableCalculator.sol";
import {IOperatorTableCalculator} from "eigenlayer-contracts/src/contracts/interfaces/IOperatorTableCalculator.sol";
import {console} from "forge-std/console.sol";

contract Multichain is Script {
    ICrossChainRegistry public CROSS_CHAIN_REGISTRY =
        ICrossChainRegistry(0x287381B1570d9048c4B4C7EC94d21dDb8Aa1352a);
    IOperatorTableCalculator public ECDSA_TABLE_CALCULATOR =
        IOperatorTableCalculator(0xaCB5DE6aa94a1908E6FA577C2ade65065333B450);

    function _registerMultichain(address avs) internal {
        // Define chainIDs
        uint256[] memory chainIDs = new uint256[](2);
        chainIDs[0] = 11155111; // Sepolia
        chainIDs[1] = 84532; // Base Sepolia

        // Define Operator Set and Config
        OperatorSet memory operatorSet = OperatorSet({avs: avs, id: 0});
        ICrossChainRegistryTypes.OperatorSetConfig
            memory config = ICrossChainRegistryTypes.OperatorSetConfig({
                owner: avs,
                maxStalenessPeriod: 86400
            });

        // Register Multichain
        CROSS_CHAIN_REGISTRY.createGenerationReservation(
            operatorSet,
            ECDSA_TABLE_CALCULATOR,
            config
        );
    }

    function run() public {
        uint256 avsPrivateKey = vm.envUint("AVS_PRIV_KEY");
        address avs = vm.addr(avsPrivateKey);
        console.log("AVS address:", avs);
        vm.startBroadcast(avsPrivateKey);
        _registerMultichain(avs);
        vm.stopBroadcast();
    }
}
