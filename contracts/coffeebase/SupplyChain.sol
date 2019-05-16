pragma solidity ^0.5.0;

import "../coffeeaccesscontrol/FarmerRole.sol";
import "../coffeeaccesscontrol/DistributorRole.sol";
import "../coffeeaccesscontrol/RetailerRole.sol";
import "../coffeeaccesscontrol/ConsumerRole.sol";

// Define a contract 'Supplychain'
contract SupplyChain is  FarmerRole, DistributorRole, RetailerRole, ConsumerRole {

  // Define 'owner'
  address private owner;

  // Define a variable called 'upc' for Universal Product Code (UPC)
  uint upc;

  // Define a variable called 'sku' for Stock Keeping Unit (SKU)
  uint sku;

  // Define a public mapping 'items' that maps the UPC to an Item.
  mapping (uint => Item) items;

  // Define a public mapping 'itemsHistory' that maps the UPC to an array of TxHash,
  // that track its journey through the supply chain -- to be sent from DApp.
  mapping (uint => string[]) itemsHistory;

  // Define enum 'State' with the following values:
  enum State
  {
    Harvested,  // 0
    Processed,  // 1
    Packed,     // 2
    ForSale,    // 3
    Sold,       // 4
    Shipped,    // 5
    Received,   // 6
    Purchased   // 7
  }

  State constant defaultState = State.Harvested;

  // Define a struct 'Item' with the following fields:
  struct Item {
    uint    sku;  // Stock Keeping Unit (SKU)
    uint    upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
    address ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
    address payable originFarmerID; // Metamask-Ethereum address of the Farmer
    string  originFarmName; // Farmer Name
    string  originFarmInformation;  // Farmer Information
    string  originFarmLatitude; // Farm Latitude
    string  originFarmLongitude;  // Farm Longitude
    uint    productID;  // Product ID potentially a combination of upc + sku
    string  productNotes; // Product Notes
    uint    productPrice; // Product Price
    State   itemState;  // Product State as represented in the enum above
    address distributorID;  // Metamask-Ethereum address of the Distributor
    address retailerID; // Metamask-Ethereum address of the Retailer
    address consumerID; // Metamask-Ethereum address of the Consumer
  }

  // events
  event TransferDAppOwnership(address indexed oldOwner, address indexed newOwner);
  event FarmerAdded(address indexed account);
  event DistributorAdded(address indexed account);
  event RetailerAdded(address indexed account);
  event ConsumerAdded(address indexed account);

  // Define 8 events with the same 8 state values and accept 'upc' as input argument
  event Harvested(uint upc);
  event Processed(uint upc);
  event Packed(uint upc);
  event ForSale(uint upc);
  event Sold(uint upc);
  event Shipped(uint upc);
  event Received(uint upc);
  event Purchased(uint upc);

  // Define a modifer that checks to see if msg.sender == owner of the contract
  modifier onlyOwner() {
    require(msg.sender == owner, "Not the owner!");
    _;
  }

   modifier onlyFarmer() {
        require(isFarmer(msg.sender), "Not a Farmer!");
        _;
  }

  modifier onlyDistributor() {
        require(isDistributor(msg.sender), "Not a Distributor");
        _;
  }

  modifier onlyRetailer() {
        require(isRetailer(msg.sender), "Not a Retailer");
        _;
  }

  modifier onlyConsumer() {
        require(isConsumer(msg.sender), "Not a Consumer!");
        _;
  }

  // Define a modifer that verifies the Caller
  modifier verifyCaller (address _address) {
    require(msg.sender == _address, "Caller not verified.");
    _;
  }

  // Define a modifier that checks if the paid amount is sufficient to cover the price
  modifier paidEnough(uint _price) {
    require(msg.value >= _price, "Paid amount is insufficient!");
    _;
  }

  // Define a modifier that checks the price and refunds the remaining balance
  modifier checkValue(uint _upc) {
    _;
    uint _price = items[_upc].productPrice;
    uint amountToReturn = msg.value - _price;
    msg.sender.transfer(amountToReturn);
  }

  // Define a modifier that checks if an item.state of a upc is Harvested
  modifier harvested(uint _upc) {
    require(items[_upc].itemState == State.Harvested, "Not yet harvested!");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Processed
  modifier processed(uint _upc) {
    require(items[_upc].itemState == State.Processed, "Not processed yet!");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Packed
  modifier packed(uint _upc) {
    require(items[_upc].itemState == State.Packed, "Not packed!");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is ForSale
  modifier forSale(uint _upc) {
    require(items[_upc].itemState == State.ForSale, "Not ForSale!");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Sold
  modifier sold(uint _upc) {
    require(items[_upc].itemState == State.Sold, "Not sold!");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Shipped
  modifier shipped(uint _upc) {
    require(items[_upc].itemState == State.Shipped, "Not shipped");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Received
  modifier received(uint _upc) {
    require(items[_upc].itemState == State.Received, "Not received!");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Purchased
  modifier purchased(uint _upc) {
    require(items[_upc].itemState == State.Purchased, "Not purchaes!");
    _;
  }

  // In the constructor set 'owner' to the address that instantiated the contract
  // and set 'sku' to 1
  // and set 'upc' to 1
  constructor() public payable {
    owner = msg.sender;
    sku = 1;
    upc = 1;
  }

  // Define a function for transferring the DApp ownership
  function transferDAppOwnership(address newOwner) public onlyOwner {
      require(newOwner != address(0), "Cannot transfer to address(0)");
      emit TransferDAppOwnership(owner, newOwner);
      owner = newOwner;
  }

  // Functions for adding Farmers, Distributors, Retailers, and Consumers roles
  function addFarmerRole(address account) public onlyOwner {
    _addFarmer(account);
    emit FarmerAdded(account);
  }

  function addDistributorRole(address account) public onlyOwner {
    _addDistributor(account);
    emit DistributorAdded(account);
  }

  function addRetailerRole(address account) public onlyOwner {
    _addRetailer(account);
    emit RetailerAdded(account);
  }

  function addConsumerRole(address account) public onlyOwner {
    _addConsumer(account);
    emit ConsumerAdded(account);
  }

  // Define a function 'kill' if required
  function kill() public {
    if (msg.sender == owner) {
      selfdestruct(msg.sender);
    }
  }

  // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
  function harvestItem(
    uint _upc,
    address payable _originFarmerID,
    string memory _originFarmName,
    string memory _originFarmInformation,
    string memory _originFarmLatitude,
    string memory _originFarmLongitude,
    string memory _productNotes) public
    //Only Farmers can call this function
    onlyFarmer
  {
    // Add the new item as part of Harvest
    items[_upc] = Item({
      sku: sku,
      upc: _upc,
      ownerID: _originFarmerID,
      originFarmerID: _originFarmerID,
      originFarmName: _originFarmName,
      originFarmInformation: _originFarmInformation,
      originFarmLatitude: _originFarmLatitude,
      originFarmLongitude: _originFarmLongitude,
      productID: _upc + sku,
      productNotes: _productNotes,
      productPrice: 0,
      itemState: State.Harvested,
      distributorID: address(0),
      retailerID: address(0),
      consumerID: address(0)
    });
    // Increment sku
    sku = sku + 1;
    // Emit the appropriate event
    emit Harvested(_upc);
  }

  // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
  function processItem(uint _upc) public
  //Only Farmers can call this function
    onlyFarmer
  // Call modifier to check if upc has passed previous supply chain stage
    harvested(_upc)
  // Call modifier to verify caller of this function
    verifyCaller (items[_upc].originFarmerID)
  {
    // Update the appropriate fields
    items[_upc].itemState = State.Processed;
    // Emit the appropriate event
    emit Processed(_upc);
  }

  // Define a function 'packItem' that allows a farmer to mark an item 'Packed'
  function packItem(uint _upc) public
  //Only Farmers can call this function
    onlyFarmer
  // Call modifier to check if upc has passed previous supply chain stage
    processed(_upc)
  // Call modifier to verify caller of this function
    verifyCaller (items[_upc].originFarmerID)
  {
    // Update the appropriate fields
    items[_upc].itemState = State.Packed;
    // Emit the appropriate event
    emit Packed(_upc);
  }

  // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
  function sellItem(uint _upc, uint _price) public
  //Only Farmers can call this function
    onlyFarmer
  // Call modifier to check if upc has passed previous supply chain stage
    packed( _upc)
  // Call modifier to verify caller of this function
    verifyCaller (items[_upc].originFarmerID)
  {
    // Update the appropriate fields
    items[_upc].productPrice = _price;
    items[_upc].itemState = State.ForSale;

    // Emit the appropriate event
    emit ForSale(_upc);
  }

  // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
  // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough,
  // and any excess ether sent is refunded back to the buyer
  function buyItem(uint _upc) public payable
    // Only Distributors can call this function
    onlyDistributor
    // Call modifier to check if upc has passed previous supply chain stage
      forSale(_upc)
    // Call modifer to check if buyer has paid enough
      paidEnough(items[_upc].productPrice)
    // Call modifer to send any excess ether back to buyer
      checkValue(_upc)
    {
    // Update the appropriate fields - ownerID, distributorID, itemState
      items[_upc].ownerID = msg.sender;
      items[_upc].distributorID = msg.sender;
      items[_upc].itemState = State.Sold;
    // Transfer money to farmer
      items[_upc].originFarmerID.transfer(items[_upc].productPrice);
    // emit the appropriate event
      emit Sold(_upc);
  }

  // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
  // Use the above modifers to check if the item is sold
  function shipItem(uint _upc) public
    // Only Distributors can call this function
      onlyDistributor
    // Call modifier to check if upc has passed previous supply chain stage
      sold( _upc)
    // Call modifier to verify caller of this function
      verifyCaller (items[_upc].distributorID)
    {
    // Update the appropriate fields
      items[_upc].itemState = State.Shipped;
    // Emit the appropriate event
      emit Shipped(_upc);
  }

  // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
  // Use the above modifiers to check if the item is shipped
  function receiveItem(uint _upc) public
    // Call modifier to check if upc has passed previous supply chain stage
    shipped( _upc)
    // Access Control List enforced by calling Smart Contract / DApp
    onlyRetailer
    {
      address retailerAddress = msg.sender;
    // Update the appropriate fields - ownerID, retailerID, itemState
      items[_upc].ownerID = retailerAddress;
      items[_upc].retailerID = retailerAddress;
      items[_upc].itemState = State.Received;
    // Emit the appropriate event
      emit Received(_upc);
  }

  // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
  // Use the above modifiers to check if the item is received
  function purchaseItem(uint _upc) public payable
    // Call modifier to check if upc has passed previous supply chain stage
    received( _upc)
    // Access Control List enforced by calling Smart Contract / DApp
    onlyConsumer
    {
    // Update the appropriate fields - ownerID, consumerID, itemState
      items[_upc].ownerID = msg.sender;
      items[_upc].consumerID = msg.sender;
      items[_upc].itemState = State.Purchased;
    // Emit the appropriate event
      emit Purchased(_upc);
  }


  // Define a function 'fetchItemBufferOne' that fetches the data
  function fetchItemBufferOne(uint _upc) public view returns
  (
  uint    itemSKU,
  uint    itemUPC,
  address ownerID,
  address originFarmerID,
  string  memory originFarmName,
  string  memory originFarmInformation,
  string  memory originFarmLatitude,
  string  memory originFarmLongitude
  )
  {
  // Assign values to the 8 parameters
  itemSKU = items[_upc].sku;
  itemUPC = items[_upc].upc;
  ownerID = items[_upc].ownerID;
  originFarmerID = items[_upc].originFarmerID;
  originFarmName = items[_upc].originFarmName;
  originFarmInformation = items[_upc].originFarmInformation;
  originFarmLatitude = items[_upc].originFarmLatitude;
  originFarmLongitude = items[_upc].originFarmLongitude;
  }

  // Define a function 'fetchItemBufferTwo' that fetches the data
  function fetchItemBufferTwo(uint _upc) public view returns
  (
  uint    itemSKU,
  uint    itemUPC,
  uint    productID,
  string  memory productNotes,
  uint    productPrice,
  uint    itemState,
  address distributorID,
  address retailerID,
  address consumerID
  )
  {
    // Assign values to the 9 parameters
  itemSKU = items[_upc].sku;
  itemUPC = items[_upc].upc;
  productID = items[_upc].productID;
  productNotes = items[_upc].productNotes;
  productPrice = items[_upc].productPrice;
  itemState = uint(items[_upc].itemState);
  distributorID = items[_upc].distributorID;
  retailerID = items[_upc].retailerID;
  consumerID = items[_upc].consumerID;
  }
 }
