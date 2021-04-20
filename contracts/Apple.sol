// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import '../Apple-swap-lib/SafeMath.sol';
import '../Apple-swap-lib/IBEP20.sol';
import '../Apple-swap-lib/BEP20.sol';

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}


contract AppleFinance is Ownable, BEP20('Apple-finance Token', 'APP'){
    using SafeMath for uint256;
    // using SafeBEP20 for IBEP20;
    
    uint256 constant p1 = 7 days * 2 + ( 1 days);
    uint256 constant moonnyx = 7 days * 4 + (2 days);
    uint256 constant moonnyx2 = moonnyx * 2;
    uint256 constant moonnyx3 = moonnyx2 + moonnyx;
    uint256 constant moonnyx6 = moonnyx * 6;
    uint256 constant perennial = moonnyx * 12;
    
    // uint256 constant priceBase = 1 gwei;
    
    uint256 internal _price = 1 gwei;
    
    uint256 public investorsMapCounter;
    
    // uint256 public currentSupply;
    
//     event TokenTransfer(address from);
    event SeedPurchased(address indexed _buyer, uint256 _amount, uint _time);
    event SownSeed(address indexed _user, uint256 _amount, uint _time);
    event Harvest(address indexed _harvester, uint256 _amount, uint256 _date);
    
    struct Investor{
        address _addr;
        bool isPaid;
        uint8 rewardBase;
        uint256 _token;
        uint harvest;
        bool lockGerminator;
        uint256 _duration;
        uint256 _depositDate;
        bool isWhiteListed;
    }
    
    address[] realInvestors;

    mapping(address => Investor) public investorsMap;
    
    mapping(uint8 => uint256) duration;
    
    mapping(uint256 => uint8) yield;
    
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        bool inBlackList;
    }

    // Info of each pool.
    struct PoolInfo {
        // IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. APPs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that APPs distribution occurs.
        uint256 accAppPerShare; // Accumulated APPs per share, times 1e12. See below.
    }

    // The REWARD TOKEN
    IBEP20 public rewardToken;

    // adminAddress
    address public adminAddress;


    // WBNB
    address public immutable WBNB;
    
    uint256 public holdersCount;

    // APP tokens created per block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    
    mapping(address => uint256) germinator;
    
    mapping(address => bool) public isinvestorsMaped;
    
    // limit 10 BNB here
    uint256 public limitAmount = 10000000000000000000;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when APP mining starts.
    uint256 public startBlock;
    // The block number when APP mining ends.
    uint256 public bonusEndBlock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Unstaked(address indexed _addr, uint _amt);

    constructor(
        // IBEP20 _lp,
        IBEP20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        address _wbnb,
        uint256 _amt
    ) {
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        adminAddress = _msgSender();
        WBNB = _wbnb;

        // staking pool
        poolInfo.push(PoolInfo({
            // lpToken: _lp,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accAppPerShare: 0
        }));
        
        duration[1] = p1;
        duration[2] = moonnyx; 
        duration[3] = moonnyx2; 
        duration[4] = moonnyx3; 
        duration[5] = moonnyx6;
        duration[6] = perennial;
        yield[p1] = 1;
        yield[moonnyx] = 3;
        yield[moonnyx2] = 7;
        yield[moonnyx3] = 10;
        yield[moonnyx6] = 21;
        yield[perennial] = 50;

        totalAllocPoint = 1000;
        _mint(address(this), _amt);
        balances[address(this)] = _amt;
        cS += _amt;

    }

    modifier onlyAdmin() {
        require(_msgSender() == adminAddress, "admin: wut?");
        _;
    }
    
    modifier iswhitelisted() {
        require(investorsMap[_msgSender()].isWhiteListed == true); _;
    }

    modifier hasEnoughSeedBalance(uint _qty) {
        require(balances[_msgSender()] > _qty, "Insufficient balance"); _;
    }

    receive() external payable {
        assert(_msgSender() == WBNB); // only accept BNB via fallback from the WBNB contract
    }
    
    
    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        require(cS.add(amount) <= fxsupply, "Supply threshold is reached");
        _mint(msg.sender, amount);
        return true;
    }
    
    function setYield(uint8 _duration, uint8 _newYieldVal) public onlyAdmin returns(bool) {
        uint256 _d = duration[_duration];
        yield[_d] = _newYieldVal;
        return true;
    }

    // Update admin address by the previous dev.
    function setAdmin(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
    }

    function setBlackList(address _blacklistAddress) public onlyAdmin {
        userInfo[_blacklistAddress].inBlackList = true;
    }

    function removeBlackList(address _blacklistAddress) public onlyAdmin {
        userInfo[_blacklistAddress].inBlackList = false;
    }

    // Set the limit amount. Can only be called by the owner.
    function setLimitAmount(uint256 _amount) public onlyOwner {
        limitAmount = _amount;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accAppPerShare = pool.accAppPerShare;
        uint256 lpSupply = balances[address(this)];
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 appReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accAppPerShare = accAppPerShare.add(appReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accAppPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = balances[address(this)];
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 appReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accAppPerShare = pool.accAppPerShare.add(appReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Stake tokens to SmartChef
    function deposit() public payable {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_msgSender()];

        require (user.amount.add(msg.value) <= limitAmount, 'exceed the top');
        require (!user.inBlackList, 'in black list');

        updatePool(0);
        if (user.amount > 0) {

            uint256 pending = user.amount.mul(pool.accAppPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                rewardToken.transfer(address(_msgSender()), pending);
            }
        }
        if(msg.value > 0) {
            IWBNB(WBNB).deposit{value: msg.value}();
            assert(IWBNB(WBNB).transfer(address(this), msg.value));
            user.amount = user.amount.add(msg.value);
        }
        user.rewardDebt = user.amount.mul(pool.accAppPerShare).div(1e12);

        emit Deposit(_msgSender(), msg.value);
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{gas: 23000, value: value}("");
        // (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }

    // Withdraw tokens from STAKING.
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_msgSender()];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accAppPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0 && !user.inBlackList) {
            rewardToken.transfer(address(_msgSender()), pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            IWBNB(WBNB).withdraw(_amount);
            safeTransferBNB(address(_msgSender()), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accAppPerShare).div(1e12);

        emit Withdraw(_msgSender(), _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        // PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_msgSender()];
        payable(_msgSender()).transfer(user.amount);
        emit EmergencyWithdraw(_msgSender(), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount < balances[address(this)], 'not enough token');
        rewardToken.transfer(address(_msgSender()), _amount);
    }
    
    function getWhiteisted(uint _amt) public payable returns(uint, uint, uint) {
        investorsMapCounter++;
        uint amtToSend = _amt.mul(_price);
        require(msg.value >= _price.mul(5000) && msg.value >= amtToSend, "Minimum buy is 500 APP");
        payable(adminAddress).transfer(msg.value);
        investorsMap[_msgSender()]._addr = _msgSender();
        investorsMap[_msgSender()].isWhiteListed = true;
        investorsMap[_msgSender()]._depositDate = block.timestamp;
        isinvestorsMaped[_msgSender()] = true;
        investorsMap[_msgSender()]._token = _amt;
        return (amtToSend, msg.value, _price);
    }

    function claimToken() external payable iswhitelisted returns(bool) {
        require(isinvestorsMaped[_msgSender()] == true, "Not investorsMaped");
        require(investorsMap[_msgSender()].isPaid == false, "User already received token");
        require(block.timestamp.add(1 days) >= investorsMap[_msgSender()]._depositDate, "Claim date not yet");
        uint claim = investorsMap[_msgSender()]._token;
        balances[address(this)].sub(claim);
        balances[_msgSender()].add(claim);
        approve(address(this), claim);
        investorsMap[_msgSender()]._token = 0;
        investorsMap[_msgSender()].isWhiteListed = false;
        investorsMap[_msgSender()].isPaid = true;
        realInvestors.push(_msgSender());
        holdersCount ++;
        emit SeedPurchased(_msgSender(), claim, block.timestamp);
        return true;
    }

    function stakeAPP(uint _qty, uint8 _duration) public hasEnoughSeedBalance(_qty) returns(bool) {
        require(_duration > 0 && _duration <= 6, "Duration out of range");
        uint init_balance = balances[_msgSender()];
        balances[_msgSender()] - _qty;
        germinator[_msgSender()] + _qty;
        uint256 k = duration[_duration];
        uint8 reward_base = yield[k];
        investorsMap[_msgSender()].rewardBase = reward_base;
        investorsMap[_msgSender()]._duration = k;
        investorsMap[_msgSender()]._depositDate = block.timestamp;
        investorsMap[_msgSender()].lockGerminator = true;
        require(balances[_msgSender()] == init_balance.add(_qty));

        emit SownSeed(_msgSender(), _qty, block.timestamp);
        return true;
    }
    
    function unstakeAPP() public returns(bool) {
        investorsMap[_msgSender()].lockGerminator = false;
        
        uint amtDue = germinator[_msgSender()].mul(investorsMap[_msgSender()].rewardBase);
        germinator[_msgSender()].sub(amtDue);
        balances[_msgSender()].add(amtDue);
        investorsMap[_msgSender ()].harvest = amtDue; 

        emit Unstaked(_msgSender(), amtDue);
        return true;
    }

    function harvest(address _ad) public returns(bool, uint256) {
        require(germinator[_msgSender()] > 0 && (investorsMap[_msgSender()].lockGerminator = false), "User have no stake");
        require(block.timestamp >= (investorsMap[_msgSender()]._depositDate + investorsMap[_msgSender()]._duration), "Root not yet mature");
        uint _s = germinator[_msgSender()];
        germinator[_msgSender()] - _s;
        _burn(_msgSender(), _s);
        uint8 _reward_b = investorsMap[_msgSender()].rewardBase;
        uint _reward = _s * _reward_b;

        balances[address(this)].sub(_reward);
        balances[_ad].add(_reward);
        investorsMap[_msgSender()].harvest = _reward;

        emit Harvest(_msgSender(), _reward, block.timestamp);
        return (true, _reward);
    }
    
    function setPriceBase(uint256 _newPriceBase) public onlyAdmin returns(bool) {
        _price = 1000000/_newPriceBase;
        return true;
    }

}