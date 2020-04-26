pragma solidity ^0.4.17;  //Gas fee: 0.001139

contract BallotFactory {
    address[] public deployedBallots;

    function createBallot(string memory _ballotName) public {       //Gas units: 865170
        address newBallot = address(new Ballot(_ballotName, msg.sender));
        deployedBallots.push(newBallot);
    }

    function getDeployedBallots() public view returns (address[] memory) {
        return deployedBallots;
    }
}

contract Ballot {     //Gas: 882566
    struct Vote {
        address voterAddress;
        uint256 candidateId;
    }
 
    struct Candidate {
        string candidateName;
        uint256 voteCount;
    }

    struct Voter {
        string voterName;
        bool voted;
    }

    string public ballotName;
    address public manager;
    uint256 public candidatesCount = 0;
    uint256 public votersCount = 0;
    
    mapping(uint256 => Vote) private votes;    
    mapping(address => Voter) public voterRegister;
    mapping(uint256 => Candidate) public candidateRegister;

    enum State {Created, Voting, Ended}
    State public state;

    function Ballot(string memory _ballotName, address creator) public {
        manager = creator;
        ballotName = _ballotName;

        state = State.Created;
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    modifier ballotState(State _state) {
        require(state == _state);
        _;
    }

    event voterAdded(address voter);
    event candidateAdded(uint256 candidateId);
    event voteStarted();
    event voteEnded();
    event voteDone(address voter);

    function addCandidates(string memory _name) public onlyManager {
        candidatesCount++; 
        
        Candidate memory newCandidate;
        newCandidate.candidateName= _name;
        newCandidate.voteCount= 0;

        candidateRegister[candidatesCount] = newCandidate;
        candidateAdded(candidatesCount);
    }

    //manager adds voters
    function addVoter(address _voterAddress, string memory _voterName)
        public
        ballotState(State.Created)
        onlyManager
    {
        Voter memory newVoter = Voter({
            voterName: _voterName,
            voted: false
        });
        voterRegister[_voterAddress] = newVoter;
        votersCount++;
        voterAdded(_voterAddress);
    }

    //declare voting starts now
    function startVote() public ballotState(State.Created) onlyManager {
        state = State.Voting;
        voteStarted();
    }

    //cast votes
    function castVote(uint256 _candidateId) public ballotState(State.Voting) {
        if(bytes(voterRegister[msg.sender].voterName).length != 0 &&
        !voterRegister[msg.sender].voted) {
            voterRegister[msg.sender].voted = true;
            
            Vote memory v;
            v.voterAddress = msg.sender;
            v.candidateId = _candidateId;
            
            candidateRegister[_candidateId].voteCount++;
        }
        voteDone(msg.sender);
    }

    //end votes
    function endVote() public ballotState(State.Voting) onlyManager {
        state = State.Ended;
        voteEnded();
    }
}
