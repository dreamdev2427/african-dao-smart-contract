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
        uint voteCount;
        uint createdAt;
    }

    uint public proposalCount;
    uint public minRateForVoting = 100; //0.01 percent
    uint public proposalLiveTime = 7 * 3600 * 24;
    uint public TVLofSecurityToken;
    address public securityTokenAddress = 0x2c77D3161533129cA2c8745B6e4ED345c3EDf96d;

    constructor(address _securityTokenAddr, uint _minRate, uint _proposalLT, uint _tvl)
    {
        securityTokenAddress = _securityTokenAddr;
        minRateForVoting = _minRate;
        proposalLiveTime = _proposalLT; //time unit is second
        TVLofSecurityToken = _tvl;
    }

    mapping(address => mapping(uint => bool)) public voterLookup;
    mapping(uint => Proposal) public candidateLookup;

    function setTVLofSecurityToken(uint _tvl)  external onlyOwner {
        TVLofSecurityToken = _tvl;
    }

    function setSecurityTokenAddress(address _addr)  external onlyOwner {
        securityTokenAddress = _addr;
    }

    function setMinTokenForVoting(uint _minRate)  external onlyOwner {
        minRateForVoting = _minRate;
    }

    function addProposals(string[] memory _idOnDBs) external onlyOwner {
        for (uint idx=0; idx<_idOnDBs.length; idx++){
            candidateLookup[proposalCount] = Proposal(proposalCount, _idOnDBs[idx], 0, block.timestamp);
            proposalCount++; 
        }
    }

    function getProposals() external view returns (string[] memory, uint[] memory, uint[] memory) {
        string[] memory IDsOnDB = new string[](proposalCount);
        uint[] memory voteCounts = new uint[](proposalCount);
        uint[] memory createdAts = new uint[](proposalCount);
        for (uint i = 0; i < proposalCount; i++) {
            IDsOnDB[i] = candidateLookup[i].IDOnDB;
            voteCounts[i] = candidateLookup[i].voteCount;
            createdAts[i] = candidateLookup[i].createdAt;
        }
        return (IDsOnDB, voteCounts, createdAts);
    }

    function vote(uint id) external {
        require (!voterLookup[msg.sender][id]);
        require (id >= 0 && id <= proposalCount-1);
        require (IERC20(securityTokenAddress).balanceOf(msg.sender) >= TVLofSecurityToken.mul(minRateForVoting).div(10000));
        require( candidateLookup[id].createdAt + proposalLiveTime  >= block.timestamp);

        candidateLookup[id].voteCount++;
        emit votedEvent(id);
    }

    event votedEvent(uint indexed id);
}