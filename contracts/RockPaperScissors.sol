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
         bytes32 payer_1_move_hash;
         bytes32 payer_2_move_hash;
         mapping(address => Move) moves;
     }
     
     struct Move {
         bytes hashMove;
         uint256 finalMove;
     }
    
    
    //maps round ids to user moves. 
    mapping(uint256 => uint8) private firstChoice;
    mapping(uint256 => address) private gameStarter;
    mapping(uint256 => Round) internal roundData;
    
    //0 = ROCK 1 = PAPER 2 = SCISSORS
    enum Option{ ROCK, PAPER, SCISSORS }
    
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
    
    //Make first move with id and move
    function move(uint256 _roundId, uint256 _move) external{
        validPlayer(_roundId, msg.sender);
        Move storage move = roundData[_roundId].moves[msg.sender];
        move.finalMove = _move;
    }
    
    // Ensure valid player has joined the game
    function validPlayer(uint256 _roundId, address _player) internal {
        Round storage round = roundData[_roundId];
        require(round.player_1 == _player || round.player_2 == _player, "not valid player");
    }
    
    function joinGame() public onlyOwner {
        
    }
    
    

}