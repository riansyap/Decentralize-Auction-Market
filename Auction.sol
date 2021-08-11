// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

/** 
 * @title Auction
 * @dev Implements Simple Auction with Solidity
 */
contract Auction{
    
    address private owner; //deployer address
    uint private monetize; //amount of max wei that owner can withdraw

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
    
    address[] accountsIndex; //store all user address
    uint[] soldItemsIndex; //store all sold product
    uint[] auctionItemsIndex; //store all auction product
    
    receive() external payable {}
    fallback() external payable {}
    
    // event for EVM logging
    event HighestBidderSet(uint indexed productID, address indexed oldBidder, address indexed newBidder);
    event IndexOnItemsIndexSet(uint indexed productID, uint indexed oldIndex, uint indexed newIndex);
    event IndexOnProductListSet(uint indexed productID, uint indexed oldIndex, uint indexed newIndex);
    
    // modifier to check user is registered or not
    modifier isRegistered(bool expectedStatus) {
        //conditional to check caller registered status by expected status
        //if expectedStatus=true function caller need registered user
        if(expectedStatus){
            require(accountsData[msg.sender].registered==true, "You Must Register First");
        }
        else{
            require(accountsData[msg.sender].registered==false, "You Already Registered");
        }
        _;
    }
    
    // modifier to check caller product owner or not 
    modifier isProductOwner(uint productID, bool expectedStatus) {
        //conditional to check caller product owner status by expected status
        //if expectedStatus=true function caller need product owner user
        if(expectedStatus){
            require(itemsData[productID].ownerAddress==msg.sender, "You are Not Owner of This Product");
        }
        else{
            require(itemsData[productID].ownerAddress!=msg.sender, "You are Owner of This Product");
        }
        _;
    }
    
    // modifier to check product is on auction or not 
    modifier onAuction(uint productID) {
        require(itemsData[productID].auctionStatus==1, "This Product Is Not On Auction");
        _;
    }
    
    // modifier to check if caller is the product's highest bidder or not 
    modifier isHighestBidder(uint productID) {
        require(itemsData[productID].highestBidder==msg.sender, "You are Not Winner of This Product Auction's");
        _;
    }
    
    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; //contract deployer for a constructor
    }
    
    /**
     * @dev register user with the required data
     * @param fullName,residenceAddress,mailAddress,phoneNumber
     */
    function registerUser(string memory fullName, string memory residenceAddress, string memory mailAddress, string memory phoneNumber)external isRegistered(false){
        
        //user input validation
        require(bytes(fullName).length!=0 
            && bytes(residenceAddress).length!=0 
            && bytes(mailAddress).length!=0
            && bytes(phoneNumber).length!=0
            , "Please Fill All Required Data");
        
        //insert data to accountsData mapping by caller address
        accountsData[msg.sender].fullName=fullName;
        accountsData[msg.sender].residenceAddress=residenceAddress;
        accountsData[msg.sender].mailAddress=mailAddress;
        accountsData[msg.sender].phoneNumber=phoneNumber;
        accountsData[msg.sender].registered=true;
        
        //insert caller address to accountsIndex array
        accountsIndex.push(msg.sender);
        
    }
    
    /**
     * @dev register item with the required data
     * @param productName,price,bidUntil
     * @return generated productID
     */
    function registerItems(string memory productName, uint price, uint bidUntil)external isRegistered(true) returns(uint){
        
        //user input validation
        require(bytes(productName).length!=0 
            && price!=0 
            && bidUntil>block.timestamp
            , "Please Fill All Required Data with bidUntil more than now unixtime");
        
        //generate unique productID   
        uint generatedProductId=uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender,productName)));
        
        //insert data to accountsData mapping by caller address
        itemsData[generatedProductId].ownerAddress=msg.sender;
        itemsData[generatedProductId].productName=productName;
        itemsData[generatedProductId].price=price;
        itemsData[generatedProductId].time=block.timestamp;
        itemsData[generatedProductId].bidUntil=bidUntil;
        itemsData[generatedProductId].highestBidder=msg.sender;
        itemsData[generatedProductId].highestPrice=price;
        itemsData[generatedProductId].auctionStatus=1;
        
        //insert productID to productList and store the index on indexOnProductList
        accountsData[msg.sender].productList.push(generatedProductId);
        itemsData[generatedProductId].indexOnProductList=(accountsData[msg.sender].productList.length-1);
        
        //insert caller address to auctionItemsIndex array
        auctionItemsIndex.push(generatedProductId);
        itemsData[generatedProductId].indexOnItemsIndex=(auctionItemsIndex.length-1);
        
        //return productID
        return generatedProductId;
    }
    
    /**
     * @dev bid auction product 
     * @param productID that want to bid
     */
    function bid(uint productID)external payable isRegistered(true) isProductOwner(productID,false) onAuction(productID) {
        
        //some validation to use this function
        require(itemsData[productID].bidUntil>block.timestamp, "Sorry This Product's Auction Reached The Auction Time Limit");
        require(productID!=0, "Please Fill All Required Data");
        require(msg.value>itemsData[productID].highestPrice, "Please Bid Higher");
        
        //transfer wei from bidder to contract address
        payable(address(this)).transfer(msg.value);
        
        //if someone previously bid, transfer back wei from contract address to previous bidder address
        if(itemsData[productID].highestBidder!=itemsData[productID].ownerAddress){
            payable(itemsData[productID].highestBidder).transfer(itemsData[productID].highestPrice);
        }
        
        emit HighestBidderSet(productID, itemsData[productID].highestBidder, msg.sender);
        
        //change higest bidder and higst price
        itemsData[productID].highestBidder=msg.sender;
        itemsData[productID].highestPrice=msg.value;
        
    }
    
    /**
     * @dev move product from auctionItemsIndex array to soldItemsIndex array
     * @param productID that sold or failed
     */
    function moveToSold(uint productID)private{
        
        //if the data is the last in array, skip this step
        //otherwise move the last data to index that will be deleted
        //and change affected indexOnItemsIndex
        if(itemsData[productID].indexOnItemsIndex!=(auctionItemsIndex.length-1)){
            auctionItemsIndex[itemsData[productID].indexOnItemsIndex]=auctionItemsIndex[(auctionItemsIndex.length-1)];
            emit IndexOnItemsIndexSet(auctionItemsIndex[itemsData[productID].indexOnItemsIndex], itemsData[auctionItemsIndex[itemsData[productID].indexOnItemsIndex]].indexOnItemsIndex, itemsData[productID].indexOnItemsIndex);
            itemsData[auctionItemsIndex[itemsData[productID].indexOnItemsIndex]].indexOnItemsIndex=itemsData[productID].indexOnItemsIndex;
        }
        //delete last data on auctionItemsIndex array
        auctionItemsIndex.pop();
        
        //insert product to soldItemsIndex and change the index on indexOnItemsIndex
        soldItemsIndex.push(productID);
        emit IndexOnItemsIndexSet(productID, itemsData[productID].indexOnItemsIndex, (soldItemsIndex.length-1));
        itemsData[productID].indexOnItemsIndex=(soldItemsIndex.length-1);
        
    }
    
    /**
     * @dev Auction Winner can ask for refund if seller not finalize the auction
     * @param productID that want to be refund
     */
    function askRefund(uint productID)external payable isRegistered(true) isProductOwner(productID,false) isHighestBidder(productID) onAuction(productID){
        //need at least 7 days after auction time reached to call this function
        require((itemsData[productID].bidUntil+ 7 days)<=block.timestamp, "Please Wait Until Auction Expired");
        
        //transfer from contract address to Auction Winner
        payable(msg.sender).transfer(itemsData[productID].highestPrice);
        
        //change higest Bidder back to seller address and change status to failed
        itemsData[productID].highestBidder=itemsData[productID].ownerAddress;
        itemsData[productID].auctionStatus=0;
        
        //call move to sold function to fix some moved data index
        moveToSold(productID);
        
    }
    
    /**
     * @dev seller must finalize the auction after bidTime reached to proceed auction status
     * @param productID that want to finalize
     */
    function finalizeAuction(uint productID)external isProductOwner(productID,true) onAuction(productID){
        //validation only can call this function if bidTime reached
        require(itemsData[productID].bidUntil<=block.timestamp, "Please Wait Until Auction Finished");
        
        //itemsData[productID].highestBidder==msg.sender means there is no bidder for the product
        if(itemsData[productID].highestBidder==msg.sender){
            //change status to failed
            itemsData[productID].auctionStatus=0;
            
            //call move to sold function to fix some moved data index
            moveToSold(productID);
        }
        else{
            //change status to goods on delivery
            itemsData[productID].auctionStatus=2;
        }
    }
    
    /**
     * @dev Auction must confirm after the product arrive
     * @param productID that want to confirm
     */
    function confirm(uint productID)external payable isRegistered(true) isProductOwner(productID,false) isHighestBidder(productID){
        //need status to be goods on delivery to call this function
        require(itemsData[productID].auctionStatus==2, "The Auction is Still Going");
        //transfer to seller with 1 % fee
        payable(itemsData[productID].ownerAddress).transfer(itemsData[productID].highestPrice*99/100);
        //store monetize amount
        monetize+=(itemsData[productID].highestPrice/100);
        
        uint tempLastIndexProduct = (accountsData[itemsData[productID].ownerAddress].productList.length-1);//0
        uint tempIndexSoldProduct = itemsData[productID].indexOnProductList;//0
        
        //if the data is the last in array, skip this step
        //otherwise move the last data to index that will be deleted
        //and change affected indexOnProductList 
        if (tempLastIndexProduct!=tempIndexSoldProduct){
            accountsData[itemsData[productID].ownerAddress].productList[tempIndexSoldProduct]=accountsData[itemsData[productID].ownerAddress].productList[tempLastIndexProduct];
            emit IndexOnProductListSet(accountsData[itemsData[productID].ownerAddress].productList[tempIndexSoldProduct], itemsData[accountsData[itemsData[productID].ownerAddress].productList[tempIndexSoldProduct]].indexOnProductList, tempIndexSoldProduct);
            itemsData[accountsData[itemsData[productID].ownerAddress].productList[tempIndexSoldProduct]].indexOnProductList=tempIndexSoldProduct;   
        }
        accountsData[itemsData[productID].ownerAddress].productList.pop();
        
        //insert ProductID to productList and update the indexOnProductList
        accountsData[msg.sender].productList.push(productID);
        itemsData[productID].indexOnProductList=(accountsData[msg.sender].productList.length-1);
        
        //change ownerdata  and change status to sold
        itemsData[productID].ownerAddress=itemsData[productID].highestBidder;
        itemsData[productID].auctionStatus=0;
        
        //call move to sold function to fix some moved data index
        moveToSold(productID);
        
    }
    
    /**
     * @dev seller can call this function if previous auction failed and Auction Winner can call this function to resell product
     * @param productID, price, bidUntil 
     */
    function reAuction(uint productID, uint price, uint bidUntil) external isProductOwner(productID,true){
        //user input validation
        require(productID!=0 
            && price!=0 
            && bidUntil!=0
            , "Please Fill All Required Data");
        //This function can only called if status is sold or failed
        require(itemsData[productID].auctionStatus==0, "Product On Auction");
        
        //update bid data
        itemsData[productID].price=price;
        itemsData[productID].time=block.timestamp;
        itemsData[productID].bidUntil=bidUntil;
        itemsData[productID].highestPrice=price;
        itemsData[productID].auctionStatus=1;
        
        uint tempIndex = itemsData[productID].indexOnItemsIndex;
        uint LastTempIndex = (soldItemsIndex.length-1);
        //if the data is the last in array, skip this step
        //otherwise move the last data to index that will be deleted
        //and change affected indexOnItemsIndex
        if(tempIndex!=LastTempIndex){
            soldItemsIndex[tempIndex]=soldItemsIndex[LastTempIndex];
            emit IndexOnItemsIndexSet(soldItemsIndex[tempIndex], itemsData[soldItemsIndex[tempIndex]].indexOnItemsIndex, tempIndex);
            itemsData[soldItemsIndex[tempIndex]].indexOnItemsIndex=tempIndex;
        }
        //delete last data on soldItemsIndex array
        soldItemsIndex.pop();
        
        //insert product to auctionItemsIndex and change the index on indexOnItemsIndex
        auctionItemsIndex.push(productID);
        emit IndexOnItemsIndexSet(productID, itemsData[productID].indexOnItemsIndex, (auctionItemsIndex.length-1));
        itemsData[productID].indexOnItemsIndex=(auctionItemsIndex.length-1);
    }
    
    /**
     * @dev Return all on auction productID
     * @return all productID on auction
     */
    function viewAllAuctionProductID() external view returns(uint[] memory){
        return auctionItemsIndex;
    }
    
    /**
     * @dev Return all productID separated onAuctionItems and soldItem
     * @return onAuctionItems and soldItems
     */
    function viewAllProductID() external view returns(uint[] memory onAuctionItems, uint[] memory soldItems){
        return (auctionItemsIndex,soldItemsIndex);
    }
    
    /**
     * @dev Return product owned by user
     * @return all product owned bu user
     */
    function viewOwnedProduct(address user) external view returns (uint[] memory){
        return accountsData[user].productList;
    }
    
    /**
     * @dev Return all registered user address
     * @return all registered user address
     */
    function viewAllUserAddress() external view returns (address[] memory){
        return accountsIndex;
    }
    
    /**
     * @dev view contract balance
     * @return balance of contract and maxWithdraw amount
     */
    function viewContractBalance() external view isOwner returns (uint balance, uint maxWithdraw){
        return (address(this).balance,monetize);
    }
    
    /**
     * @dev get some wei from contract
     * @param amount of wei to get
     */
    function withdrawBalance(uint amount) external payable isOwner{
        require(amount<=monetize,"Please Withdraw lower");
        monetize-=amount;
        payable(owner).transfer(amount);
    }
    
}