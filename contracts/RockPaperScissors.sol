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
    enum Option{ NULL, ROCK, PAPER, SCISSORS }

    struct Round {
         address player_1;
         address player_2;
         bytes32 player_1_move_hash;
         bytes32 player_2_move_hash;
         Option player_1_move_reveal; // uint256 input, typecasted automatically to Option
         Option player_2_move_reveal;
         uint256 player_1_move_time;
         uint256 player_2_move_time;
         bool active;
     }
     
    // Implicit cast from uint256 to Option
    // You can't do implicit the other way, hence you'd have to uint256(Option.ROCK)
    
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
        roundData[_roundId].player_1_move_time = block.timestamp;
    }
    
    //Join round with id and entrance fee
    function join(uint256 _roundId, uint256 _fee) external {
        require(msg.sender != roundData[_roundId].player_1, "not valid player");
        require(roundData[_roundId].player_2 == address(0), "already initialized address");
        Round storage round = roundData[_roundId];
        token.safeTransferFrom(msg.sender, address(this), _fee);  
        round.player_2 = msg.sender;
        roundData[_roundId].player_2_move_time = block.timestamp;
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
        require(roundData[_roundId].player_1_move_hash == bytes32(0) && roundData[_roundId].player_2_move_hash == bytes32(0)); // check for empty move
        require(createHashMove(_option, _salt) == getCommit(_roundId), "incorrect hash");
        require(_option == Option.ROCK || _option == Option.PAPER || _option == Option.SCISSORS);
        Round storage round = roundData[_roundId];
        
        if(msg.sender == round.player_1){
            round.player_1_move_reveal = _option;
        } else {
            round.player_2_move_reveal = _option;
        }
        hasRevealed[_roundId][msg.sender] = true;
    }
    
    // Confirm both moves have been revealed 
    function _confirmReveal(uint256 _roundId) internal {
        Round storage round = roundData[_roundId];
        (address player_1, address player_2) = (round.player_1, round.player_2);
        require(hasRevealed[_roundId][player_1] && hasRevealed[_roundId][player_2]);
        roundData[roundId].active = true; //make sure round is active
        calculateWinner(_roundId);
    }
    
    // Calculate the winner 
    function _calculateWinner(uint256 _roundId) internal {
        Round storage round = roundData[_roundId];
        
        (address player_1, address player_2) = (roundData[_roundId].player_1, roundData[_roundId].player_2);
        
        // Time Out
        if(roundData[_roundId].player_1_move_time < block.timestamp - 2000 && round.player_2_move_hash != "") {
            return token.safeTransferFrom(address(this), roundData[_roundId].player_2, fee); 
        } else if (roundData[_roundId].player_2_move_time < block.timestamp - 2000 && round.player_1_move_hash != "") {
            return token.safeTransferFrom(address(this), roundData[_roundId].player_1, fee);
        } 
        
        // Compare moves
        if(round.player_1_move_reveal == round.player_2_move_reveal){
            resetGame(_roundId);
        }
        if(round.player_1_move_reveal == Option.ROCK) {
            if(round.player_2_move_reveal != Option.PAPER) {
                _winner(_roundId, player_1);
            }
            if(round.player_2_move_reveal == Option.SCISSORS) {
                _winner(_roundId, player_2);
            }
            
        if(round.player_1_move_reveal == Option.PAPER) {
             if(round.player_2_move_reveal != Option.SCISSORS){
                _winner(_roundId, player_2);
             }
             if(round.player_2_move_reveal == Option.ROCK) {
                _winner(_roundId, player_1);
            }
        }
        if(round.player_1_move_reveal == Option.SCISSORS) {
             if(round.player_2_move_reveal != Option.ROCK){
                _winner(_roundId, player_2);
             }
             if(round.player_2_move_reveal == Option.PAPER) {
                _winner(_roundId, player_1);
            }
        }
        else {
            revert("Something bad happened");
        }
    }
    } 
    
    //Winner 
    function _winner(uint256 _roundId, address player) internal {
        require(roundData[_roundId].active == true, "not active game");
        token.safeTransferFrom(address(this), player, fee*2); //transfer prize to winner
        roundData[_roundId].active == false;
    }
    
    // Reset Game incase of Retrieve
    function _resetGame(uint256 _roundId) internal {
        Round storage round = roundData[_roundId];
        round.player_1_move_hash == "";
        round.player_2_move_hash == "";
        round.player_1_move_reveal == Option.NULL;
        round.player_2_move_reveal == Option.NULL;
    }
    
    // Create hash for a move
    function createHashMove(Option _option, uint256 salt) public view returns(bytes32){
        return keccak256(abi.encodePacked(_option, salt));
    }
    
    // Retrieve hash for a move
    function getCommit(uint256 _roundId) public view returns(bytes32){
        return msg.sender == roundData[_roundId].player_1 ? roundData[_roundId].player_1_move_hash : roundData[_roundId].player_2_move_hash;
    }

}