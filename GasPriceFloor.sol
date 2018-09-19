pragma solidity ^0.4.24;

/** 
 * I had a lot of fun thinking through this.
 * Basically, this contract allows the owner of the contract to fix the minimum gas price for a period of time.
 * The owner should first fund the contract with a sufficient balance.
 * Then, the owner can set `gasPrice` and `endBlock`.
 * `killTrees()` basically burns any gas sent along with the transaction.
 * Anyone who calls `killTrees()` with a gas price equal to `gasPrice` will have their gas refunded.
 * However, this refund is *only* valid until `endBlock`.
 * Miners can therefore call `killTrees()` at any time during the period to fill the remainder of a block at the specified gas price.
 * Because miners always have the option to call `killTrees()`, other users *must* pay at least `gasPrice` to have their transactions included.
 * This ends up being an efficient way to set a price floor on gas prices.
 */

contract GasPriceFloor {
    address public owner;
    uint256 public gasPrice;
    uint256 public endBlock;

    function () public payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "Invalid sender.");
        _;
    }

    constructor () public {
        owner = msg.sender;
    }

    function setGasPrice(uint256 _newGasPrice) public onlyOwner {
        gasPrice = _newGasPrice;
    }

    function setEndBlock(uint256 _newEndBlock) public onlyOwner {
        endBlock = _newEndBlock;
    }


    function killTrees() public {
        // Check that this burn is valid.
        require(block.number < endBlock, "Invalid block number.");
        require(tx.gasprice == gasPrice, "Invalid gas price.");

        uint256 totalRefund = (gasleft() + 19000) * gasPrice; // Approximation.

        // Speed up global warming.
        while (gasleft() > 10000) {}

        // Pay the user for their contribution.
        msg.sender.transfer(totalRefund);
    }
}
