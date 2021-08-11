# Decentralize-Auction-Market

## Description
<p>How Decentralize Auction Market Works</p>
<ol>
  <li>User need to register with require data (Name, Residence Address, Mail Address, Phone Number) to use all Smart Contract function</li>
  <li>Seller will input product data to blockchain (ProductName, Price, BidTime)</li>
  <li>Buyer can bid the product during BidTime</li>
  <li>When bidding, Buyer will transfer amount of wei to smart contract to prevent spam and buyer will paid back if someone bid higher</li>
  <li>If BidTime reached without any bid, Seller can re-Auction the same product</li>
  <li>When BidTime reached, Seller can finalize the auction to send the product</li>
  <li>If seller not finalize within 7 days after bidUntil, the Auction winner can request to refund</li>
  <li>When product delivered to the Auction winner, the winner can confirm and seller receive the payment from Smart Contract with 1% fee</li>
  <li>The product data will owned by the Auction winner and can open new auction of same product</li>
</ol>

## Program Flow
### Flow of Decentralize Auction Market
![gambar](https://user-images.githubusercontent.com/17853143/128887269-0c3d7c76-d68e-4e31-96c9-774dff77fb2e.png)

## Main Data Structure
### Structure used on smart contract
This Smart Contract uses 2 structures with mapping as shown below
<pre><code>
  struct Account{
        string fullName; 
        string residenceAddress;
        string mailAddress;
        string phoneNumber;
        uint[] productList; //this array consist productID owned by user
        bool registered; //true if user registered
    }
    
    struct Item{
        address ownerAddress; //represent current address of product owner
        uint indexOnProductList; //store index of productList on Account struct
        uint indexOnItemsIndex; //if auction status=0 store soldItemsIndex array, else store auctionItemsIndex array
        string productName;
        uint price; //price in wei
        uint time; //store auction start time in unixtime
        uint bidUntil; //store when auction end in unixtime
        address highestBidder; //address of current highest bidder
        uint highestPrice; //current highest bid price
        uint auctionStatus; //0=sold or failed, 1=on auction, 2=goods on process for delivery
    }

    mapping(address => Account) public accountsData;
    mapping(uint => Item) public itemsData;
</pre></code>
Besides that, arrays are also used to find specific data to avoid the use of looping
<pre><code>
    address[] accountsIndex; //store all user address
    uint[] soldItemsIndex; //store all sold product
    uint[] auctionItemsIndex; //store all auction product
</pre></code>

## Function
### Function that will use on smart contract
<ol>
  <li>registerUser</li>
<pre><code>
    /**
     * @dev register user with the required data
     * @param fullName,residenceAddress,mailAddress,phoneNumber
     */
    function registerUser(string memory fullName, string memory residenceAddress, string memory mailAddress, string memory phoneNumber)external isRegistered(false){...}
</pre></code>
  <li>registerItems</li>
<pre><code>
    /**
     * @dev register item with the required data
     * @param productName,price,bidUntil
     * @return generated productID
     */
    function registerItems(string memory productName, uint price, uint bidUntil)external isRegistered(true) returns(uint){...}
</pre></code>
    <li>bid</li>
<pre><code>
    /**
     * @dev bid auction product 
     * @param productID that want to bid
     */
    function bid(uint productID)external payable isRegistered(true) isProductOwner(productID,false) onAuction(productID) {...}
</pre></code>
    <li>finalizeAuction</li>
<pre><code>
    /**
     * @dev seller must finalize the auction after bidTime reached to proceed auction status
     * @param productID that want to finalize
     */
    function finalizeAuction(uint productID)external isProductOwner(productID,true) onAuction(productID){...}
</pre></code>
    <li>confirm</li>
<pre><code>
    /**
     * @dev Auction must confirm after the product arrive
     * @param productID that want to confirm
     */
    function confirm(uint productID)external payable isRegistered(true) isProductOwner(productID,false) isHighestBidder(productID){...}
</pre></code>
    <li>askRefund</li>
<pre><code>
    /**
     * @dev Auction Winner can ask for refund if seller not finalize the auction
     * @param productID that want to be refund
     */
    function askRefund(uint productID)external payable isRegistered(true) isProductOwner(productID,false) isHighestBidder(productID) onAuction(productID){...}
</pre></code>
    <li>reAuction</li>
<pre><code>
    /**
     * @dev seller can call this function if previous auction failed and Auction Winner can call this function to resell product
     * @param productID, price, bidUntil 
     */
    function reAuction(uint productID, uint price, uint bidUntil) external isProductOwner(productID,true){...}
</pre></code>
    <li>accountsData (Public Variable)</li>
<pre><code>
    mapping(address => Account) public accountsData;
</pre></code>
    <li>itemsData (Public Variable)</li>
<pre><code>
    mapping(uint => Item) public itemsData;
</pre></code>
<li>viewAllAuctionProductID</li>
<pre><code>
    /**
     * @dev Return all on auction productID
     * @return all productID on auction
     */
    function viewAllAuctionProductID() external view returns(uint[] memory){...}
</pre></code>
<li>viewAllProductID</li>
<pre><code>
    /**
     * @dev Return all productID separated onAuctionItems and soldItem
     * @return onAuctionItems and soldItems
     */
    function viewAllProductID() external view returns(uint[] memory onAuctionItems, uint[] memory soldItems){...}
</pre></code>
<li>viewOwnedProduct</li>
<pre><code>
    /**
     * @dev Return product owned by user
     * @return all product owned bu user
     */
    function viewOwnedProduct(address user) external view returns (uint[] memory){...}
</pre></code>
<li>viewAllUserAddress</li>
<pre><code>
    /**
     * @dev Return all registered user address
     * @return all registered user address
     */
    function viewAllUserAddress() external view returns (address[] memory){...}
</pre></code>  
<li>viewContractBalance</li>
<pre><code>
    /**
     * @dev view contract balance
     * @return balance of contract and maxWithdraw amount
     */
    function viewContractBalance() external view isOwner returns (uint balance, uint maxWithdraw){...}
</pre></code>
<li>withdrawBalance</li>
<pre><code>
    /**
     * @dev get some wei from contract
     * @param amount of wei to get
     */
    function withdrawBalance(uint amount) external payable isOwner{...}
</pre></code> 
</ol>