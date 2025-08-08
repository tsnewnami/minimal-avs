// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AVSRegistrar} from "eigenlayer-middleware/src/middlewareV2/registrar/AVSRegistrar.sol";
import {IAVSRegistrar} from "eigenlayer-contracts/src/contracts/interfaces/IAVSRegistrar.sol";
import {IAllocationManager} from "eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IKeyRegistrar} from "eigenlayer-contracts/src/contracts/interfaces/IKeyRegistrar.sol";

contract MinimalAVSRegistrar is AVSRegistrar {
    constructor(
        address _avs,
        IAllocationManager _allocationManager,
        IKeyRegistrar _keyRegistrar
    ) AVSRegistrar(_avs, _allocationManager, _keyRegistrar) {
        _disableInitializers();
    }

    function initialize(
    ) external initializer {
    }
}
