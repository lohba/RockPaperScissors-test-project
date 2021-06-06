pragma solidity 0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelinV2/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
contract RockPaperScissors  is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    IERC20 public token; 
    uint256 fee; // entrance fee
    uint256 roundId; 
    
    constructor(IERC20 _token, uint _fee) {
        token = _token;
        fee = _fee;
    }
    
    struct Round {
         address player_1;
         address player_2;
         bytes32 player_1_move_hash;
         bytes32 player_2_move_hash;
         mapping(address => Move) moves;
     }
     
     struct Move {
         bytes hashMove;
         Option finalMove;
     }
    
    //0 = ROCK 1 = PAPER 2 = SCISSORS
    enum Option{ ROCK, PAPER, SCISSORS }
    
    //maps round ids to user moves. 
    mapping(uint256 => uint8) private firstChoice;
    mapping(uint256 => address) private gameStarter;
    
    mapping(uint256 => Round) internal roundData;
    mapping(uint256 => mapping(address => bool)) hasRevealed;
    

    
    mapping(address => uint8) public choices; // keeps track of player choices
    
    struct Player {
        uint playerNumber;
    }
    
    //Create new round with id and entrance fee
    function startGame(uint256 _roundId, uint256 _fee) external {
        Round storage round = roundData[_roundId];
        require(token.balanceOf(msg.sender) >= _fee);
        token.transferFrom(msg.sender, address(this), _fee);
        round.player_1 = msg.sender;
    }
    
    //Make first move with id and hashed move
    function move(uint256 _roundId, bytes32 _hashedMove) external{
        validPlayer(_roundId, msg.sender);
        Round storage round = roundData[_roundId];
        
        if(msg.sender == round.player_1){
            round.player_1_move_hash = _hashedMove;
        } else {
            round.player_2_move_hash = _hashedMove;
        }
    }
    
    // Reveal hashed moved
    function reveal(uint256 _roundId, Option _option, uint256 _salt) external {
        require(keccak256(abi.encodePacked(_option, _salt)) == getCommit(_roundId), "incorrect hash");
        require(_option == Option.ROCK || _option == Option.PAPER || _option == Option.SCISSORS);
        
        if(msg.sender == roundData[_roundId].player_1){
            roundData[_roundId].moves[roundData[_roundId].player_1].finalMove = _option;
        } else {
            roundData[_roundId].moves[roundData[_roundId].player_2].finalMove = _option;
        }
        hasRevealed[_roundId][msg.sender] = true;
    }
    
    // Confirm both moves have been revealed 
    function confirmReveal(uint256 _roundId) internal {
        Round storage round = roundData[_roundId];
        Move storage _1 = round.moves[round.player_1]; 
        Move storage _2 = round.moves[round.player_2]; 
        (address player_1, address player_2) = (roundData[_roundId].player_1, roundData[_roundId].player_2);
        require(hasRevealed[_roundId][player_1] && hasRevealed[_roundId][player_2]);
        calculateWinner(_roundId);
    }
    
    // Calculate the winner 
    function calculateWinner(uint256 _roundId) internal {
        Round storage round = roundData[_roundId];
        (address player_1, address player_2) = (roundData[_roundId].player_1, roundData[_roundId].player_2);
        round.moves[player_1].finalMove == round.moves[player_2].finalMove ? resetGame(_roundId) : 
        
    } 
    
    // Reset Game incase of Retrieve
    function resetGame(uint256 _roundId) internal {
        Round storage round = roundData[_roundId];
        round.player_1_move_hash == "";
        round.player_2_move_hash == "";
        round.moves[player_1].finalMove == "";
        round.moves[player_2].finalMove == "";
    }
    
    // Ensure valid player has joined the game
    function validPlayer(uint256 _roundId, address _player) internal {
        Round storage round = roundData[_roundId];
        require(round.player_1 == _player || round.player_2 == _player, "not valid player");
    }
    
    // Create hash for a move
    function createHashMove(Option _option, uint256 salt) public view returns(bytes32){
        return keccak256(abi.encodePacked(_option, salt));
    }
    
    // Retrieve hash for a move
    function getCommit(uint id) public view returns(bytes32){
        return msg.sender == roundData[id].player_1 ? roundData[id].player_1_move_hash : roundData[id].player_2_move_hash;
    }
    
    //
    
    

}