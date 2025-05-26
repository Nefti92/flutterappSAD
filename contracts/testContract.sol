// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/// @title TestDApp Smart Contract
/// @notice Demonstrates various function mutabilities, events, and image storage
contract TestDApp {
    // State variables (attributes)
    string public appName;
    uint256 public count;
    address public owner;

    // Storage for images: URIs and raw bytes
    mapping(uint256 => string) private imageURIs;
    mapping(uint256 => bytes) private images;

    // Storage for user data records
    struct DataRecord {
        address user;
        uint256 amount;
        string message;
        uint256 timestamp;
    }
    mapping(uint256 => DataRecord) private dataRecords;

    // Events
    event CountUpdated(address indexed updater, uint256 newCount);
    event ImageUploaded(uint256 indexed imageId, address indexed uploader);
    event DataStored(uint256 indexed recordId, address indexed user, uint256 amount, string message, uint256 timestamp);

    /// @notice Contract constructor sets the app name and owner
    /// @param _name The name of the DApp
    constructor(string memory _name) {
        appName = _name;
        owner = msg.sender;
        count = 0;
    }

    /// @notice Returns the app name given in constructor (view function)
    /// @return name The app name
    function getName() external view returns (string memory name) {
        return appName;
    }

    /// @notice Multiplies two numbers (pure function)
    /// @param a First operand
    /// @param b Second operand
    /// @return product The product of a and b
    function multiply(uint256 a, uint256 b) external pure returns (uint256 product) {
        return a * b;
    }

    /// @notice Returns the current count (view function)
    /// @return The stored count
    function getCount() external view returns (uint256) {
        return count;
    }

    /// @notice Increments the count by a given value (nonpayable)
    /// @param value Amount to add to count
    /// @return The new count
    function incrementCount(uint256 value) external returns (uint256) {
        count += value;
        emit CountUpdated(msg.sender, count);
        return count;
    }

    /// @notice Deposits ETH into the contract (payable)
    /// @return The contract's balance after deposit
    function deposit() external payable returns (uint256) {
        return address(this).balance;
    }

    /// @notice Stores a data record and emits an event
    /// @param recordId Identifier for the record
    /// @param user Address associated with the data
    /// @param amount Numeric data
    /// @param message Text message
    /// @return success Always true when stored
    function storeData(
        uint256 recordId,
        address user,
        uint256 amount,
        string calldata message
    ) external returns (bool success) {
        dataRecords[recordId] = DataRecord(user, amount, message, block.timestamp);
        emit DataStored(recordId, user, amount, message, block.timestamp);
        return true;
    }

    /// @notice Retrieves a stored data record (view function)
    /// @param recordId Identifier of the record
    /// @return user Address associated with the data
    /// @return amount Numeric data
    /// @return message Text message
    /// @return timestamp Time when the record was stored
    function getData(uint256 recordId)
        external
        view
        returns (
            address user,
            uint256 amount,
            string memory message,
            uint256 timestamp
        )
    {
        DataRecord storage record = dataRecords[recordId];
        return (record.user, record.amount, record.message, record.timestamp);
    }

    /// @notice Sums an array of numbers (pure with array input)
    /// @param numbers An array of uint256
    /// @return sum The total sum of all elements
    function sumArray(uint256[] memory numbers) public pure returns (uint256 sum) {
        for (uint256 i = 0; i < numbers.length; i++) {
            sum += numbers[i];
        }
        return sum;
    }

    /// @notice Uploads an image URI and emits an event
    /// @param imageId Identifier for the image
    /// @param uri The image URI (e.g., IPFS link)
    function uploadImageURI(uint256 imageId, string calldata uri) external {
        imageURIs[imageId] = uri;
        emit ImageUploaded(imageId, msg.sender);
    }

    /// @notice Retrieves a stored image URI
    /// @param imageId Identifier of the image
    /// @return The stored URI
    function getImageURI(uint256 imageId) external view returns (string memory) {
        return imageURIs[imageId];
    }

    /// @notice Uploads raw image bytes and emits an event
    /// @param imageId Identifier for the image
    /// @param data Raw image data (e.g., base64 or binary)
    function uploadImageData(uint256 imageId, bytes calldata data) external {
        images[imageId] = data;
        emit ImageUploaded(imageId, msg.sender);
    }

    /// @notice Retrieves stored raw image data
    /// @param imageId Identifier of the image
    /// @return The raw bytes of the image
    function getImageData(uint256 imageId) external view returns (bytes memory) {
        return images[imageId];
    }

    /// @notice Receive function to accept plain ETH transfers
    receive() external payable {}

    /// @notice Fallback function
    fallback() external payable {}
}
