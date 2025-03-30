// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Maj_Factory.sol";

contract Maj {
    string public majName;
    uint256 public signaturesRequired;
    address[] public admins;
    mapping(address => bool) public isAdmin;
    MajFactory private factory;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        address proposedBy;
        bool active;
        bool executed;
        uint8 numSignatures;
    }
    Transaction[] private transactions;
    mapping(uint256 => mapping(address => bool)) private hasSigned;

    event TransactionProposed(uint256 txIndex, address to, uint256 value, bytes data, address proposedBy);
    event TransactionSigned(uint256 txIndex, address admin, uint256 numSignatures);
    event TransactionExecuted(uint256 txIndex, address to, uint256 value, bytes data);
    event AdminAdded(address newAdmin);
    event AdminRemoved(address adminRemoved);
    event SignaturesRequiredChanged(uint256 signaturesRequired);

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Maj__OnlyAdmin");
        _;
    }

    modifier onlyMaj() {
        require(msg.sender == address(this), "Maj__OnlyMaj");
        _;
    }

    constructor(string memory _majName, address[] memory _admins, uint256 _sigsRequired, address _factory) {
        factory = MajFactory(_factory);
        for (uint i = 0; i < _admins.length; ++i) {
            _addAdmin(_admins[i]);
        }
        require(_sigsRequired >= 2 && _sigsRequired <= admins.length, "Invalid signature count");
        signaturesRequired = _sigsRequired;
        majName = _majName;
    }

    function addAdmin(address _newAdmin) public onlyMaj {
        _addAdmin(_newAdmin);
        factory.updateAdminStatus(_newAdmin, address(this), true);
        emit AdminAdded(_newAdmin);
    }

    function removeAdmin(address _toRemove) public onlyMaj {
        require(isAdmin[_toRemove], "Maj__AddressIsNotAdmin");
        require(admins.length > 2, "Maj__TwoAdminMinimum");
        isAdmin[_toRemove] = false;
        for (uint i; i < admins.length; ++i) {
            if (admins[i] == _toRemove) {
                admins[i] = admins[admins.length - 1];
                admins.pop();
                break;
            }
        }
        factory.updateAdminStatus(_toRemove, address(this), false);
        emit AdminRemoved(_toRemove);
    }

    function _addAdmin(address _admin) private {
        require(!isAdmin[_admin], "Maj__DuplicateAdminAddress");
        require(_admin != address(0), "Maj__ZeroAddress");
        admins.push(_admin);
        isAdmin[_admin] = true;
    }
}
