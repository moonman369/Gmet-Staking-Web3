// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GmetStaking {

    struct Referral {
        uint256 referralTimestamp;
        uint256 referralInvestment;
        address referredAddress;
        // uint256 referralRewardPercentage;
    }

    // Struct to represent staker information
    struct Staker {
        uint256 amount; // Amount staked
        uint256 startTime; // Time when staking started
        // uint256 referralCount;
        uint8 referralLevel;
        address referrer; // Referrer address
        // mapping (uint256 =>  Referral) referrals;
        Referral [] directReferrals;
    }

    // Mapping of staker addresses to their staker information
    mapping(address => Staker) public stakers;

    // Events
    event Staked(address indexed staker, uint256 amount);
    event Withdrawn(address indexed staker, uint256 amount);
    event DirectReferral(address indexed referrer, address indexed referee, uint256 amount, uint256 timestamp);
    // event LevelUpReward (address indexed referrer, uint256 amount,  uint256 timestamp);
    event StakerLevelUp(address indexed staker, uint8 currentLevel,  uint256 timestamp);

    // Constants
    uint256 public constant MIN_LOCKING_PERIOD = 6 * 30 days; // Minimum locking period of 6 months
    uint256 public constant DAILY_REWARD_RATE = 50; // 0.5% daily reward
    uint256 public constant DIRECT_REFERRAL_REWARD_RATE = 1000; // 10%
    uint256 public constant MAX_REWARD_CAP_GEN = 20000; // 200% maximum reward cap
    uint256 public constant MAX_REWARD_CAP_BOOST = 30000; // 200% maximum reward cap
    uint256[] LEVEL_REWARDS = [ 2000, 1500, 1000, 1000, 1000, 1000, 1000, 500, 500, 500];

    ERC20 immutable stakeToken;

    constructor (address _stakeTokenAddress) {
        stakeToken = ERC20(_stakeTokenAddress);
    }

    function _boosterEligible (address _staker) internal view returns (bool) {
        Staker memory staker = stakers[_staker];
            if(staker.directReferrals.length >= 3) {
            unchecked{
                uint256 flag = 0;
                for (uint256 i = 0; i < staker.directReferrals.length; i++) {
                    if (staker.directReferrals[i].referralInvestment >= staker.amount ) {
                        flag++;
                    }
                    if(flag >= 3) {
                        return true;
                    }
                }

            }
        }
        return false;
    }

    // Functions
    // Stake function
    function stake(uint256 _stakeAmount) external {
        require(_stakeAmount > 0, "Amount must be greater than 0");
        require(stakers[msg.sender].amount == 0, "Already staked");
        
        stakers[msg.sender].amount = _stakeAmount;
        stakers[msg.sender].startTime = block.timestamp;

        emit Staked(msg.sender, _stakeAmount);
    }

    function referralStake (address _referrer, uint256 _stakeAmount) external {
        require(_stakeAmount > 0, "Amount must be greater than 0");
        require(stakers[msg.sender].amount == 0, "Already staked");

        bool isLevelUpRequired = stakers[_referrer].directReferrals.length < 1;

        emit DirectReferral(_referrer, msg.sender, _stakeAmount, block.timestamp);

        stakers[msg.sender].amount = _stakeAmount;
        stakers[msg.sender].startTime = block.timestamp;
        stakers[msg.sender].referrer = _referrer;

        stakers[_referrer].directReferrals.push(Referral(block.timestamp, _stakeAmount, msg.sender));
        // stakers[_referrer].directReferrals.push(Referral(msg.sender, block.timestamp));
        

        unchecked {
            if (isLevelUpRequired) {
                // address currLine = msg.sender;
                address prevLine = _referrer;
                // while ()
                for (uint8 i = 0; i < 10; i++) {
                    if(prevLine == address(0) || stakers[prevLine].referralLevel >= 10) {
                        break;
                    }
                    else {
                        // stakers[currLine].referralLevel++;
                        emit StakerLevelUp(prevLine, stakers[prevLine].referralLevel, block.timestamp);
                        stakers[prevLine].referralLevel++;
                        // currLine = prevLine;
                        prevLine = stakers[prevLine].referrer;
                    }
                }
            }
        }
    }

    // Referral reward function
    function claimReferralReward() external {
        address referrer = stakers[msg.sender].referrer;
        require(referrer != address(0), "No referrer");
        
        uint256 referralReward = stakers[msg.sender].amount * 10 / 100;
        payable(referrer).transfer(referralReward);

        // emit ReferralReward(referrer, msg.sender, referralReward, block.timestamp);
    }

    // Withdraw function
    // function withdraw() external {
    //     require(stakers[msg.sender].amount > 0, "No staked amount");
    //     require(block.timestamp >= stakers[msg.sender].startTime + MIN_LOCKING_PERIOD, "Minimum locking period not met");

    //     uint256 reward = calculateDailyReward(msg.sender, block.timestamp);
    //     uint256 totalAmount = stakers[msg.sender].amount + reward;
    //     payable(msg.sender).transfer(totalAmount);

    //     emit Withdrawn(msg.sender, totalAmount);

    //     // Reset staker info
    //     delete stakers[msg.sender];
    // }

    // Calculate reward function
    function calculateDailyRewardAtTimestamp(address _staker, uint256 _timestamp) public view returns (uint256) {
        Staker memory staker = stakers[_staker];

        require(staker.startTime <= _timestamp, "Invalid timestamp");
        uint256 elapsedTime = _timestamp - stakers[_staker].startTime;
        uint256 rewardPercentage = elapsedTime * DAILY_REWARD_RATE / (1 days);

        uint256 MAX_REWARD_CAP = _boosterEligible(_staker) ? MAX_REWARD_CAP_BOOST : MAX_REWARD_CAP_GEN;
        

        if (rewardPercentage > MAX_REWARD_CAP) {
            rewardPercentage = MAX_REWARD_CAP;
        }

        return stakers[_staker].amount * rewardPercentage / 10000;
    }

    function calculateMaturedReward (address _staker) public view returns (uint256) {
        return stakers[_staker].amount * (
            _boosterEligible(_staker)
            ? MAX_REWARD_CAP_BOOST
            : MAX_REWARD_CAP_GEN
        ) / 10000;
    }

    function calculateDirectReferralReward (address _staker) public view returns (uint256) {
        require(stakers[msg.sender].amount > 0, "No staked amount");
        uint256 directReferralCount = stakers[_staker].directReferrals.length;
        return directReferralCount * (stakers[msg.sender].amount * (DIRECT_REFERRAL_REWARD_RATE / 10000));
    }

    function calculateLevelReward (address _staker, uint256 _timestamp) public view returns (uint256) {
        Staker memory staker = stakers[_staker];
        require(staker.amount > 0, "No staked amount");

        uint256 cumulativeLevelIncome = 0;

        unchecked {
            address nextDownLine = _staker;
            for (uint256 i = 0; i < staker.referralLevel; i++) {
                nextDownLine = stakers[nextDownLine].directReferrals[0].referredAddress;
                uint256 downlineDaily = calculateDailyRewardAtTimestamp(nextDownLine, _timestamp);
                cumulativeLevelIncome += LEVEL_REWARDS[i] * downlineDaily / 10000;
            }
        }

        return cumulativeLevelIncome;
    }

    // View function to check staker's details
    function getStakerDetails(address _staker) external view returns (uint256 amount, uint256 startTime, address referrer, uint256 referralLevel, Referral[] memory directReferrals) {
        amount = stakers[_staker].amount;
        startTime = stakers[_staker].startTime;
        referrer = stakers[_staker].referrer;
        referralLevel = stakers[_staker].referralLevel;
        directReferrals = stakers[_staker].directReferrals;
    }

    function getBlockTimestamp () public view returns (uint256) {
        return block.timestamp;
    }
}
