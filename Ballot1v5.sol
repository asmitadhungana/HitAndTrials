pragma solidity ^0.5.0;

contract ElectionCreation {
    address [] public deployedBallots;
    
    function createBallot(string memory _ballotName) public {
        address newBallot = address(new Ballot(_ballotName, msg.sender));
        deployedBallots.push(newBallot);
    }
    
    function getDeployedBallots() public view returns(address[] memory) {
        return deployedBallots;
    }
}

contract Ballot{
    
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    
    struct Voter{
        string voterName;
        bool voted;
        address voterAddress;
    }
    
    mapping(address => bool) public hasVoted;
    mapping(address => bool) public isVoter;
    
    mapping (uint => bool) public isCandidate;
    
    Candidate[] public candidatesArr;
    Voter[] public votersArr;
    
    string public ballotName;
    address public manager;
    uint public candidatesCount = 0;
    uint public votersCount = 0;
    
    enum State { Created, Voting, Ended }
	State public state;
    
    constructor(string memory _ballotName, address creator) public   {
        manager = creator;               
        ballotName = _ballotName;
        
        state= State.Created;
    }
    
     modifier onlyManager(){
        require(msg.sender == manager);
        _;
    }
    
    modifier ballotState(State _state) {
		require(state == _state);
		_;
	}
    
    event voterAdded(address voter);
    event candidateAdded(uint candidateId);
    event voteStarted();
    event voteEnded();
    event voteDone(address voter);
    
    function addCandidates(string memory _name) public onlyManager {
       
        Candidate memory newCandidate = Candidate({
            id : candidatesCount ,
            name : _name,
            voteCount : 0
        });
         
        
        isCandidate[candidatesCount] = true;
        candidatesArr.push(newCandidate);
        
        emit candidateAdded(candidatesCount);
        
        candidatesCount++;
    }
    
    //manager adds voters
    function addVoter(address _voterAddress, string memory _voterName)
        public
        ballotState(State.Created)
        onlyManager
    {
        Voter memory newVoter = Voter({
            voterName : _voterName,
            voted: false,
            voterAddress: _voterAddress
        });
        
        votersArr.push(newVoter);
        isVoter[_voterAddress] = true;
        votersCount++;
        emit voterAdded(_voterAddress);
    }

 //declare voting starts now
    function startVote()
        public
        ballotState(State.Created)
        onlyManager
    {
        state = State.Voting;     
        emit voteStarted();
    }
    
    //cast votes
    function castVote(uint _candidateId)
        public
        ballotState(State.Voting)
    {
        require(isVoter[msg.sender]);  //the caller should be a registered voter
        require( !hasVoted[msg.sender]);  //caller shouldn't have voted before
        
        hasVoted[msg.sender] = true;  //mark the caller as voted
        
        candidatesArr[_candidateId].voteCount += 1;  
        
        hasVoted[msg.sender] = true;
        emit voteDone(msg.sender);
        
    }
    
    //end votes
    function endVote()
        public
        ballotState(State.Voting)
        onlyManager
    {
        state = State.Ended;
        emit voteEnded();
    }
        
}
