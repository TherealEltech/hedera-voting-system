// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    mapping(uint256 => Candidate) public candidates;
    mapping(bytes32 => bool) public hasVoted; // Changed: Track by NIN hash
    uint256 public candidatesCount;

    event Voted(uint256 indexed _candidateId, bytes32 indexed _ninHash);

    constructor() {
        addCandidate("Bola Ahmed Tinubu");
        addCandidate("Peter Obi");
        addCandidate("Musa Kwankwoso");
        addCandidate("Nasir El-Rufai");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint256 _candidateId, bytes32 _ninHash) public {
        require(!hasVoted[_ninHash], "You have already voted.");
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID.");

        hasVoted[_ninHash] = true;
        candidates[_candidateId].voteCount++;

        emit Voted(_candidateId, _ninHash);
    }
    
    function checkIfVoted(bytes32 _ninHash) public view returns (bool) {
        return hasVoted[_ninHash];
    }
}