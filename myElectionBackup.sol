pragma solidity ^0.4.17;


contract BallotFactory {
    //Gas: 1369595
    address[] public deployedBallots;

    function createBallot(string memory _ballotName) public {
        //Gas: 1075954
        address newBallot = address(new Ballot(_ballotName, msg.sender));
        deployedBallots.push(newBallot);
    }

    function getDeployedBallots() public view returns (address[] memory) {
        return deployedBallots;
    }

    function getLength() public view returns (uint256) {
        return deployedBallots.length;
    }
}


contract Ballot {
    //Gas: 1109509
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    struct Voter {
        string voterName;
        bool voted;
        address voterAddress;
    }

    mapping(address => bool) public hasVoted;
    mapping(address => bool) public isVoter;

    mapping(uint256 => bool) public isCandidate;

    Candidate[] public candidatesArr;
    Voter[] public votersArr;

    string public ballotName;
    address public manager;
    uint256 public candidatesCount;
    uint256 public votersCount;

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
        Candidate memory newCandidate = Candidate({
            id: candidatesCount,
            name: _name,
            voteCount: 0
        });

        isCandidate[candidatesCount] = true;
        candidatesArr.push(newCandidate);

        candidateAdded(candidatesCount);

        candidatesCount++;
    }

    //manager adds voters
    function addVoter(address _voterAddress, string memory _voterName)
        public
        ballotState(State.Created)
        onlyManager
    {
        Voter memory newVoter = Voter({
            voterName: _voterName,
            voted: false,
            voterAddress: _voterAddress
        });

        votersArr.push(newVoter);
        isVoter[_voterAddress] = true;
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
        require(isVoter[msg.sender]); //the caller should be a registered voter
        require(!hasVoted[msg.sender]); //caller shouldn't have voted before

        hasVoted[msg.sender] = true; //mark the caller as voted

        candidatesArr[_candidateId].voteCount += 1;

        hasVoted[msg.sender] = true;

        voteDone(msg.sender);
    }

    //end votes
    function endVote() public ballotState(State.Voting) onlyManager {
        state = State.Ended;

        voteEnded();
    }
}
