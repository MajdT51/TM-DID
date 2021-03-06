pragma solidity ^0.5.0;

contract TM_DID {
    
    struct DID {
        address owner;
        uint256 created;
        uint256 updated;
        bool    revoked;
    }
    
    mapping(address => DID) public dids;
    mapping(address => mapping(bytes32 => mapping(address => uint))) public delegatesOfDid;
    mapping(address => uint) public blockNumOfUpdate;


    event CreatedDID(address didAddress);
    
    /// Register a DID on the ledger
    function createDID() public
    {
        dids[msg.sender].owner = msg.sender;
        dids[msg.sender].created = now;
        dids[msg.sender].updated = now;
        dids[msg.sender].revoked = false;
        
        blockNumOfUpdate[msg.sender] = block.number;
        emit CreatedDID(msg.sender);
    }
    

    event DIDOwnerChanged (address indexed identity, address owner, uint previousChange);
    
    /// Change DID owner
    function changeDIDOwner(address didAddress, address newOwner) public {
        require(dids[didAddress].owner == msg.sender);
        dids[didAddress].updated = now;
        dids[didAddress].owner = newOwner;
        blockNumOfUpdate[didAddress] = block.number;
    }

    /// Look up DID on the ledger
    function getDID(address didAddress) public view returns(address, uint256, uint256, bool) {
        return (dids[didAddress].owner, dids[didAddress].created, dids[didAddress].updated, dids[didAddress].revoked);
    }
    
    /// Modify the validity of DID
    function revokeDID(address didAddress) public {
        require(msg.sender == dids[didAddress].owner);
        dids[didAddress].updated = now;
        dids[didAddress].revoked = true;
    }
    
    /// Get the validity of DID
    function validDelegate(address didAddress, bytes32 delegateType, address delegate) public view returns(bool) {
        uint validity = delegatesOfDid[didAddress][keccak256(abi.encodePacked(delegateType))][delegate];
        return (validity > now);
    }
    
    event DIDDelegateChanged (address indexed didAddress, bytes32 delegateType, address delegate, uint validTo, uint previousChange);

    /// Add an agent for DID
    function addDelegate(address didAddress, bytes32 delegateType, address delegate, uint validity) public {
        delegatesOfDid[didAddress][keccak256(abi.encodePacked(delegateType))][delegate] = now + validity;
        emit DIDDelegateChanged(didAddress, delegateType, delegate, now + validity, blockNumOfUpdate[didAddress]);
        blockNumOfUpdate[didAddress] = block.number;
    }

   /// Modify the validity of agent
    function revokeDelegate(address didAddress, bytes32 delegateType, address delegate) public {
        delegatesOfDid[didAddress][keccak256(abi.encodePacked(delegateType))][delegate] = now;
        emit DIDDelegateChanged(didAddress, delegateType, delegate, now, blockNumOfUpdate[didAddress]);
        blockNumOfUpdate[didAddress] = block.number;
    }


    event DIDAttributeChanged ( address indexed didAddress, bytes32 name, bytes value, uint validTo, uint previousChange);

    /// Set DID's attribute information
    function setAttribute(address didAddress, bytes32 name, bytes memory value, uint validity) public {
        require(msg.sender == dids[didAddress].owner);
        emit DIDAttributeChanged(didAddress, name, value, now + validity, blockNumOfUpdate[didAddress]);
        blockNumOfUpdate[didAddress] = block.number;
    }
    
    /// Modify the validity of DID's attribute information
    function revokeAttribute(address didAddress, bytes32 name, bytes memory value) public {
        require(msg.sender == dids[didAddress].owner);
        emit DIDAttributeChanged(didAddress, name, value, 0, blockNumOfUpdate[didAddress]);
        blockNumOfUpdate[didAddress] = block.number;
    }
}
