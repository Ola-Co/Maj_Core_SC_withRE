// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Maj.sol";

contract MajFactory {

    event MajDeployed(address indexed majAddress, address[] _admins, uint256 _sigsRequired);
    
    Maj[] public deployedContracts;

    function createMajContract(address[] memory _admins, uint256 _sigsRequired) external {
        Maj newContract = new Maj(_admins, _sigsRequired);
        deployedContracts.push(newContract);
        emit MajDeployed(address(newContract), _admins , _sigsRequired);
    }
    
    function getDeployedContracts() external view returns (Maj[] memory) {
        return deployedContracts;
    }
}