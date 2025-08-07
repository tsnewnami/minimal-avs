// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IDelegationManager} from "eigenlayer-contracts/src/contracts/interfaces/IDelegationManager.sol";
import {IAllocationManager} from "eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IStrategyManager} from "eigenlayer-contracts/src/contracts/interfaces/IStrategyManager.sol";
import {ISlashingRegistryCoordinator} from "eigenlayer-middleware/src/interfaces/ISlashingRegistryCoordinator.sol";
import {IStrategy} from "eigenlayer-contracts/src/contracts/interfaces/IStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IBLSApkRegistryTypes} from "@eigenlayer-middleware/src/interfaces/IBLSApkRegistry.sol";
import {BN254} from "@eigenlayer-middleware/src/libraries/BN254.sol";
import {console} from "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract Register is Script {
    using BN254 for BN254.G1Point;
    using Strings for uint256;

    IDelegationManager public _delegationManager;
    IAllocationManager public _allocationManager;
    IStrategyManager public _strategyManager;
    ISlashingRegistryCoordinator public _slashingRegistryCoordinator;

    address public avs;
    address public token;
    address public strategy;
    address public operator;

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
        _slashingRegistryCoordinator = ISlashingRegistryCoordinator(
            stdJson.readAddress(config, "$.contracts.slashingRegistryCoordinator")
        );
        avs = stdJson.readAddress(config, "$.avs");
        token = stdJson.readAddress(config, "$.token");
        strategy = stdJson.readAddress(config, "$.strategy");

        // Registration parameters
        operatorSetId = stdJson.readUint(config, "$.operatorSetId");
        metadataURI = stdJson.readString(config, "$.metadataURI");
        operator = stdJson.readAddress(config, "$.operatorPubkey");
    }


    function _registerAsEigenOperator() internal {
        _delegationManager.registerAsOperator(address(0), 10, metadataURI);
    }

    function _depositIntoStrategy() internal {
        IERC20(token).approve(address(_strategyManager), type(uint256).max);
        _strategyManager.depositIntoStrategy(IStrategy(strategy), IERC20(token), 0.000001 ether);
    }

    function _parseBLSKeys() internal returns (BN254.G1Point memory, BN254.G2Point memory) {
        string memory config = vm.readFile("script/BLSConfig.json");
        uint256 G1X = stdJson.readUint(config, "$.G1X");
        uint256 G1Y = stdJson.readUint(config, "$.G1Y");
        uint256 G2X0 = stdJson.readUint(config, "$.G2X0");
        uint256 G2Y0 = stdJson.readUint(config, "$.G2Y0");
        uint256 G2X1 = stdJson.readUint(config, "$.G2X1");
        uint256 G2Y1 = stdJson.readUint(config, "$.G2Y1");

        uint256[2] memory G2XPair = [G2X1, G2X0];
        uint256[2] memory G2YPair = [G2Y1, G2Y0];
        return (BN254.G1Point(G1X, G1Y), BN254.G2Point(G2XPair, G2YPair));
    }

    function _registerToOperatorSet() internal {
        (BN254.G1Point memory pubkeyG1, BN254.G2Point memory pubkeyG2) = _parseBLSKeys();

        IBLSApkRegistryTypes.PubkeyRegistrationParams memory registrationParams;
        registrationParams.pubkeyG1 = pubkeyG1;
        registrationParams.pubkeyG2 = pubkeyG2;


        // // Get the pubkey registration message hash that needs to be signed
        // bytes32 pubkeyRegistrationMessageHash = _slashingRegistryCoordinator.calculatePubkeyRegistrationMessageHash(operator);
        // console.log("pubkeyRegistrationMessageHash", pubkeyRegistrationMessageHash);

        // _allocationManager.registerForOperatorSets(avs, token, strategy, metadataURI);
    }

    function run() public {
        _parseConfig();
        uint256 operatorPrivateKey = vm.envUint("ECDSA_PRIV_KEY");
        _registerToOperatorSet();
        // vm.startBroadcast(operatorPrivateKey);
        // _registerAsEigenOperator();
        // _depositIntoStrategy();
        // _registerToOperatorSet();
        // vm.stopBroadcast();
    }
}
