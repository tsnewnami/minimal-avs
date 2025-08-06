// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IDelegationManager} from "eigenlayer-contracts/src/contracts/interfaces/IDelegationManager.sol";
import {IAllocationManager} from "eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";

contract Register is Script {
    IDelegationManager public _delegationManager;
    IAllocationManager public _allocationManager;

    address public avs;
    address public token;
    address public strategy;

    string public metadataURI;
    

    function _parseConfig() internal {
        string memory config = vm.readFile("script/registerConfig.json");

        // Parse contract addresses
        _delegationManager = IDelegationManager(
            stdJson.readAddress(config, "$.contracts.delegationManager")
        );
        avs = stdJson.readAddress(config, "$.avs");
        token = stdJson.readAddress(config, "$.token");
        strategy = stdJson.readAddress(config, "$.strategy");
        metadataURI = stdJson.readString(config, "$.metadataURI");
    }
}
