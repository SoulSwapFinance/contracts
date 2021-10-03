// SPDX-License-Identifier: MIT
// Created by DeGatchi (3/10/2021) for SoulSwap 
pragma solidity 0.8.9;

interface ISummoner {
    function userInfo(uint pid, address user) external view returns(uint, uint, uint, uint, uint, uint, uint);
    function poolInfo(uint pid) external view returns (address, uint, uint, uint);
    function poolLength() external view returns (uint);
    function totalAllocPoint() external view returns (uint);
    function soulPerSecond() external view returns (uint);
    function getWithdrawable(uint pid, uint timeDelta, uint amount) external view returns (uint _feeAmount, uint _withdrawable);
    function userDelta(uint256 _pid, address _user) external view returns (uint256 delta);
    function getFeeRate(uint pid, uint timeDelta) external view returns (uint feeRate);
    function pendingSoul(uint pid, address user) external view returns (uint);
    function deposit(uint pid, uint amount) external;
}

interface IToken {
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract FarmHelper {
        
    address SUMMONER_CONTRACT = 0xce6ccbB1EdAD497B4d53d829DF491aF70065AB5B;    
    
    address FUSD = 0xAd84341756Bf337f5a0164515b1f6F993D194E1f;
    address FUSDT = 0x049d68029688eAbF473097a2fC38ef61633A3C7A;
    address USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address WETH = 0x74b23882a30290451A17c44f4F05243b6b58C76d;
    address SOUL = 0xe2fb177009FF39F52C0134E8007FA0e4BaAcBd07;
    
    address ftmUsdcLp = 0x160653F02b6597E7Db00BA8cA826cf43D2f39556;
    address soulFusdLp = 0x9e7711eAeb652d0da577C1748844407f8Db44a10;
    address ftmEthLp = 0xC615a5fd68265D9Ec6eF60805998fa5Bb71972Cb;
    
    /// @dev fetches the total pending rewards from all farm pools
    function totalPending() external view returns (uint) {
        uint poolLength = ISummoner(SUMMONER_CONTRACT).poolLength();
        
        uint _totalPending;
        
        for (uint pid; pid < poolLength; pid++) {
            uint pending = ISummoner(SUMMONER_CONTRACT).pendingSoul(pid, msg.sender);
            if (pending != 0) _totalPending += pending;
        }
        
        return _totalPending;
    }
        
    function harvestAll() external {
        uint poolLength = ISummoner(SUMMONER_CONTRACT).poolLength();
        
        for (uint pid; pid < poolLength; pid++) {
            uint pending = ISummoner(SUMMONER_CONTRACT).pendingSoul(pid, msg.sender);
            if (pending != 0) ISummoner(SUMMONER_CONTRACT).deposit(pid, 0);
        }
    }
        
    function fetchTvl(uint pid) public view returns (uint) {
        (address lpToken, , ,) = ISummoner(SUMMONER_CONTRACT).poolInfo(pid);
        
        address token0 = IToken(lpToken).token0();
        address token1 = IToken(lpToken).token1();
        
        uint poolTvl;
        
        if (token0 == FUSD || token1 == FUSD || token0 == USDC || token1 == USDC || token0 == FUSDT || token1 == FUSDT) {
            if (token0 == FUSD || token0 == USDC)  {
                poolTvl = IToken(token0).balanceOf(lpToken) * 2;
            } else {
                poolTvl = IToken(token1).balanceOf(lpToken) * 2;
            }
        } else if (token0 == WFTM || token1 == WFTM) {
            if (token0 == WFTM) {
                poolTvl = IToken(token0).balanceOf(lpToken) * 2;
            } else {
                poolTvl = IToken(token1).balanceOf(lpToken) * 2;
            }
        } else if (token0 == SOUL || token1 == SOUL) {
            if (token0 == SOUL) {
                poolTvl = IToken(token0).balanceOf(lpToken) * 2;
            } else {
                poolTvl = IToken(token1).balanceOf(lpToken) * 2;
            }
        } else if (token0 == WETH || token1 == WETH) {
            if (token0 == WETH) {
                poolTvl = IToken(token0).balanceOf(lpToken) * 2;
            } else {
                poolTvl = IToken(token1).balanceOf(lpToken) * 2;
            }
        }
        
        return poolTvl;
    }   
    
    function fetchPercOfSupply(uint pid) public view returns (uint summonerBal, uint totalSupply) {
        (address lpToken, , ,) = ISummoner(SUMMONER_CONTRACT).poolInfo(pid);
        uint summonerLpTokens = IToken(lpToken).balanceOf(SUMMONER_CONTRACT);
        uint lpTokenSupply = IToken(lpToken).totalSupply();
        return (summonerLpTokens, lpTokenSupply);
    }
    
    function fetchPoolWeight(uint pid) public view returns (uint _pidAlloc, uint _totalAlloc) {
        (, uint pidAlloc, ,) = ISummoner(SUMMONER_CONTRACT).poolInfo(pid);
        uint totalAlloc = ISummoner(SUMMONER_CONTRACT).totalAllocPoint();
        return (pidAlloc, totalAlloc);
    }
    
    // note:
    // yearlySoulFarmRewards = SOUL_PER_YEAR * poolWeight
    function fetchYearlyRewards(uint pid) public view returns (uint _pidAlloc, uint _totalALloc, uint _soulPerYear) {
        (uint pidAlloc, uint totalAlloc)  = fetchPoolWeight(pid);
        uint SECONDS_PER_YEAR = 31536000;
        uint soulPerSec = ISummoner(SUMMONER_CONTRACT).soulPerSecond();
        uint SOUL_PER_YEAR = SECONDS_PER_YEAR * soulPerSec;
        return (pidAlloc, totalAlloc, SOUL_PER_YEAR);
    }
    
    // note:
    // alloc = userBal / contractBal
    // allocPerc = alloc * 100
    function fetchUserOwnershp(uint pid) public view returns (uint userBal, uint contractBal) {
        (uint _userBal, , , , , ,) = ISummoner(SUMMONER_CONTRACT).userInfo(pid, msg.sender);
        (address lpToken, , ,) = ISummoner(SUMMONER_CONTRACT).poolInfo(pid);
        uint _contractBal = IToken(lpToken).balanceOf(SUMMONER_CONTRACT);
        return (_userBal, _contractBal);
    }
    
    function fetchOwnershipRewards(uint pid) external view returns (uint userBal, uint contractBal, uint pidAlloc, uint totalAlloc, uint soulPerYear) {
        (uint _userBal, uint _contractBal) = fetchUserOwnershp(pid);
        (uint _pidAlloc, uint _totalAlloc, uint _soulPerYear) = fetchYearlyRewards(pid);
        return (_userBal, _contractBal, _pidAlloc, _totalAlloc, _soulPerYear);
    }
    
    function fetchPidDetails(uint pid) public view returns (uint summonerLpTokens, uint lpTokenSupply, uint _pidAlloc, uint _totalAlloc, uint _soulPerYear, uint tvl) {
        (uint _summonerLpTokens, uint _lpTokenSupply) = fetchPercOfSupply(pid);
        (uint pidAlloc, uint totalAlloc, uint soulPerYear) = fetchOwnershipRewards(pid);
        uint _tvl = fetchTvl(pid);
        return (_summonerLpTokens, _lpTokenSupply, pidAlloc, totalAlloc, soulPerYear, _tvl);
    }
    
    struct PidDetails {
        uint summonerLpTokens;
        uint lpTokenSupply;
        uint pidAlloc;
        uint totalALloc;
        uint soulPerYear;
        uint tvl;
    }
    
    function fetchAllPidsDetails() external view returns (
        uint[] memory _summonerLpTokens,
        uint[] memory _lpTokenSupply,
        uint[] memory _pidAlloc,
        uint[] memory _totalALloc,
        uint[] memory _tvl,
        uint _soulPerYear
    ) {
        uint[] memory summonerLpToken_;
        uint[] memory lpTokenSupply_;
        uint[] memory pidAlloc_;
        uint[] memory totalALloc_;
        uint[] memory tvl_;
        uint soulPerYear_;
        
        uint poolLength = ISummoner(SUMMONER_CONTRACT).poolLength();

        for (uint i; i < poolLength; i++) {
            (uint summonerLpToken, uint lpTokenSupply, uint pidAlloc, uint totalALloc, uint soulPerYear, uint tvl) = fetchPidDetails(i);
            summonerLpToken_[i] = summonerLpToken;
            lpTokenSupply_[i] = lpTokenSupply;
            pidAlloc_[i] = pidAlloc;
            totalALloc_[i] = totalALloc;
            tvl_[i] = tvl;
            
            if (i == poolLength) soulPerYear_ = soulPerYear;
        }
        
        return (summonerLpToken_, lpTokenSupply_, pidAlloc_, totalALloc_, tvl_, soulPerYear_);
    }

    function fetchTokenRateBals() external view returns (uint ftmUsdcTotalFtm, uint ftmUsdcTotalUsdc, uint soulFusdTotalSoul, uint soulFtmTotalFusd, uint ethFtmTotalFtm, uint ethFtmTotalEth) {
        uint _ftmUsdcTotalFtm = IToken(WFTM).balanceOf(ftmUsdcLp);
        uint _ftmUsdcTotalUsdc = IToken(USDC).balanceOf(ftmUsdcLp);
        
        uint _soulFusdTotalSoul = IToken(SOUL).balanceOf(soulFusdLp);
        uint _soulFtmTotalFusd = IToken(FUSD).balanceOf(soulFusdLp);
        
        uint _ethFtmTotalFtm = IToken(WFTM).balanceOf(ftmEthLp);
        uint _ethFtmTotalEth = IToken(WETH).balanceOf(ftmEthLp);
        
        return (_ftmUsdcTotalFtm, _ftmUsdcTotalUsdc, _soulFusdTotalSoul, _soulFtmTotalFusd, _ethFtmTotalFtm, _ethFtmTotalEth);
    }
    
    function fetchWithdrawable(uint pid, uint amount) external view returns (uint _feeAmount, uint _withdrawable, uint _feeRate) {
        uint timeDelta = ISummoner(SUMMONER_CONTRACT).userDelta(pid, msg.sender);
        (uint feeAmount, uint withdrawable) = ISummoner(SUMMONER_CONTRACT).getWithdrawable(pid, timeDelta, amount);
        uint feeRate = ISummoner(SUMMONER_CONTRACT).getFeeRate(pid, timeDelta);
        return (feeAmount, withdrawable, feeRate);
    }
    
    function fetchStakedBals(uint pid) external view returns (uint staked, uint unstaked) {
        (address lpToken, , ,) = ISummoner(SUMMONER_CONTRACT).poolInfo(pid);
        (uint _staked, , , , , ,) = ISummoner(SUMMONER_CONTRACT).userInfo(pid, msg.sender);
        uint _unstaked = IToken(lpToken).balanceOf(msg.sender);
        return (_staked, _unstaked);
    }
}
