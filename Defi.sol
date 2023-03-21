pragma solidity >0.4.0 <=0.9.0;

//import "./Common.sol";
import "./RewardsToken.sol";
import "hardhat/console.sol";

contract Defi is Context, Ownable {
    using SafeMath for uint256;

    constructor() {}

    struct PoolInfo {
        IBEP20 lpToken;
        uint256 startRewardsBlockNum;
        uint256 rewardPerBlock;
        uint256 totalLPtoken;
    }

    struct UserInfo {
        uint256 depositBlockNum;
        uint256 depositAmount;
    }

    PoolInfo[] public poolInfos;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    mapping(address => uint256) private _balances;

    RewardsToken private rewardsToken;

    function init(IBEP20 _lpToken, uint256 _rewardPerBlock,RewardsToken _rewardsToken) public {
        PoolInfo memory _pool = PoolInfo(
            _lpToken,
            block.number,
            _rewardPerBlock,
            0
        );

        poolInfos.push(_pool);

        rewardsToken = _rewardsToken;
    }

    function deposit(
        address sender,
        uint256 _lpTokenAmount,
        uint256 _pid
    ) public onlyOwner {
        PoolInfo storage _selectPool = poolInfos[_pid];
        console.log(
            "_selectPool.startRewardsBlockNum",
            _selectPool.startRewardsBlockNum
        );
        // 添加池子之前，判断地址是否有质押过，如果质押，结算并转账到sender
        if (userInfo[_pid][sender].depositAmount > 0) {
            console.log(
                "userInfo[_pid][sender].depositBlockNum",
                userInfo[_pid][sender].depositBlockNum
            );
            if (block.number > userInfo[_pid][sender].depositBlockNum) {
                uint256 _rewards = (
                    block.number.sub(userInfo[_pid][sender].depositBlockNum)
                ).mul(_selectPool.rewardPerBlock);
                //emit Deposit(sender,_rewards);

                //mintRewardToken(_rewards);
               rewardsToken.mint(address(this),_rewards);
               rewardsToken.transfer(sender, _rewards);

               console.log("claim rewards:",rewardsToken.balanceOf(sender));
            }
        }
        require(
            _selectPool.lpToken.balanceOf(sender) >= _lpTokenAmount,
            "lptoken is not enough"
        );

        _selectPool.totalLPtoken = _selectPool.totalLPtoken.add(_lpTokenAmount);
        console.log("_selectPool.totalLPtoken", _selectPool.totalLPtoken);
        UserInfo memory user = UserInfo(block.number, _lpTokenAmount);
        userInfo[_pid][sender] = user;
        console.log(
            " userInfo[_pid][sender]",
            userInfo[_pid][sender].depositAmount
        );
        emit Deposit(sender,_lpTokenAmount);
    }

    event Deposit(address indexed sender, uint256 value);
}
