// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Vote {
    address public owner;
    uint public endTime;
    uint public totalDonations = 0;
    bool public hasSentFunds;

    struct PossibleWinner {
        uint count;
        uint index;
    }

    struct Candidate {
        string name;
        uint voteCount;
        address payable candidateAddress;
    }

    Candidate[] public  candidates;
    PossibleWinner possibleWinner;

    mapping (address => bool) public hasVotedList;

    event VotingEnded(string winner);

    constructor(uint periodInMinutes) {
        owner = msg.sender;
        endTime = block.timestamp + periodInMinutes * 1 minutes;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "only owner can create candidates");
        _;
    }

    modifier notVoted {
        require(!hasVotedList[msg.sender], "You have already voted");
        _;
    }

    modifier votingOpen {
        require(block.timestamp < endTime, "Voting has ended");
        _;
    }

    modifier votingClose {
        require(block.timestamp >= endTime, "Voting has not ended");
        _;
    }

    modifier notPaid {
        require(!hasSentFunds, "Already send");
        _;
    }

    function addCandidates(string memory _name, address payable _address) public onlyOwner {
        candidates.push(Candidate(_name,0, _address));
    }

    function sendVote(uint index) public payable notVoted votingOpen {
        require(index < candidates.length, "Not valid index");
        require(msg.value > 0, "Invalid donation count");
        hasVotedList[msg.sender] = true;
        candidates[index].voteCount+= msg.value;
        totalDonations+=msg.value;

        if (candidates[index].voteCount > possibleWinner.count) {
            possibleWinner = PossibleWinner(candidates[index].voteCount, index);
        }
    }

    function getCandidates() public view returns (Candidate[] memory)  {
        return candidates;
    }

    function getWinner () internal view votingClose returns (Candidate memory) {
        require(candidates.length > 0, "Candidates is empty");
        require(possibleWinner.count > 0, "No winner") ;
        return candidates[possibleWinner.index];
    }

    function endVoting () external votingClose {
        Candidate memory winner = getWinner();
        emit VotingEnded(winner.name);
        sendDonation(winner.candidateAddress, totalDonations);
    }

    function sendDonation (address payable _address, uint _count) internal notPaid {
        require(address(this).balance >= _count, "Insufficient balance to transfer funds");
        _address.transfer(_count);
        hasSentFunds = true;
        totalDonations = 0;
    }
}