// SPDX-License-Identifier: MIT
// 1 - Pragma statements
pragma solidity ^0.8.8;

// 2 - Import statements
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// Solidity console.log - Debugging with Hardhat Network
// Then add some console.log calls to the transfer() function in javascript
// In terminal: yarn harhat test
import "hardhat/console.sol";

// 3 - Error codes (not in soliditys style guide)
error FundMe__NotOwner();

// 4 - Interfaces (comes here if any)

// 5 - Libraries (comes here if any)

//  Doxygen-style - https://en.wikipedia.org/wiki/Doxygen
/** @title A contract for crowd funding sample
 * @author Tom Engan
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
// 6 - Contracts
contract FundMe {

    // 1 - Type declarations
    using PriceConverter for uint256;

    // 2 - State variables!
    // Variables started with s_ is storage variables
    mapping(address => uint256) private s_addressToAmountFunded; 
    address[] private s_funders;
    address private i_owner; // immutable - can't be constant
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    AggregatorV3Interface private s_priceFeed;

    // 3 - Events (comes here if any)

    // 4 - Modifiers
    modifier onlyOwner {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // 5 - Functions
    // Functions Order:
    //// 1 - constructor
    //// 2 - receive
    //// 3 - fallback
    //// 4 - external
    //// 5 - public
    //// 6 - internal
    //// 7 - private
    //// 8 - view / pure

    // 1 - constructor
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // 2 - receive
    // 4 - external
    // https://hardhat.org/tutorial/debugging-with-hardhat-network
    // Solidity console.log (debugging with Hardhat Network)
    // Remember import "hardhat/console.sol" at the top of this file
    // NOT WORKING (NOT FINISHED)! 
    // function transfer(address to, uint256 amount) external {
    //     require(balances[msg.sender] >= amount, "Not enough tokens");
    //     console.log("Transferring from %s to %s %s tokens", msg.sender, to, amount);
    //     balances[msg.sender] -= amount;
    //     balances[to] += amount;
    //     emit Transfer(msg.sender, to, amount);
    // }

    // 2 - receive
    // 4 - external
    // receive() external payable {
    //     fund();
    // }

    // 3 - fallback
    // 4 - external    
    // fallback() external payable {
    //     fund();
    // }

    /** @notice This function funds this contract
     * @dev This implements price feeds as our library
     * @ param (comes here if any)
     * @ return (comes here if any)
     */

    // 5 - public
    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }
    
    // 5 - public
    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; 
            funderIndex < s_funders.length; 
            funderIndex++
        )  {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // 6 - internal  (comes here if any)
    // 7 - private  (comes here if any)

    // 8 - view / pure
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address fundingAddress) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

}

// Explainer from: https://solidity-by-example.org/fallback/
// Ether is sent to contract
//      is msg.data empty?
//          /   \ 
//         yes  no
//         /     \
//    receive()?  fallback() 
//     /   \ 
//   yes   no
//  /        \
//receive()  fallback()