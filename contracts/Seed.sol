// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface seedRecipient { 
    function getApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}

contract Seed {
    // Public variables of the token
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 userIndex = 0;
    
    struct User{
        bool isInvestor;
        uint investmentCount;
        uint reward;
        uint rewardCount;
    }
    
    // An array with all balances 
    mapping (address => uint256) public balOf;
    mapping (address => mapping(address => uint)) public allowance;
    mapping (mapping(address => mapping(uint256 => bool)) frozenAccounts;
    
    // Note @dev, in production, employ the use of a library to safely and completely
    // remove item from the array.
    mapping (address => User)[] public users;
    
    function setUserInfo(address _target, uint _count, uint _reward, uint _rewardCount) Internal {
        users[_target][userIndex] = User(true, _count, _reward, _rewardCount);
    }
    
    // Generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);

    //Only sender with owner Authorization is permiitted
    modifier onlyOwner(address _caller) {
        require(_caller == owner, "UnAuthorized");
        _;
    }

    // Initializes token properties.
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balOf[msg.sender] = totalSupply;               
        name = tokenName;                               
        symbol = tokenSymbol;
        owner = msg.sender;                          
    }
    
    // // Update state varibles for 
    // function setState() Internal {
        
    // }
    
    // Internal transfer function
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(balOf[_from] >= _value);
        require(balOf[_to] + _value > balOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balOf[_from] -= _value;
        balOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balOf[_from] + balOf[_to] == previousBalances);
    }
    // Mint assets.
    function mintToken(address target, uint256 mintedAmount) onlyOwner(msg.sender) public {
        require(totalSupply >= mintedAmount, "Threshold exceeded");
        balOf[target] += mintedAmount;
        totalSupply -= mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }
  
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

      function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
   
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                    
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balOf[_from] >= _value);               
        require(_value <= allowance[_from][msg.sender]);   
        balOf[_from] -= _value;                        
        allowance[_from][msg.sender] -= _value;          
        totalSupply -= _value;        
        emit Burn(_from, _value);
        return true;
    }
    
    function freezeAlc(address _target, uint256 _val) public onlyOwner(msg.sender) {
        frozenAccounts[_target][_val] == false;
    }
    
}


