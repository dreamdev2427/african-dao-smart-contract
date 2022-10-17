// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract CampaignFactory is Ownable{
    using SafeMath for uint256;

    struct Proposal {
        uint id;
        string IDOnDB;
        uint quorumCount;
        uint createdAt;
    }

    uint public proposalCount;
    uint public MIN_RATE_FOR_VOTING = 100; //0.01 percent
    uint public LIVE_TIME_OF_PROPOSAL = 7 * 3600 * 24;
    uint public TVL_OF_SECURITY_TOKEN;
    uint public MAX_QUORUM = 10000;
    address public securityTokenAddress = 0x2c77D3161533129cA2c8745B6e4ED345c3EDf96d;

    constructor(address _securityTokenAddr, uint _minRate, uint _proposalLT, uint _tvl)
    {
        securityTokenAddress = _securityTokenAddr;
        MIN_RATE_FOR_VOTING = _minRate;
        LIVE_TIME_OF_PROPOSAL = _proposalLT; //time unit is second
        TVL_OF_SECURITY_TOKEN = _tvl;
    }

    mapping(address => mapping(uint => bool)) public voterLookup;
    mapping(uint => Proposal) public candidateLookup;

    function setProposalLiveTime(uint _liveT) external onlyOwner {
        LIVE_TIME_OF_PROPOSAL = _liveT;
    }

    function setTVL_OF_SECURITY_TOKEN(uint _tvl)  external onlyOwner {
        TVL_OF_SECURITY_TOKEN = _tvl;
    }

    function setSecurityTokenAddress(address _addr)  external onlyOwner {
        securityTokenAddress = _addr;
    }

    function setMinTokenForVoting(uint _minRate)  external onlyOwner {
        MIN_RATE_FOR_VOTING = _minRate;
    }

    function addProposals(string[] memory _idOnDBs) external onlyOwner {
        for (uint idx=0; idx<_idOnDBs.length; idx++){
            candidateLookup[proposalCount] = Proposal(proposalCount, _idOnDBs[idx], 0, block.timestamp);
            proposalCount++; 
        }
    }

    function getProposals() external view returns (string[] memory, uint[] memory, uint[] memory) {
        string[] memory IDsOnDB = new string[](proposalCount);
        uint[] memory quorumCounts = new uint[](proposalCount);
        uint[] memory createdAts = new uint[](proposalCount);
        for (uint i = 0; i < proposalCount; i++) {
            IDsOnDB[i] = candidateLookup[i].IDOnDB;
            quorumCounts[i] = candidateLookup[i].quorumCount; // on the frontend we should check the quorumCount is bigger then 5100 or not
            createdAts[i] = candidateLookup[i].createdAt;
        }
        return (IDsOnDB, quorumCounts, createdAts);
    }

    function vote(uint id) external {
        require (!voterLookup[msg.sender][id]);
        require (id >= 0 && id <= proposalCount-1);
        require (IERC20(securityTokenAddress).balanceOf(msg.sender) >= TVL_OF_SECURITY_TOKEN.mul(MIN_RATE_FOR_VOTING).div(10000));
        require( candidateLookup[id].createdAt + LIVE_TIME_OF_PROPOSAL  >= block.timestamp);

        candidateLookup[id].quorumCount =  candidateLookup[id].quorumCount.add(IERC20(securityTokenAddress).balanceOf(msg.sender).mul(MAX_QUORUM).div(TVL_OF_SECURITY_TOKEN));
        emit votedEvent(id);
    }

    event votedEvent(uint indexed id);
}

