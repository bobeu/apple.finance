// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Apple-swap-lib/SafeMath.sol';
import '../Apple-swap-lib/IBEP20.sol';
import '../Apple-swap-lib/BEP20.sol';
// import '..deps/npm/@appleswap/apple-swap-lib/contracts/access/Ownable.sol';


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
    
    uint256 public _price = 1;
    
//     event TokenTransfer(address from);
    event SeedPurchased(address indexed _buyer, uint256 _amount, uint _time);
    event SownSeed(address indexed _user, uint256 _amount, uint _time);
    event Harvest(address indexed _harvester, uint256 _amount, uint256 _date);

    struct SeedInvestor{
        bool isAppInvestor;
        uint8 rewardBase;
        uint harvest;
        bool lockGerminator;
        uint256 germ_duration;
        uint256 sowTime;
    }
    
    address[] realInvestors;

    mapping(address => SeedInvestor) seedInvestorMap;
    
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
        IBEP20 lpToken;           // Address of LP token contract.
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
    
    mapping(address => uint256) barn;
    
    // limit 10 BNB here
    uint256 public limitAmount = 100000000000000000000;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when APP mining starts.
    uint256 public startBlock;
    // The block number when APP mining ends.
    uint256 public bonusEndBlock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IBEP20 _lp,
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
        adminAddress = msg.sender;
        WBNB = _wbnb;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _lp,
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
        _mint(adminAddress, _amt);

    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }
    
    modifier invested() {
        require(seedInvestorMap[msg.sender].isAppInvestor == true); _;
    }

    modifier hasEnoughSeedBalance(uint _qty) {
        require(_balances[msg.sender] > _qty, "Insufficient balance"); _;
    }

    receive() external payable {
        assert(msg.sender == WBNB); // only accept BNB via fallback from the WBNB contract
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
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
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
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
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
        UserInfo storage user = userInfo[msg.sender];

        require (user.amount.add(msg.value) <= limitAmount, 'exceed the top');
        require (!user.inBlackList, 'in black list');

        updatePool(0);
        if (user.amount > 0) {

            uint256 pending = user.amount.mul(pool.accAppPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                rewardToken.transfer(address(msg.sender), pending);
            }
        }
        if(msg.value > 0) {
            IWBNB(WBNB).deposit{value: msg.value}();
            assert(IWBNB(WBNB).transfer(address(this), msg.value));
            user.amount = user.amount.add(msg.value);
        }
        user.rewardDebt = user.amount.mul(pool.accAppPerShare).div(1e12);

        emit Deposit(msg.sender, msg.value);
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{gas: 23000, value: value}("");
        // (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }

    // Withdraw tokens from STAKING.
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accAppPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0 && !user.inBlackList) {
            rewardToken.transfer(address(msg.sender), pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            IWBNB(WBNB).withdraw(_amount);
            safeTransferBNB(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accAppPerShare).div(1e12);

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount < rewardToken.balanceOf(address(this)), 'not enough token');
        rewardToken.transfer(address(msg.sender), _amount);
    }
    
    function buyApple(uint256 _qty) external payable returns(bool) {
        address payable _contract = payable(address(this));
        uint senderInitBalance = msg.sender.balance;
        uint256 amountToPay = _qty * _price;
        require(senderInitBalance > amountToPay, "Insufficient fund");
        msg.sender.balance.sub(amountToPay);
        _contract.balance.add(amountToPay);
        require(msg.sender.balance < senderInitBalance, "Anomally detected: transaction reversed");
        _balances[_contract].sub(_qty);
        _balances[msg.sender].add(_qty);
        approve(address(this), _qty);
        seedInvestorMap[msg.sender] = SeedInvestor(true, 0, 0, false, 0, 0);
        realInvestors.push(msg.sender);
        holdersCount ++;

        emit SeedPurchased(msg.sender, _qty, block.timestamp);
        return true;
    }

    function sowSeed(uint _qty, uint8 _duration) public invested hasEnoughSeedBalance(_qty) returns(bool) {
        // require(rootInvestorsMap[msg.sender].lockGerminator == false, "Seed already germinated.");
        require(_duration > 0 && _duration <= 6, "Duration out of range");
        uint init_balance = _balances[msg.sender];
        _balances[msg.sender] - _qty;
        germinator[msg.sender] + _qty;
        uint256 k = duration[_duration];
        uint8 reward_base = yield[k];
        seedInvestorMap[msg.sender].rewardBase = reward_base;
        seedInvestorMap[msg.sender].germ_duration = k;
        seedInvestorMap[msg.sender].sowTime = block.timestamp;
        seedInvestorMap[msg.sender].lockGerminator = true;
        require(_balances[msg.sender] == init_balance.add(_qty));

        emit SownSeed(msg.sender, _qty, block.timestamp);
        return true;
    }

    function harvest() public invested returns(bool, uint256) {
        require(germinator[msg.sender] > 0 && (seedInvestorMap[msg.sender].lockGerminator = false), "User have no stake");
        require(block.timestamp >= (seedInvestorMap[msg.sender].sowTime + seedInvestorMap[msg.sender].germ_duration), "Root not yet mature");
        uint _s = germinator[msg.sender];
        germinator[msg.sender] - _s;
        _burn(msg.sender, _s);
        uint8 _reward_b = seedInvestorMap[msg.sender].rewardBase;
        uint _reward = _s + (_s * _reward_b);

        _balances[address(this)] - _reward;
        barn[msg.sender] + _reward;
        seedInvestorMap[msg.sender].harvest = _reward;

        emit Harvest(msg.sender, _reward, block.timestamp);
        return (true, _reward);
    }
    
    function setPrice(uint256 _newPrice) public onlyAdmin returns(bool) {
        _price = _newPrice;
        return true;
    }

}