// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Maj.sol";

contract MajFactory {

    event MajDeployed(address indexed majAddress, address[] _admins, uint256 _sigsRequired);
    event AdminStatusUpdated(address indexed admin, address indexed majContract, bool status);

    error Maj__NameTaken();
    error Maj__NameNotFound();
    
    Maj[] public deployedContracts;
    mapping(string => address) private majName;
    mapping(string => bool) public isMajNameNotAvailable;
    mapping(address => address[]) private adminMajContracts;

    function createMajContract(string memory _name, address[] memory _admins, uint256 _sigsRequired) external {
        if(isMajNameNotAvailable[_name]) revert Maj__NameTaken();
        Maj newContract = new Maj(_name, _admins, _sigsRequired, payable(address(this)));
        deployedContracts.push(newContract);
        isMajNameNotAvailable[_name] = true;
                for (uint i = 0; i < _admins.length; i++) {
            adminMajContracts[_admins[i]].push(payable(address(newContract)));
        }
        emit MajDeployed(address(newContract), _admins , _sigsRequired);
    }
    
    function updateAdminStatus(address _admin, address _majContract, bool _status) external {
        require(_status || msg.sender == _majContract, "Unauthorized update");
        if (_status) {
            adminMajContracts[_admin].push(_majContract);
        } else {
            address[] storage contracts = adminMajContracts[_admin];
            for (uint i = 0; i < contracts.length; i++) {
                if (contracts[i] == _majContract) {
                    contracts[i] = contracts[contracts.length - 1];
                    contracts.pop();
                    break;
                }
            }
        }
        emit AdminStatusUpdated(_admin, _majContract, _status);
    }
    
    function isAdminOfAny(address _admin) external view returns (bool) {
        return adminMajContracts[_admin].length > 0;
    }
    
    function getAdminContracts(address _admin) external view returns (address[] memory) {
        return adminMajContracts[_admin];
    }
    
    function getDeployedMajList() external view returns (Maj[] memory) {
        return deployedContracts;
    }
    
    function getDeployedMajNames(string memory _name) external view returns (address majAdderess) {
        if(!isMajNameNotAvailable[_name]) revert Maj__NameNotFound();
        return majName[_name];
    }

        // Fallback function to handle unexpected calls
    fallback() external payable {
    }

    // Receive function to accept ETH transfers
    receive() external payable {
    }
}
