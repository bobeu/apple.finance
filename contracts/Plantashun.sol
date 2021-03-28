// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;


contract Plantashun {
    
    Seed seed = Seed();
    Crop crop = Crop();
    
    address payable owner;
    
    
    mapping(address => uint256) public cropBal;
    mapping(address => mapping(address => uint256)) allowed;
    
     //Only sender with owner Authorization is permiitted
    modifier onlyOwner(address _caller) {
        require(_caller == owner, "UnAuthorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
    
    function changeOwnership() public {
        
    }
    
    function renounceOwnership() public {
        
    }
    
    function plantSeed(uint _amt) public returns bool {
        
    }
    
    function harvestCrop() public {
        
    }
    
    function buySeed() public {
        
    }
    
    function blacklist() public {
        
    }

    function terminate() public onlyOwner(msg.sender) {
        selfdestruct(address(uint160(owner()))); // cast owner to address payable
    }
    
    
}