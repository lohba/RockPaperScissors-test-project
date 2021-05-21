pragma solidity 0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RockPaperScissors {
    using SafeMath for uint256;
    constructor() public {

    }

    uint8 constant ROCK = 0;
    uint8 constant PAPER = 1;
    uint8 constant SCISSORS = 2;

    mapping(address => uint8) public choices;

    function enter() public payable {
        require(msg.value >= getEntranceFee(), "Not enough tokens to play");
        

    }

    function getEntranceFee() public view returns (uint256) {
        

    }

    function startBattle(uint8 choice) public {
        require(choice == ROCK || choice == PAPER || choice == SCISSORS);
        
    }

    function endBattle() public {

    }

    function pickWinner() public {

    }

}