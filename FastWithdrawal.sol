pragma solidity ^0.4.0;

import "./PlasmaCore.sol";
import "./RootChain.sol";

contract FastWithdrawal {
    using PlasmaCore for bytes;


    /*
     * Storage
     */

    mapping (address => mapping (uint256 => ExitToken)) public exits;

    struct ExitToken {
        address owner;
        uint256 price;
        bool buyable;
    }


    /*
     * Events
     */

    event ExitTokenCreated(
        address indexed plasmaAddress,
        address indexed owner,
        uint256 amount
    );


    /*
     * Public functions
     */

    /**
     * @dev Starts a fast exit by proxying through this contract. Requires that the sender prove they sent the funds.
     * @param _plasmaAddress Address of the Plasma contract to withdraw from.
     * @param _inputId ID of the input UTXO.
     * @param _inputTx RLP encoded transaction that created the input.
     * @param _inputTxInclusionProof Proof that the transaction was included.
     * @param _outputIndex Which output in the input transaction was spent.
     * @param _outputId ID of the output transaction.
     * @param _outputTx RLP encoded transaction that created the output to this contract.
     * @param _outputTxInclusionProof Proof that the transaction was included.
     * @param _price Price at which this exit can be bought.
     */
    function startFastExit(
        address _plasmaAddress,
        uint256 _inputId,
        bytes _inputTx,
        bytes _inputTxInclusionProof,
        uint256 _outputIndex,
        uint256 _outputId,
        bytes _outputTx,
        bytes _outputTxInclusionProof,
        uint256 _price
    )
        public
        payable
    {
        RootChain rootChain = RootChain(_plasmaAddress);

        // Verify the owner of this exit.
        require(_outputTx.getInputId(0) == _inputId);
        require(rootChain.transactionIncluded(_inputTx, _inputId, _inputTxInclusionProof));
        require(_inputTx.getOutput(_outputIndex).owner == msg.sender);

        // Start the exit.
        rootChain.startExit.value(msg.value)(_outputId, _outputTx, _outputTxInclusionProof);

        // Update the mapping.
        uint256 amount;
        (, amount) = rootChain.exits(_outputId);
        exits[_plasmaAddress][_outputId] = ExitToken({
            owner: msg.sender,
            price: _price,
            buyable: true
        });

        emit ExitTokenCreated(_plasmaAddress, msg.sender, amount);
    }

    /**
     * @dev Allows a user to buy an exit.
     * @param _plasmaAddress Address of the Plasma contract containing this exit.
     * @param _outputId Identifier of the output being purchased.
     */
    function buyExit(
        address _plasmaAddress,
        uint256 _outputId
    )
        public
        payable
    {
        ExitToken storage exitToken = exits[_plasmaAddress][_outputId];

        // Validate the purchase.
        require(exitToken.buyable);
        require(msg.value == exitToken.price);

        // Send the money.
        exitToken.owner.transfer(msg.value);

        // Update the token info.
        exitToken.owner = msg.sender;
        exitToken.buyable = false;
    }

    /**
     * @dev Fallback is used to send out funds to the owner of the given exit.
     */
    function ()
        public
        payable
    {
        uint256 outputId = _bytesToUint256(msg.data);
        ExitToken storage exitToken = exits[msg.sender][outputId];
        if (exitToken.owner != address(0)) {
            exitToken.owner.send(msg.value);
        }
        delete exitToken.owner;
    }


    /*
     * Internal functions
     */

    /**
     * @dev Converts bytes to uint256, assumes 32 bytes long.
     * @param _b Bytes to convert to uint256.
     * @return Converted uint256.
     */
    function _bytesToUint256(bytes _b)
        internal
        pure
        returns (uint256)
    {
        uint256 x;
        assembly {
            x := mload(add(_b, 32))
        }
        return x;
    }
}
