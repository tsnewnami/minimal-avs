// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IDelegationManager} from "eigenlayer-contracts/src/contracts/interfaces/IDelegationManager.sol";
import {IAllocationManager} from "eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IStrategyManager} from "eigenlayer-contracts/src/contracts/interfaces/IStrategyManager.sol";
import {IStrategy} from "eigenlayer-contracts/src/contracts/interfaces/IStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Register is Script {
    IDelegationManager public _delegationManager;
    IAllocationManager public _allocationManager;
    IStrategyManager public _strategyManager;

    address public avs;
    address public token;
    address public strategy;

    string public metadataURI;
    uint256 public operatorSetId;

    function _parseConfig() internal {
        string memory config = vm.readFile("script/registerConfig.json");

        // Parse contract addresses
        _delegationManager = IDelegationManager(
            stdJson.readAddress(config, "$.contracts.delegationManager")
        );
        _allocationManager = IAllocationManager(
            stdJson.readAddress(config, "$.contracts.allocationManager")
        );
        _strategyManager = IStrategyManager(
            stdJson.readAddress(config, "$.contracts.strategyManager")
        );
        avs = stdJson.readAddress(config, "$.avs");
        token = stdJson.readAddress(config, "$.token");
        strategy = stdJson.readAddress(config, "$.strategy");

        // Registration parameters
        operatorSetId = stdJson.readUint(config, "$.operatorSetId");
        metadataURI = stdJson.readString(config, "$.metadataURI");
    }


    function _registerAsEigenOperator() internal {
        _delegationManager.registerAsOperator(address(0), 10, metadataURI);
    }

    function _depositIntoStrategy() internal {
        IERC20(token).approve(address(_strategyManager), type(uint256).max);
        _strategyManager.depositIntoStrategy(IStrategy(strategy), IERC20(token), 0.000001 ether);
    }

    function _registerToOperatorSet() internal {
        // _allocationManager.registerForOperatorSets(avs, token, strategy, metadataURI);
    }

    function run() public {
        _parseConfig();
        uint256 operatorPrivateKey = vm.envUint("ECDSA_PRIV_KEY");
        vm.startBroadcast(operatorPrivateKey);
        // _registerAsEigenOperator();
        // _depositIntoStrategy();
        // _registerToOperatorSet();
        vm.stopBroadcast();
    }
}
