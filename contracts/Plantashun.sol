// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/TokenTimelock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Plantashun {

    address owner;
    using SafeMath for uint;
    IERC20 private _root;
    IERC20 private _crop;

    uint128 seedPrice = 1 ether;

    uint256 public rootHoldersCount;
    uint256 public cropHoldersCount;
    uint256 constant p1 = 7 days + (1 days);
    uint256 constant moonnyx = 7 days * 4 + (2 days);
    uint256 constant moonnyx2 = moonnyx * 2;
    uint256 constant moonnyx3 = moonnyx2 + moonnyx;
    uint256 constant moonnyx6 = moonnyx * 6;
    uint256 constant perennial = moonnyx * 12;
    
    event TokenTransfer(address from);
    event RootPurchased(address indexed _buyer, uint256 _amount, uint _time);
    event SownSeed(address indexed _user, uint256 _amount, uint _time);

    struct RootInvestor{
        bool isRootInvestor;
        uint rewardBase;
        uint harvest;
        bool lockGerminator;
        uint256 germ_duration;
        uint256 sowTime;
    }
 
    mapping(address => uint256) germinator;
    mapping(address => RootInvestor) rootInvestorsMap;
    mapping(uint8 => uint256) constant duration;
    mapping(address => bool) public blacklist;
    mapping(uint256 => uint8) yield;
    
    address[] holders;
    address[] cropHolders;
    
    constructor(IERC20 root, IERC20 crop) {
        // Gardens storage _garden;
        _root = root;
        _crop = crop;
        owner = msg.sender;
        duration[1] = p1;
        duration[2] = moonnyx; 
        duration[3] = moonnyx2; 
        duration[4] = moonnyx3; 
        duration[5] = moonnyx6;
        duration[6] = perennial;
        yield[p1] = 1/100;
        yield[moonnyx] = 3/100;
        yield[moonnyx2] = 7/100;
        yield[moonnyx3] = 10/100;
        yield[moonnyx6] = 21/100;
        yield[perennial] = 50/100;

    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Authorized"); _;
    }

    modifier hasRoot() {
        require(rootInvestorsMap[msg.sender].isRootInvestor == true); _;
    }

    modifier hasEnoughRootBalance(uint _qty) {
        require(_root.balanceOf[msg.sender] > _qty, "Insufficient balance"); _;
    }

    modifier hasEnoughCropBalance(uint _qty) {
        require(_crop.balanceOf[msg.sender] > _qty, "Insufficient balance"); _;
    }

    function setPercentYield(uint8 _count, uint128 _p) public onlyOwner returns(bool) {
        require(_count > 0 && _count <= 6, "Duration out of range");
        yield[_count] = _p;
        return true;
    }

    function tranferRoot(uint256 amount) external onlyOwner {
        address from = msg.sender;
        _root.transferFrom(from, address(this), amount);
        emit TokenTransfer(from);
    }

    function transferCassava(uint256 amount) external onlyOwner {
        address from = msg.sender;
        _crop.transferFrom(from, address(this), amount);
        emit TokenTransfer(from);
    }

    function getSeedBalance() public view returns(uint256) {
        return _root.balanceOf[msg.sender];
    }

    function getCropBalance() public view returns(uint256) {
        return _crop.balanceOf[msg.sender];
    }

    function buyRoot(uint256 _qty) public {
        uint initialBalance = msg.sender.balance;
        uint256 amountToPay = mul(_qty, seedPrice);
        require(msg.sender.balance > amountToPay, "Insufficient fund");
        sub(msg.sender.balance, amountToPay);
        address(this).transfer(amountToPay);
        require(address(this).balance > initialBalance, "Anomally detected: transaction reversed");
        sub(_root.balanceOf[address(this)], _qty);
        add(_root.balanceOf[msg.sender], _qty);
        _root.allowance(msg.sender, address(this));
        _root.approve(address(this), _qty);
        rootInvestorsMap[msg.sender] = RootInvestor(true, 0, 0, false, 0);
        holders.push(msg.sender);
        rootHoldersCount ++;

        emit RootPurchased(msg.sender, _qty, block.timestamp);
    }

    function sowSeed(uint _qty, uint8 _duration) public hasRoot hasEnoughRootBalance(_qty) returns(bool) {
        // require(rootInvestorsMap[msg.sender].lockGerminator == false, "Seed already germinated.");
        require(_duration > 0 && _duration <= 6, "Duration out of range");
        sub(_root.balanceOf[msg.sender], _qty);
        add(germinator[msg.sender], _qty);
        uint256 k = duration[_duration];
        uint8 reward_base = yield[k];
        rootInvestorsMap[msg.sender].rewardBase = reward_base;
        rootInvestorsMap[msg.sender].germ_duration = k;
        rootInvestorsMap[msg.sender].sowTime = block.timestamp;
        rootInvestorsMap[msg.sender].lockGerminator = true;

        emit SownSeed(msg.sender, _qty, block.timestamp);
        return true;
    }

    function harvest() public hasRoot returns(bool, uint256) {
        require(germinator[msg.sender] > 0 && rootInvestorsMap[msg.sender].lockGerminator = true, "User have no stake");
        require(block.timestamp >= add(rootInvestorsMap[msg.sender].sowTime, rootInvestorsMap[msg.sender].germ_duration), "Root not yet mature");
        uint _s = germinator[msg.sender];
        sub(germinator[msg.sender], _s);
        uint _reward_b = rootInvestorsMap[msg.sender].rewardBase;
        uint _reward = add(_s, mul(_s, _reward_b));

        sub(_crop.balanceOf[address(this)], _reward);
        add(_crop.balanceOf[msg.sender], _reward);
        rootInvestorsMap[msg.sender].harvest = _reward;
    }

    function _setUserInfo(address _target, uint _reward, uint _rewardCount) internal {
        holders.push(Investor(_target, true, _reward, _rewardCount));
    }
    
    function changeOwnership() public {
        
    }
    
    function plantSeed(uint _amt) public returns(bool) {
        
    }
    
    function harvestCrop() public {
        
    }
    
    function buySeed() public {
        
    }
    
    function blackList(address _target) public onlyOwner returns(string memory) {
        if (blacklist[_target] == true) {
            blacklist[_target] = false;
            return "User is whiteListed";
        } else {
            blacklist[_target] = true;
            return "User is blacklisted";
        }
    }
    
    
}