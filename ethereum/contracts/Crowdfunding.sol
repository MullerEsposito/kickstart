// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

import "../structs/Request.sol";
import "../structs/Summary.sol";

contract Crowdfunding {
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public numberOfApprovers;
    Request[] public requests;

    modifier restrictedToManager() {
        require(msg.sender == manager);
        _;
    }

    constructor(uint minimum, address creator) {
        manager = creator;
        minimumContribution = minimum;        
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);

        approvers[msg.sender] = true;
        numberOfApprovers++;
    }

    function createRequest(string memory description, uint value, address recipient) public payable restrictedToManager {
        Request storage newRequest = requests.push(); 
        newRequest.description = description;
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.isComplete = false;
        newRequest.yesVotes = 0;

    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

        bool isApprover = approvers[msg.sender];
        bool isNotAlreadyVoted = !request.voters[msg.sender];
        
        require(isApprover);
        require(isNotAlreadyVoted);

        request.voters[msg.sender] = true;
        request.yesVotes++;
    }

    function getRequestVoters(uint indexRequest, address addressVoter) public view returns(bool) {
        return requests[indexRequest].voters[addressVoter];
    }

    function finalizeRequest(uint index) public restrictedToManager {
        Request storage request = requests[index];

        require(request.yesVotes > (numberOfApprovers / 2));
        require(!request.isComplete);

        payable(request.recipient).transfer(request.value);
        request.isComplete = true;
    }

    function getSummary() public view returns (Summary memory) {
        return (Summary(
            minimumContribution,
            address(this).balance,
            requests.length,
            numberOfApprovers,
            manager
        ));
    }

    function getRequestsCount() public view returns (uint) {
        return requests.length;
    }
    
}