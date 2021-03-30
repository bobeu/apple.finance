// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// import "contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

interface seedRecipient { 
    function getApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}

contract Seed {
    
    using SafeMath for uint256;
    
    // Public variables of the token
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    // uint256 userIndex = 0;
    uint256 public seedInvestorsCount;
    
    struct User{
        address investor;
        bool isInvestor;
        uint investmentCount;
        uint reward;
        uint rewardCount;
    }
    
    // An array with all balances 
    mapping (address => uint256) public balOf;
    mapping (address => mapping(address => uint)) public allowance;
    mapping (address => mapping(uint => bool)) alcs;
    // mapping (address => seedInvestorsCount) internal seedInvestorMap;
    
    User[] public users;

    // Generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);

    //Only sender with owner Authorization is permiitted
    modifier onlyOwner(address _caller) {
        require(_caller == owner, "UnAuthorized");
        _;
    }
    
    modifier isNotFreezed(address _any) {
        require(alcs[_any][balOf[_any]] == true, "Account is freezed");
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
    
    // Internal transfer function
    function _transfer(address _from, address _to, uint _value) internal isNotFreezed(_from) {
        require(_to != address(0));
        require(balOf[_from] >= _value);
        require(balOf[_to] + _value > balOf[_to]);
        uint previousBalances = balOf[_from] + balOf[_to];
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
        seedRecipient spender = seedRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.getApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

      function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
   
    function burn(uint256 _value) public isNotFreezed(msg.sender) returns (bool success) {
        require(balOf[msg.sender] >= _value);   
        balOf[msg.sender] -= _value;            
        totalSupply -= _value;                    
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public isNotFreezed(_from) returns (bool success) {
        require(balOf[_from] >= _value);               
        require(_value <= allowance[_from][msg.sender]);   
        balOf[_from] -= _value;                        
        allowance[_from][msg.sender] -= _value;          
        totalSupply -= _value;        
        emit Burn(_from, _value);
        return true;
    }
    
    function freezeAlc(address _any) public onlyOwner(msg.sender) {
        require(alcs[_any][balOf[_any]] == true, "Already frozen");
        alcs[_any][balOf[_any]] == false;
    }
    
    function unfreeze(address _any) public onlyOwner(msg.sender) {
        require(alcs[_any][balOf[_any]] == false, "Already frozen");
        alcs[_any][balOf[_any]] == true;
    }
}


contract Crop {
    
    using SafeMath for uint256;
    
    // Public variables of the token
    address public owNer;
    string public nAme;
    string public sYmbol;
    uint8 public dEcimals = 18;
    uint256 public totaLSupply;
    uint256 useRIndex = 0;
    
    // An array with all balances 
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint)) public allOwance;
    mapping (address => mapping(uint => bool)) approveAlcs;
    

    // Generates a public event on the blockchain that will notify clients
    event TransFer(address indexed from, address indexed to, uint256 value);
    event ApproVal(address indexed _owner, address indexed _spender, uint256 _value);
    event BuRn(address indexed from, uint256 value);

    //Only sender with owner Authorization is permiitted
    modifier onlyOWner(address _caller) {
        require(_caller == owNer, "UnAuthorized");
        _;
    }
    
    modifier notFreezed(address _any) {
        require(approveAlcs[_any][balanceOf[_any]] == true, "Account is frozen"); _;
    }
    
    modifier hasEnofBalance(address _sndr, uint _value) {
        require(balanceOf[_sndr] > _value, "Insufficient CROP balance"); _;
    }

    // Initializes token properties.
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) {
        totaLSupply = initialSupply * 10 ** uint256(dEcimals);
        balanceOf[msg.sender] = totaLSupply;               
        nAme = tokenName;
        sYmbol = tokenSymbol;
        owNer = msg.sender;
    }
    
    
    // Internal transfer function
    function _transFer(address _from, address _to, uint _value) internal notFreezed(_from) hasEnofBalance(_from, _value) {
        require(_to != address(0));
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit TransFer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    // Mint assets.
    function minTToken(address target, uint256 mintedAmount) onlyOWner(msg.sender) public {
        require(totaLSupply >= mintedAmount, "Threshold exceeded");
        balanceOf[target] += mintedAmount;
        totaLSupply -= mintedAmount;
        emit TransFer(address(0), address(this), mintedAmount);
        emit TransFer(address(this), target, mintedAmount);
    }
  
    function transFer(address _to, uint256 _value) public returns (bool success) {
        _transFer(msg.sender, _to, _value);
        return true;
    }

    function apprOve(address _spender, uint256 _value) public returns (bool success) {
        allOwance[msg.sender][_spender] = _value;
        emit ApproVal(msg.sender, _spender, _value);
        return true;
    }

    function apprOveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        seedRecipient spender = seedRecipient(_spender);
        if (apprOve(_spender, _value)) {
            spender.getApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

      function transFerFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allOwance[_from][msg.sender]);
        allOwance[_from][msg.sender] -= _value;
        _transFer(_from, _to, _value);
        return true;
    }
   
    function buRn(uint256 _value) public hasEnofBalance(msg.sender, _value) returns (bool success) {
        balanceOf[msg.sender] -= _value;            
        totaLSupply -= _value;                    
        emit BuRn(msg.sender, _value);
        return true;
    }
    
    function buRnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);               
        require(_value <= allOwance[_from][msg.sender]);   
        balanceOf[_from] -= _value;                        
        allOwance[_from][msg.sender] -= _value;          
        totaLSupply -= _value;        
        emit BuRn(_from, _value);
        return true;
    }
    
    function freeZeAlc(address _target) public onlyOWner(msg.sender) {
        require(approveAlcs[_target][balanceOf[_target]] == true, "Already frozen");
        approveAlcs[_target][balanceOf[_target]] == false;
    }
    
    function unfreezeAlc(address _any) public onlyOWner(msg.sender) {
        require(approveAlcs[_any][balanceOf[_any]] == false, "Already frozen");
        approveAlcs[_any][balanceOf[_any]] == true;
    }
    
}


abstract contract Plantashun is Seed, Crop{
    address internal sAdd;
    address internal cAdd;
    
    Seed seed = Seed(sAdd);
    Crop crop = Crop(cAdd);
    
    address payable oWner;
    
    struct Investor{
        address investorAdd;
        bool isSeedInvestor;
        uint reward;
        uint rewardCount;
        
    }
    
    mapping(address => uint256) public accountBal;
    mapping(address => mapping(address => uint256)) allowed;
    
    Investor[] public holders;
    
    constructor(address _sadd, address _cadd) {
        sAdd = _sadd;
        cAdd = _cadd;
    }
    
    function _setUserInfo(address _target, uint _reward, uint _rewardCount) internal {
        holders.push(Investor(_target, true, _reward, _rewardCount));
    }
    
    function changeOwnership() public {
        
    }
    
    function renounceOwnership() public {
        
    }
    
    function plantSeed(uint _amt) public returns(bool) {
        
    }
    
    function harvestCrop() public {
        
    }
    
    function buySeed() public {
        
    }
    
    function blacklist() public {
        
    }
    
    
}