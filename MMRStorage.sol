pragma solidity ^0.4.0;

contract MMRStorage {
    /*
     * Storage
     */

    uint256 public commitments;
    bytes32[32] public slots;

    
    /*
     * Constructor
     */

    constructor ()
        public
    {
        commitments = 1;
    }


    /*
     * Public functions
     */

    /**
     * @dev Commits some bytes32 data to the MMR.
     * @param _data Data to commit.
     */
    function commit(bytes32 _data)
        public
    {
        uint256 slot = _firstSetBit(commitments);
        bytes32 root = _data;
        if (_powerOfTwo(slot)) {
            root = _merklize(root, _firstSetBit(slot));
        }
        slots[slot] = root;
        commitments += 1;
    }


    /*
     * Internal functions
     */

    /**
     * @dev Finds the index of the first set bit of an integer.
     * @param _x Integer to query.
     * @return Index of the first set bit.
     */
    function _firstSetBit(uint256 _x)
        internal
        pure 
        returns (uint256 index)
    {
        for (index = 0; index < 32; index++) {
            if (_bitSet(_x, index)) {
                return index;
            }
        }
    }

    /**
     * @dev Determines whether some bit of an integer is set.
     * @param _x Integer to query.
     * @param _index Bit to check.
     * @return True if the bit is set, false otherwise.
     */
    function _bitSet(uint256 _x, uint256 _index)
        internal
        pure
        returns (bool)
    {
        return _x >> _index & 1 == 1;
    }

    /**
     * @dev Determines whether some integer is a power of two.
     * @param _x Integer to check.
     * @return True if the integer is a power of two, false otherwise.
     */
    function _powerOfTwo(uint256 _x)
        internal
        pure
        returns (bool)
    {
        return _x != 0 && (_x & (_x - 1)) == 0;
    }

    /**
     * @dev Merklizes a range, along with some data.
     * @param _data New leaf node.
     * @param _range Range of the MMR to merklize.
     * @return Root of the tree.
     */
    function _merklize(bytes32 _data, uint256 _range)
        internal
        view
        returns (bytes32)
    {
        bytes32 root = _data;
        for (uint i = 0; i <= _range; i++) {
            root = keccak256(abi.encodePacked(root, slots[i]));
        }
        return root;
    }
}
