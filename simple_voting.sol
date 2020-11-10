// Programmer: Dr. Mohd Anuar Mat Isa, iExplotech & IPTM Secretariat
// Project: Simple Voting
// Website: https://github.com/iexplotech  http://blockscout.iexplotech.com, www.iexplotech.com
// License: GPL3

pragma solidity 0.5.12;

contract voting {
    
    uint256 private totalVotes;
    uint256 private timeStart;
    uint256 private timeEnd;
    
    struct voter {
        string name;
        uint128 memberIC;
        uint128 memberID;
        bool voteCasted;  // true = summited vote, false = not submit yet.
    }
    
    struct candidate {
        string name;
        uint128 memberIC;
        uint128 memberID;
        uint256 candidateTotalVotes;
    }
    
    mapping (address => voter) private myVoter;
    mapping (address => candidate) private myCandidate;
    
    modifier timeLimit {
        if(now >= timeStart && now <=timeEnd) {
            _;
        } else
            revert("Time Out... No Voting");
    }
    
    constructor () public {
        totalVotes = 0;
        setAllVoters ();
        setAllCandidates ();
        timeStart = now;
        timeEnd = timeStart + 60;
    }
    
    function getVotingTime() public view returns (uint256 start, uint256 end, uint256 time) {
        return(timeStart, timeEnd, now); 
    }
    
    function addVoter(string newName, uint128 newMemberIC, uint128 newMemberID)
        public {
        myVoter[msg.sender].name = newName;
        myVoter[msg.sender].memberIC = newMemberIC;
        myVoter[msg.sender].memberID = newMemberID;
        myVoter[msg.sender].voteCasted = false;
    }
    
    function addCandidate(string newName, uint128 newMemberIC, uint128 newMemberID)
        public {
        myCandidate[msg.sender].name = newName;
        myCandidate[msg.sender].memberIC = newMemberIC;
        myCandidate[msg.sender].memberID = newMemberID;
        myCandidate[msg.sender].candidateTotalVotes = 0;
    }
        
    function setVote() public {
  
        if(myVoter[msg.sender].voteCasted == false){
            totalVotes = totalVotes + 1;
            myVoter[msg.sender].voteCasted = true;
        }
       
    }
        
    function getTotalVotes() public view returns (uint256) {
        return totalVotes;
    }
    
    function getTotalCandidateVotes() public view returns (uint256, uint256) {
        return (myCandidate[0xca35b7d915458ef540ade6068dfe2f44e8fa733c].
                    candidateTotalVotes, myCandidate[0x14723a09acff6d2a60dcdf7aa4aff308fddc160c].
                    candidateTotalVotes);
    }
    
    
    // debug functions
    function setVoter(address newAddress, string newName, uint128 newMemberIC, 
        uint128 newMemberID) public {
        myVoter[newAddress].name = newName;
        myVoter[newAddress].memberIC = newMemberIC;
        myVoter[newAddress].memberID = newMemberID;
        myVoter[newAddress].voteCasted = false;
    }
    
    function setAllVoters () public {
        setVoter(0xca35b7d915458ef540ade6068dfe2f44e8fa733c, "V1", 11, 11); // voter 1
        setVoter(0x14723a09acff6d2a60dcdf7aa4aff308fddc160c, "V2", 22, 22); // voter 2
        setVoter(0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db, "V3", 33, 33); // voter 3
        setVoter(0x583031d1113ad414f02576bd6afabfb302140225, "V4", 44, 44); // voter 4
        setVoter(0xdd870fa1b7c4700f2bd7f44238821c26f7392148, "V5", 55, 55); // voter 5
    }
    
    function addCandidate(address newAddress, string newName, uint128 newMemberIC, uint128 newMemberID)
        public {
        myCandidate[newAddress].name = newName;
        myCandidate[newAddress].memberIC = newMemberIC;
        myCandidate[newAddress].memberID = newMemberID;
        myCandidate[newAddress].candidateTotalVotes = 0;
    }
    
    function setAllCandidates () public {
        addCandidate(0xca35b7d915458ef540ade6068dfe2f44e8fa733c, "Anuar", 11, 11); // Candidate 1
        addCandidate(0x14723a09acff6d2a60dcdf7aa4aff308fddc160c, "Anwar", 22, 22); // Candidate 2
    }
    
    function chooseFirstCandidate() public timeLimit {
        if(myVoter[msg.sender].voteCasted == false){
            totalVotes = totalVotes + 1;
            myCandidate[0xca35b7d915458ef540ade6068dfe2f44e8fa733c].
                    candidateTotalVotes = 
                    myCandidate[0xca35b7d915458ef540ade6068dfe2f44e8fa733c].
                    candidateTotalVotes + 1;
            myVoter[msg.sender].voteCasted = true;
        }
    }
    
    function chooseSecondCandidate() public timeLimit {
        if(myVoter[msg.sender].voteCasted == false){
            totalVotes = totalVotes + 1;
            myCandidate[0x14723a09acff6d2a60dcdf7aa4aff308fddc160c].
                    candidateTotalVotes = 
                    myCandidate[0x14723a09acff6d2a60dcdf7aa4aff308fddc160c].
                    candidateTotalVotes + 1;
            myVoter[msg.sender].voteCasted = true;
        }
    }
}