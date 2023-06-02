// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract AiYueNFTExchange is ERC1155, ERC1155Burnable{
    struct InitialOwner {
        address owner;
        uint256 amount;
    }
    struct CurrentOwner {
        address owner;
        uint256 amount;
    }
    struct Vote {
        address voter;
        uint256 number;
    }
    mapping(uint256 => InitialOwner) public initialOwners;
    mapping(uint256 => CurrentOwner[]) public tokenIdCurrentOwner;
    mapping(uint256 => Vote[]) public voteInfo;

    constructor() ERC1155("") {}
    function setURI(string memory newuri) public {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public
    {
        _mint(account, id, amount, data);
        initOwnerAmount(account, id, amount);
        initCurrentOwner(account, id, amount);
    }

    function transferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public {
        safeTransferFrom(from, to, id, amount, data);
        changeTokenIdAmount(from, to, id, amount);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public
    {
        _mintBatch(to, ids, amounts, data);
    }

    function initOwnerAmount(address _owner, uint256 tokenId, uint256 _amount) internal {
        InitialOwner memory initialOwner = InitialOwner({
            owner : _owner,
            amount : _amount
            });
        initialOwners[tokenId] = initialOwner;
    }

    function initCurrentOwner(address _owner, uint256 tokenId, uint256 _amount) internal {
        CurrentOwner memory currentOwner = CurrentOwner({
            owner : _owner,
            amount : _amount
            });
        tokenIdCurrentOwner[tokenId].push(currentOwner);
    }

    function changeTokenIdAmount(address _from, address _to, uint256 _tokenId, uint256 _amount) internal {
        if (getShareExit(_tokenId, _to)) {
            CurrentOwner memory currentOwner = getShareEntity(_tokenId, _to);
            currentOwner.amount += _amount;

            uint256 shareIndex = getShareArrayIndex(_tokenId, _to);
            tokenIdCurrentOwner[_tokenId][shareIndex] = currentOwner;
        } else {
            CurrentOwner memory currentOwner = CurrentOwner({
                owner : _to,
                amount : _amount
                });
            tokenIdCurrentOwner[_tokenId].push(currentOwner);
        }

        CurrentOwner memory current = getShareEntity(_tokenId, _from);
        current.amount = current.amount - _amount;

        uint256 shareOneIndex = getShareArrayIndex(_tokenId, _from);
        tokenIdCurrentOwner[_tokenId][shareOneIndex] = current;
    }

    function getShareExit(uint256 _tokenId, address owner) internal view returns (bool){
        CurrentOwner[] memory shares = tokenIdCurrentOwner[_tokenId];
        for (uint i = 0; i < shares.length; i++) {
            if (shares[i].owner == owner) {
                return true;
            }
        }
        return false;
    }

    function getShareEntity(uint256 _tokenId, address owner) internal view returns (CurrentOwner memory){
        CurrentOwner  memory share;
        CurrentOwner[] memory shareList = tokenIdCurrentOwner[_tokenId];
        for (uint i = 0; i < shareList.length; i++) {
            if (shareList[i].owner == owner) {
                share = shareList[i];
                return share;
            }
        }
        return share;
    }

    function getShareArrayIndex(uint256 _tokenId, address owner) internal view returns (uint256){
        uint256 index;
        CurrentOwner[] memory shareList = tokenIdCurrentOwner[_tokenId];
        for (uint i = 0; i < shareList.length; i++) {
            if (shareList[i].owner == owner) {
                index = i;
                return index;
            }
        }
        return index;
    }

    function addVoteInfo(address _voter, address operator, uint256 id) public {
        uint256 _number = balanceOf(_voter, id);
        Vote memory newVote = Vote({
            voter : _voter,
            number : _number
            });
        voteInfo[id].push(newVote);
        setApprovalForAll(operator, true);
    }

    function getVoteInfo(uint256 id) public view returns (uint256, uint256){
        uint256 all = initialOwners[id].amount;
        uint256 realVoteNumber = 0;
        Vote[] memory voteList = voteInfo[id];
        for (uint i = 0; i < voteList.length; i++) {
            realVoteNumber += voteList[i].number;
        }
        return (all, realVoteNumber);
    }


}
