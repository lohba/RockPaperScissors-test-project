pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelinV2/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract RockPaperScissors {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    IERC20 public token; 
    uint256 fee; // entrance fee
    uint256 roundId; 
    
    constructor(IERC20 _token, uint _fee) {
        token = _token;
        fee = _fee;
    }
    
    //0 = ROCK 1 = PAPER 2 = SCISSORS
    enum Option{ ROCK, PAPER, SCISSORS }
    
    struct Round {
         address player_1;
         address player_2;
         bytes32 player_1_move_hash;
         bytes32 player_2_move_hash;
         bytes32 player_1_move_reveal;
         bytes32 player_2_move_reveal;
         uint256 player_1_move_time;
         uint256 player_2_move_time;
     }

    
    //maps round ids to user moves. 
    mapping(uint256 => uint8) private firstChoice;
    mapping(uint256 => address) private gameStarter;
    
    mapping(uint256 => Round) internal roundData;
    mapping(uint256 => mapping(address => bool)) public hasRevealed;
    

    
    mapping(address => uint8) public choices; // keeps track of player choices
    
    // Ensure valid player has joined the game
    function _validPlayer(uint256 _roundId, address _player) internal view{
        Round storage round = roundData[_roundId];
        require(round.player_1 == _player || round.player_2 == _player, "not valid player");
    }
    
    //Create new round with id and entrance fee
    function startGame(uint256 _roundId, uint256 _fee) external {
        Round storage round = roundData[_roundId];
        token.safeTransferFrom(msg.sender, address(this), _fee);  
        round.player_1 = msg.sender;
        roundData[_roundId].layer_1_move_time = block.timestamp;
    }
    
    //Join round with id and entrance fee
    function join(uint256 _roundId, uint256 _fee) external {
        require(msg.sender != round.player_1, "not valid player");
        require(round.player_2 == address(0), "already initialized address");
        Round storage round = roundData[_roundId];
        token.safeTransferFrom(msg.sender, address(this), _fee);  
        round.player_2 = msg.sender;
        roundData[_roundId].layer_2_move_time = block.timestamp;
    }
    
    //Make first move with id and hashed move
    function move(uint256 _roundId, bytes32 _hashedMove) external {
        _validPlayer(_roundId, msg.sender);
        Round storage round = roundData[_roundId];
        
        if(msg.sender == round.player_1){
            round.player_1_move_hash = _hashedMove;
        } else {
            round.player_2_move_hash = _hashedMove;
        }
    }
    
    // Reveal hashed moved
    function reveal(uint256 _roundId, Option _option, uint256 _salt) external {
        require(round.player_1_move_hash == bytes32(0)) && (round.player_2_move_hash == bytes32(0)); // check for empty move
        require(createHashMove(_option, _salt) == getCommit(_roundId), "incorrect hash");
        require(_option == Option.ROCK || _option == Option.PAPER || _option == Option.SCISSORS);
        
        if(msg.sender == roundData[_roundId].player_1){
            roundData[_roundId].player_1_move_reveal = _option;
        } else {
            roundData[_roundId].player_2_move_reveal = _option;
        }
        hasRevealed[_roundId][msg.sender] = true;
    }
    
    // Confirm both moves have been revealed 
    function confirmReveal(uint256 _roundId) internal {
        Round storage round = roundData[_roundId];
        (address player_1, address player_2) = (roundData[_roundId].player_1, roundData[_roundId].player_2);
        require(hasRevealed[_roundId][player_1] && hasRevealed[_roundId][player_2]);
        calculateWinner(_roundId);
    }
    
    // Calculate the winner 
    function calculateWinner(uint256 _roundId) internal {
        Round storage round = roundData[_roundId];
        (address player_1, address player_2) = (roundData[_roundId].player_1, roundData[_roundId].player_2);
        if(roundData[_roundId].player_1_move_time < block.time - 2000 && round.player_2_move_hash !== "") {
            token.safeTransferFrom(address(this), roundData[_roundId].player_2, _fee); 
        } else if (roundData[_roundId].player_2_move_time < block.time - 2000 && round.player_1_move_hash !== "") {
            token.safeTransferFrom(address(this), roundData[_roundId].player_1, _fee);
        } 
        
        round.player_1_move_reveal == round.player_2_move_reveal ? resetGame(_roundId) : 
        
    } 
    
    // Reset Game incase of Retrieve
    function resetGame(uint256 _roundId) internal {
        Round storage round = roundData[_roundId];
        round.player_1_move_hash == "";
        round.player_2_move_hash == "";
        round.player_1_move_reveal == "";
        round.player_2_move_reveal == "";
    }
    
    // Create hash for a move
    function createHashMove(Option _option, uint256 salt) public view returns(bytes32){
        return keccak256(abi.encodePacked(_option, salt));
    }
    
    // Retrieve hash for a move
    function getCommit(uint256 _roundId) public view returns(bytes32){
        return msg.sender == roundData[id].player_1 ? roundData[id].player_1_move_hash : roundData[id].player_2_move_hash;
    }
    
    //
    
    

}