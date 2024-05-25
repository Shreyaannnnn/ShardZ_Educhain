pragma solidity ^0.8.20;

import "./Asset.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Market {

    address[] private _assets;
    enum Listingstatus {
        Active,
        Sold,
        Cancelled
    }

    struct Listing {
        Listingstatus status;
        address seller;
        uint amount;
        uint price;
    }

    uint private _listingId = 0;
    mapping(address => Listing) private _listings;

    function createcontent(string memory _name, string memory _symbol) public returns (address) {
        Asset asset = new Asset(_name, _symbol);
        _assets.push(address(asset));
        Listing memory listing = Listing(Listingstatus.Cancelled, msg.sender, 0, 0);
        _listings[address(asset)]=listing;
        asset.transferOwnership(msg.sender);
        return address(asset);
    }



    

    

    function addassettolist(address assetAddress, uint amount, uint price) public {
        Asset asset = Asset(assetAddress);
        require(asset.transferFrom(msg.sender,address(this), amount), "Listing Failed");
        Listing memory listing = _listings[assetAddress];
        listing.amount=amount;
        listing.price=price;
        listing.status=Listingstatus.Active;
        _listings[assetAddress] = listing;
        _listingId++;
    }

    function getListing(address assetAddress) public view returns (Listing memory) {
        return _listings[assetAddress];
    }

    function buyasset(address assetAddress, uint numcoins) external payable {
        Listing storage listing = _listings[assetAddress];
        require(listing.status == Listingstatus.Active, "Listing is not active");
        require(msg.sender != listing.seller, "Seller can't be the buyer");
        require(listing.amount >= numcoins, "Not enough tokens available");
        require(msg.value >= listing.price * numcoins, "Insufficient payment");

        Asset asset = Asset(assetAddress);
        asset.transfer(msg.sender, numcoins);
        payable(listing.seller).transfer(listing.price * numcoins);
        listing.amount -= numcoins;

        if (listing.amount == 0) {
            listing.status = Listingstatus.Sold;
        }
        _listings[assetAddress] = listing;
    }

    function cancel(address assetAddress) public {
        Listing storage listing = _listings[assetAddress];
        require(msg.sender == listing.seller, "Only seller can cancel listing");
        require(listing.status == Listingstatus.Active, "Listing is not active");
        listing.status = Listingstatus.Cancelled;
        Asset asset = Asset(assetAddress);
        asset.transfer(msg.sender, listing.amount);
    }
}
