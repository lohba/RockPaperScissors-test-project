pragma solidity 0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelinV2/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
contract RockPaperScissors  is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    IERC20 public token; 
    uint fee; // entrance fee
    
    constructor(IERC20 _token, uint _fee) {
        token = _token;
        fee = _fee;
    }
    
    struct Round {
         address alice;
         address bob;
         mapping(address => uint256) moves;
     }
    
    
    //maps round ids to user moves. 
    mapping(uint256 => uint8) private firstChoice;
    mapping(uint256 => address) private gameStarter;
    mapping(uint256 => Round) internal roundData;
    
    //0 = ROCK 1 = PAPER 2 = SCISSORS
    enum RockPaperScissors{ ROCK, PAPER, SCISSORS }
    
    mapping(address => uint8) public choices; // keeps track of player choices
    
    struct Player {
        uint playerNumber;
    }
    
    //Create new round with id and entrance fee
    function createRound(uint256 _roundId, uint256 _fee) external {
        Round storage round = roundData[_roundId];
    }
    
    function releaseFunds() public onlyOwner {
        
    }
    
    
    function startGame(uint8 choice) public {
        //require(choice == ROCK || choice == PAPER || choice == SCISSORS);
        require(choices[msg.sender] == 0);
        choices[msg.sender] = choice;
    }
}