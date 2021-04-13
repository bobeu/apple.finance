// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/TokenTimelock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract Plantashun {

    address owner;
    using SafeMath for uint;
    IERC20 public _seed;
    IERC20 public _crop;
    uint256 public seedHoldersCount;
    uint256 public cropHoldersCount;
    uint256 constant p1 i;
    uint256 constant moonnyx = 7 days * 4 + (2 days);
    uint256 constant moonnyx2 = moonnyx * 2;
    uint256 constant moonnyx3 = moonnyx2 + moonnyx;
    uint256 constant moonnyx6 = moonnyx * 6;
    uint256 constant perennial = moonnyx * 12;
    
    event TokenTransfer(address from);

    struct SeedInvestor{
        address investorAdd;
        bool isSeedInvestor;
        uint reward;
        uint rewardCount;
        uint cropHarvest;
        bool lockGerminator;  
    }
    
    mapping(address => uint256) public envelope;
    mapping(address => uint256) public barn;
    mapping(address => uint256) germinator;
    mapping(address => SeedInvestor) seedInvestorsMap;
    mapping(uint8 => uint256) constant periodSelection;
    
    SeedInvestor[] public holders;
    address[] cropHolders;
    uint8[6] private periods;
    
    constructor(ERC20 seed, ERC20 crop) {
        _seed = seed;
        _crop = crop;
        owner = msg.sender;
        _setPeriods();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Authorized"); _;
    }

    modifier hasSeed(SeedInvestor memory _investor) {
        require(_investor.isSeedInvestor == true); _;
    }

    function _setPeriods() internal {
        periods[1] = p1;
        periods[2] = moonnyx;
        periods[3] = moonnyx2;
        periods[4] = moonnyx3;
        periods[5] = moonnyx6;
        periods[6] = perennial;
    }

    function tranferSeedToken(uint256 amount) external onlyOwner {
        address from = msg.sender;
        _seed.transferFrom(from, address(this), amount);
        emit TokenTransfer(from);
    }

    function transferCropToken(uint256 amount) external onlyOwner {
        address from = msg.sender;
        _crop.transferFrom(from, address(this), amount);
        emit TokenTransfer(from);
    }

    function getSeedBalance() public view returns(uint256) {
        return envelope[msg.sender];
    }

    function getCropBalance() public view returns(uint256) {
        return barn[msg.sender];
    }



    function sowSeed(uint _qty, uint8 _period) public hasSeed returns(bool) {
        require(seedInvestorsMap[msg.sender].lockGerminator == true, "");
        envelope[msg.sender] - _qty;
        germinator[msg.sender] + _qty;
        seedInvestorsMap[address].lockGerminator = false;
        uint256 selectedPeriod = periodSelection[_period];
        if(block.timestamp == selectedPeriod){
            germinator[msg.sender] - _qty;
            
        }
        return true;
    }

    function harvest() public returns(bool, uint256) {

    }

    function approveSpender(address _spender, uint256 _amount) external {
        _seed.approve(_spender, _amount);
    }

    function increaseAllownce(address _spender, uint256 _value) public {
        _seed.safeIncreaseAllowance(_spender, _value);
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
    
    function blacklist() public {
        
    }
    
    
}