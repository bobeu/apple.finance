// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// // import "@openzeppelin/contracts/security/Pausable.sol";
// // import "@openzeppelin/contracts/token/ERC20/utils/TokenTimelock.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Cassava.sol";
import './Root.sol';

contract Plantashun is Cassava, Root {

    address owner;
    address private _c;
    address private _r;
    Cassava cassava = Cassava(_c);
    Root root = Root(_r);

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
    event Harvest(address indexed _harvester, uint256 _amount, uint256 _date);

    struct RootInvestor{
        bool isRootInvestor;
        ufixed8x2 rewardBase;
        uint harvest;
        bool lockGerminator;
        uint256 germ_duration;
        uint256 sowTime;
    }
 
    mapping(address => uint256) germinator;
    mapping(address => RootInvestor) rootInvestorsMap;
    mapping(uint8 => uint256) duration;
    mapping(address => bool) public blacklist;
    mapping(uint256 => ufixed8x2) yield;
    
    address[] holders;
    address[] cropHolders;
    
    constructor(Cassava _crop, Root _root) {
        // Gardens storage _garden;
        _r = _root;
        _c = _crop;
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
        require(root.alc_balance[msg.sender] > _qty, "Insufficient balance"); _;
    }

    modifier hasEnoughCropBalance(uint _qty) {
        require(crop.balances > _qty, "Insufficient balance"); _;
    }

    function setPercentYield(uint8 _count, uint8 _p) public onlyOwner returns(bool) {
        require(_count > 0 && _count <= 6, "Duration out of range");
        yield[_count] = _p;
        return true;
    }

    function tranferRoot(uint256 amount) external onlyOwner {
        address from = msg.sender;
        root.transferFrom(from, address(this), amount);
        emit TokenTransfer(from);
    }

    function transferCassava(uint256 amount) external onlyOwner {
        address from = msg.sender;
        crop.transferFrom(from, address(this), amount);
        emit TokenTransfer(from);
    }

    function getRootBalance() public view returns(uint256) {
        root.alc_balance[msg.sender];
    }

    function getCropBalance() public view returns(uint256) {
        crop.balances[msg.sender];
    }

    function buyRoot(uint256 _qty) public returns(bool) {
        address _contract = address(this);
        address payable _rec = payable(_contract);
        uint initialBalance = msg.sender.balance;
        uint256 amountToPay = _qty * seedPrice;
        require(msg.sender.balance > amountToPay, "Insufficient fund");
        msg.sender.balance - amountToPay;
        _rec.transfer(amountToPay);
        require(address(this).balance > initialBalance, "Anomally detected: transaction reversed");
        root.alc_balance[_rec] - _qty;
        root.alc_balance[msg.sender] + _qty;
        root.alc_balance[msg.sender, address(this)];
        root.approve(address(this), _qty);
        rootInvestorsMap[msg.sender] = RootInvestor(true, 0, 0, false, 0, 0);
        holders.push(msg.sender);
        rootHoldersCount ++;

        emit RootPurchased(msg.sender, _qty, block.timestamp);
        return true;
    }

    function sowSeed(uint _qty, uint8 _duration) public hasRoot hasEnoughRootBalance(_qty) returns(bool) {
        // require(rootInvestorsMap[msg.sender].lockGerminator == false, "Seed already germinated.");
        require(_duration > 0 && _duration <= 6, "Duration out of range");
        root.alc_balance[msg.sender] - _qty;
        germinator[msg.sender] + _qty;
        uint256 k = duration[_duration];
        ufixed8x2 reward_base = yield[k];
        rootInvestorsMap[msg.sender].rewardBase = reward_base;
        rootInvestorsMap[msg.sender].germ_duration = k;
        rootInvestorsMap[msg.sender].sowTime = block.timestamp;
        rootInvestorsMap[msg.sender].lockGerminator = true;

        emit SownSeed(msg.sender, _qty, block.timestamp);
        return true;
    }

    function harvest() public hasRoot returns(bool, uint256) {
        require(germinator[msg.sender] > 0 && (rootInvestorsMap[msg.sender].lockGerminator = false), "User have no stake");
        require(block.timestamp >= (rootInvestorsMap[msg.sender].sowTime + rootInvestorsMap[msg.sender].germ_duration), "Root not yet mature");
        uint _s = germinator[msg.sender];
        germinator[msg.sender] - _s;
        _root.totalSupply() - _s;
        ufixed8x2 _reward_b = rootInvestorsMap[msg.sender].rewardBase;
        uint _reward = _s + (_s * _reward_b);

        crop.balances[address(this)] - _reward;
        crop.balances[msg.sender] + _reward;
        rootInvestorsMap[msg.sender].harvest = _reward;

        emit Harvest(msg.sender, _reward, block.timestamp);
    }
    
    function changeOwnership() public {
        
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