// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Maj_Factory.sol";

contract Maj {

    string public majName;
    uint256 public signaturesRequired;
    address[] public admins;
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isBlacklisted;
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

    event TransactionProposed(
        uint256 txIndex,
        address to,
        uint256 value,
        bytes data,
        address proposedBy
    );
    event TransactionSigned(uint256 txIndex, address admin, uint256 numSignatures);
    event TransactionExecuted(uint256 txIndex, address to, uint256 value, bytes data);
    event SignatureRevoked(uint256 txIndex, address admin, uint256 numSignatures);
    event TransactionCancelled(uint256 txIndex);
    event AdminAdded(address newAdmin);
    // event AdminAdded(address newAdmin, uint256 numSigsRequired);
    event AdminRemoved(address adminRemoved);
    // event AdminRemoved(address adminRemoved, uint256 numSigsRequired);
    event SignaturesRequiredChanged(uint256 signaturesRequired);

    error Maj__DuplicateAdminAddress();
    error Maj__ZeroAddress();
    error Maj__TooManySignaturesRequired();
    error Maj__TooFewSignaturesRequired();
    error Maj__OnlyAdmin();
    error Maj__TransactionNotActive();
    error Maj__DuplicateSignature();
    error Maj__InsufficientSignatures();
    error Maj__TransactionFailed();
    error Maj__UserHasNotSigned();
    error Maj__OnlyProposerCanCancel();
    error Maj__OnlyMaj();
    error Maj__AddressIsNotAdmin();
    error Maj__TwoAdminMinimum();

    modifier onlyAdmin() {
        if(!isAdmin[msg.sender]) revert Maj__OnlyAdmin();
        _;
    }

    modifier onlyActive(uint256 txIndex) {
        if(!transactions[txIndex].active) revert Maj__TransactionNotActive();
        _;
    }

    modifier onlyMaj() {
        if(msg.sender != address(this)) revert Maj__OnlyMaj();
        _;
    }

    modifier onlyAllowed(){
        if(isBlacklisted[msg.sender]) revert Maj__OnlyAdmin();
        _;
    }

    constructor(string memory _majName, address[] memory _admins, uint256 _sigsRequired, address payable _factory) {
        factory = MajFactory(_factory);
        for (uint i = 0; i < _admins.length; ++i) {
            _addAdmin(_admins[i]);
        }
        require(_sigsRequired >= 2 && _sigsRequired <= admins.length, "Invalid signature count");
        signaturesRequired = _sigsRequired;
        majName = _majName;
    }

    fallback() external payable {}
    receive() external payable {}

    
    
    function proposeTransaction(
        address _to, 
        uint256 _value, 
        bytes calldata _data
    ) 
        external 
        onlyAllowed 
        returns (uint256) 
    {
        uint256 internalindex;
        if (isAdmin[msg.sender]) {
            internalindex = AdminProposeTransaction(_to, _value, _data);
    }   else {
            internalindex = nonAdminProposeTransaction(_to, _value, _data);
            }
        return internalindex;
    }
    
    
    function AdminProposeTransaction(
        address _to, 
        uint256 _value, 
        bytes calldata _data
    ) 
        internal 
        onlyAdmin 
        returns (uint256) 
    {
        uint256 txIndex = transactions.length;
        Transaction memory transaction;
        transaction.to = _to;
        transaction.value = _value;
        transaction.data = _data;
        transaction.proposedBy = msg.sender;
        transaction.active = true;
        transactions.push(transaction);
        emit TransactionProposed(txIndex, _to, _value, _data, msg.sender);
        signTransaction(txIndex);
        return txIndex;
    }

    function nonAdminProposeTransaction(
        address _to, 
        uint256 _value, 
        bytes calldata _data
    ) 
        internal  
        returns (uint256) 
    {
        uint256 txIndex = transactions.length;
        Transaction memory transaction;
        transaction.to = _to;
        transaction.value = _value;
        transaction.data = _data;
        transaction.proposedBy = msg.sender;
        transaction.active = true;
        transactions.push(transaction);
        emit TransactionProposed(txIndex, _to, _value, _data, msg.sender);
        return txIndex;
    }

    function signTransaction(uint256 _txIndex) public onlyAdmin onlyActive(_txIndex) {
        if(hasSigned[_txIndex][msg.sender]) revert Maj__DuplicateSignature();
        Transaction storage transaction = transactions[_txIndex];
        transaction.numSignatures += 1;
        hasSigned[_txIndex][msg.sender] = true;
        emit TransactionSigned(_txIndex, msg.sender, transaction.numSignatures);
        if(transaction.numSignatures >= signaturesRequired) executeTransaction(_txIndex);
    }

    function executeTransaction(uint256 _txIndex) public onlyAdmin onlyActive(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        if(transaction.numSignatures < signaturesRequired) revert Maj__InsufficientSignatures();
        transaction.executed = true;
        transaction.active = false;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        if(!success) revert Maj__TransactionFailed();
        emit TransactionExecuted(_txIndex, transaction.to, transaction.value, transaction.data);
    }

    function revokeSignature(uint256 _txIndex) public onlyAdmin onlyActive(_txIndex) {
        if(!hasSigned[_txIndex][msg.sender]) revert Maj__UserHasNotSigned();
        Transaction storage transaction = transactions[_txIndex];
        transaction.numSignatures -= 1;
        hasSigned[_txIndex][msg.sender] = false;
        emit SignatureRevoked(_txIndex, msg.sender, transaction.numSignatures);
    }

    function cancelTransaction(uint256 _txIndex) public onlyAdmin onlyActive(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        if(msg.sender != transaction.proposedBy) revert Maj__OnlyProposerCanCancel();
        transaction.active = false;
        emit TransactionCancelled(_txIndex);
    }


    function changeSignaturesRequired(uint256 _newSigsRequired) public onlyMaj {
        require(_checkNumSigs(_newSigsRequired, admins.length));
        signaturesRequired = _newSigsRequired;
        emit SignaturesRequiredChanged(_newSigsRequired);
    }
 

    function _checkNumSigs(uint256 _numSigs, uint256 _numAdmins) private pure returns (bool) {
        if(_numSigs > _numAdmins) revert Maj__TooManySignaturesRequired();
        if(_numSigs < 2) revert Maj__TooFewSignaturesRequired();
        return true;
    }

    function getTransaction(uint256 txIndex) public view returns (Transaction memory) {
        return transactions[txIndex];
    }

    function adminHasSigned(uint256 txIndex, address admin) public view returns (bool) {
        return hasSigned[txIndex][admin];
    }

    function getAllTransactions() public view returns (Transaction[] memory) {
        return transactions;
    }

    function getNumTransactions() public view returns (uint256) {
        return transactions.length;
    }

    function getAdmins() public view returns (address[] memory) {
        return admins;
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

    function addBlacklist (address _address) public onlyMaj {
        isBlacklisted[_address] = true;
    }

    function removeBlacklist (address _address) public onlyMaj {
        isBlacklisted[_address] = false;
    }

}