// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

contract BUNNLottery is VRFConsumerBaseV2, ConfirmedOwner {
    event RequestSent(uint256 requestID, uint32 numWords);
    event RequestFulfiled(uint256 requestID, uint256[] randomWords);
    event lotteryCreated(uint256 lotteryId);

    VRFCoordinatorV2Interface COODINATOR;
    uint256 lastRequestId;
    uint64 s_subscription;

    bytes32 keyHash =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public s_requests;
    uint256[] public requestIds;

    uint32 callbackGasLimit = 1e5;
    uint16 requestConfirmation = 3;

    uint32 numWords = 1;

    struct lotteryData_ {
        uint256 numberOfParticipants;
        address winner;
        address[] contenders;
        bool completed;
        bool exists;
    }

    mapping(uint256 => lotteryData_) LotteryData;

    constructor(
        uint64 subscriptionID
    )
        VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625)
        ConfirmedOwner(msg.sender)
    {
        COODINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
        s_subscription = subscriptionID;
    }

    function requestRandomWords() internal returns (uint256 requestID) {
        requestID = COODINATOR.requestRandomWords(
            keyHash,
            s_subscription,
            requestConfirmation,
            callbackGasLimit,
            numWords
        );

        s_requests[requestID] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });

        requestIds.push(requestID);
        lastRequestId = requestID;
        emit RequestSent(requestID, numWords);
    }

    function fulfillRandomWords(
        uint256 _requestID,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestID].exists, "Request not found");

        s_requests[_requestID].fulfilled = true;
        s_requests[_requestID].randomWords = _randomWords;
        emit RequestFulfiled(_requestID, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestID
    ) public view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestID].exists, "Request not found");

        RequestStatus memory request = s_requests[_requestID];

        return (request.fulfilled, request.randomWords);
    }

    function createLottery(
        uint256 _lotteryId,
        uint256 noOfParticipants
    ) external onlyOwner {
        address[] memory contenders;

        lotteryData_ memory newLottery = lotteryData_(
            noOfParticipants,
            address(0),
            contenders,
            false,
            true
        );
        LotteryData[_lotteryId] = newLottery;
        emit lotteryCreated(_lotteryId);
    }

    function participate(uint256 _lotteryId) external returns (bool) {
        require(LotteryData[_lotteryId].exists == true, "Invalid Lottery ID");
        require(
            LotteryData[_lotteryId].contenders.length <
                LotteryData[_lotteryId].numberOfParticipants,
            "Lottery failed"
        );

        LotteryData[_lotteryId].contenders.push(msg.sender);

        if (
            LotteryData[_lotteryId].numberOfParticipants ==
            LotteryData[_lotteryId].contenders.length
        ) {
            spinTheWheel(_lotteryId);
        }
        return true;
    }

    function spinTheWheel(uint _lotteryId) public {
        require(LotteryData[_lotteryId].exists == true, "Invalid Lottery ID");
        if (msg.sender != owner()) {
            require(
                LotteryData[_lotteryId].numberOfParticipants ==
                    LotteryData[_lotteryId].contenders.length
            );
        }
        LotteryData[_lotteryId].completed = true;
        requestRandomWords();
    }

    function AwardWinner(uint _lotteryId) external returns (uint256) {
        require(LotteryData[_lotteryId].completed == true, "Wheel not spined.");
        require(
            LotteryData[_lotteryId].winner == address(0),
            "Winner already announced."
        );
        (, uint[] memory winners) = getRequestStatus(lastRequestId);

        uint noOfContenders = LotteryData[_lotteryId].contenders.length;
        uint winner = winners[0] % noOfContenders;

        address[] memory contenders_ = LotteryData[_lotteryId].contenders;
        LotteryData[lotteryId].winner = contenders[winner];

        return winner;
    }

    function viewWinner(uint _lotteryId) external view returns (address) {
        require(LotteryData[_lotteryId].exists == true, "Invalid lottery ID");
        return LotteryData[_lotteryId].winner;
    }
}