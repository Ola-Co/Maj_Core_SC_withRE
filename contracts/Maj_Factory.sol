// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Maj.sol";

contract MajFactory {

    event MajDeployed(address indexed majAddress, address[] _admins, uint256 _sigsRequired);

    error Maj__NameTaken();
    error Maj__NameNotFound();
    
    Maj[] public deployedContracts;
    mapping(string => address) private majName;
    mapping(string => bool) public isMajNameAvailable;

    function createMajContract(string memory _name, address[] memory _admins, uint256 _sigsRequired) external {
        if(isMajNameAvailable[_name]) revert Maj__NameTaken();
        Maj newContract = new Maj(_name, _admins, _sigsRequired);
        deployedContracts.push(newContract);
        isMajNameAvailable[_name] = true;
        emit MajDeployed(address(newContract), _admins , _sigsRequired);
    }
    
    function getDeployedMajList() external view returns (Maj[] memory) {
        return deployedContracts;
    }
    
    function getDeployedMajNames(string memory _name) external view returns (address majAdderess) {
        if(!isMajNameAvailable[_name]) revert Maj__NameNotFound();
        return majName[_name];
    }

        // Fallback function to handle unexpected calls
    fallback() external payable {
    }

    // Receive function to accept ETH transfers
    receive() external payable {
    }
}