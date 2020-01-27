pragma solidity >=0.6.0;

import "./Withdrawal.sol";

///@title EthMov
contract EthMov is Withdrawal {
    /// @author Cyril Attie
    /// @notice Matches trasnportation demand with supply
    /// @dev to be insurable at nexus, to include special conditions option (ex: refrigeration)

    uint256 numTransports=0;

    enum SizeCategory {Enveloppe, SmallBox, BigBox} ///@dev size categories of the packet
    enum WeightCategory {lessThan1kg, between1kgAnd10kg, moreThan10kg} ///@dev weight categories of the packet
    enum TransportState {Unallocated, Allocated, PickedUp} ///@dev status of the transport

    ///@dev Transport
    struct Transport {
        address fromAddress;
        address toAddress;
        address transporter;
        SizeCategory sizeCategory;
        WeightCategory weightCategory;
        uint8[4] itinerary; ///@dev contains _fromLatitude, _fromLongitude, _toLatitude, _toLongitude
        uint256 timestamp;
        uint256 maxDeliveryTimestamp;
        uint256 weiPacketValue; /// for insurance purposes
        uint256 price; ///@dev fee offered or paid for this transport
    }

    struct Offer {
        address transporter;
        uint256 askPrice;
    }

    mapping(uint256 => Transport) public transportDemandPool; ///@dev to record transportation demands
    mapping(uint256 => Offer[]) AvailableTransportSupply; ///@dev to record transportation supplies with offered price
    mapping(uint256 => TransportState) onGoingTransportation; ///@dev ongoing transportations and their state

    event TransportDemanded(
        uint256 transportID,
        uint8[4] indexed itinerary,
        SizeCategory indexed sizeCategory,
        WeightCategory indexed weightCategory, //TODO check packetCategory is searchable from topics
        uint256 timestamp,
        uint256 maxDeliveryTimestamp,
        uint256 bidPrice
    );

    event TransportSupplied(
        uint256 _transportID,
        address transportSupplier,
        uint256 askPrice
    );
    event TransportationAllocated(
        uint256 transportID,
        address selectedTransporter,
        uint256 atPrice
    );
    event PickUp(uint256 transportID);
    event Delivery(uint256 transportID);
    event AllocatedTransportSupplyCancelled(
        uint256 transportID,
        address transporter
    );
    event UnallocatedTransportSupplyCancelled(
        uint256 transportID,
        address transporter
    );
    event transportDemandCancellation(uint256 transportID);

    modifier verifySender(uint256 transportId) {
        ///@param _transportID the transport identifier
        ///@dev verify sender to allocate transportation to transporter
        require(
            transportDemandPool[transportId].fromAddress == msg.sender,
            "This function must be called by the sender."
        );
        _;
    }
    modifier verifyTransporter(uint256 transportId) {
        ///@param _transportID the transport identifier
        ///@dev verify transporter to confirm pickup
        require(
            transportDemandPool[transportId].transporter == msg.sender,
            "This function must be called by the transporter."
        );
        _;
    }
    modifier verifyNotPickedUp(uint256 _transportID) {
        ///@param _transportID the transport identifier
        ///@dev verify packet has not yet been picked up to let users cancel transport.
        require(
            onGoingTransportation[_transportID] != TransportState.PickedUp,
            "Already picked up transports cannot be canceled."
        );
        _;
    }

    // function viewDemandTransport(uint256 _transportID)
    //     public
    //     view
    //     returns (address fromAddress,address toAddress,address transporter,
    //     SizeCategory sizeCategory,WeightCategory weightCategory,
    //     uint8[4] memory itinerary,uint256 timestamp,uint256 maxDeliveryTimestamp,uint256 weiPacketValue,uint256 price)
    // {
    //     return (transportDemandPool[_transportID].fromAddress,
    //     transportDemandPool[_transportID].toAddress,
    //     transportDemandPool[_transportID].transporter,
    //     transportDemandPool[_transportID].sizeCategory,
    //     transportDemandPool[_transportID].weightCategory,
    //     transportDemandPool[_transportID].itinerary,
    //     transportDemandPool[_transportID].timestamp,
    //     transportDemandPool[_transportID].maxDeliveryTimestamp,
    //     transportDemandPool[_transportID].weiPacketValue,
    //     transportDemandPool[_transportID].price);
    // }

function viewItinerary(uint256 _transportID)
        public
        view
        returns (uint8[4] memory itinerary)
    {
        return ([transportDemandPool[_transportID].itinerary[0],
                 transportDemandPool[_transportID].itinerary[1],
                 transportDemandPool[_transportID].itinerary[2],
                 transportDemandPool[_transportID].itinerary[3]]);
    }

    function demandTransport(
        address _to,
        SizeCategory _sizeCategory,
        WeightCategory _weightCategory,
        uint8[4] calldata _itinerary,
        uint256 _maxDeliveryTimestamp,
        uint256 _weiPacketValue,
        uint256 _bidPrice
    ) external returns (uint transportID) {
        ///@notice Post a new transportation demand
        ///@param _to address to which deliver packet
        ///@param _sizeCategory size category of the packet
        ///@param _weightCategory weight category of the packet
        ///@param _itinerary pick up and delivery locations coordinates
        ///@param _maxDeliveryTimestamp delivery deadline
        ///@param _weiPacketValue declared value of the packet
        ///@param _bidPrice offered transportation fee
        ///@dev increase transport counter
        numTransports++; // transportID generator
        transportID = numTransports;
        ///@dev add TransportDemand to transportDemandPool
        transportDemandPool[transportID] = Transport({
            fromAddress: msg.sender,
            toAddress: _to,
            transporter: address(0),
            sizeCategory: _sizeCategory,
            weightCategory: _weightCategory,
            itinerary: _itinerary,
            timestamp: now,
            maxDeliveryTimestamp: _maxDeliveryTimestamp,
            weiPacketValue: _weiPacketValue, /// for insurance purposes
            price: _bidPrice
        });

        ///@dev log TransportDemanded event
        emit TransportDemanded(
            transportID,
            _itinerary,
            _sizeCategory,
            _weightCategory,
            now,
            _maxDeliveryTimestamp,
            _bidPrice
        );
        return transportID;
    }

    function supplyTransport(uint256 _transportID, uint256 _askPrice) external {
        ///@notice supply a Transport service or modify a transport service supplied
        ///@param _transportID the transport identifier
        ///@param _askPrice the transport fee asked by the transporter
        ///@dev add transport supply to the list of available transporters
        AvailableTransportSupply[_transportID].push(
            Offer({transporter: msg.sender, askPrice: _askPrice})
        );
        ///@dev log Transport Supply event
        emit TransportSupplied(_transportID, msg.sender, _askPrice);
    }

    function allocateTransport(
        uint256 _transportID,
        address payable _selectedTransporter
    ) external payable verifySender(_transportID) {
        ///@notice to select transporter
        ///@param _transportID the transport identifier
        ///@dev check selected transporter made an offer for this transport and ether sent is enough to pay the asked fee
        uint256 i = 0;
        for (i; i <= AvailableTransportSupply[_transportID].length; i++) {
            if (
                AvailableTransportSupply[_transportID][i].transporter ==
                _selectedTransporter
            ) break;
        }
        require(
            i != AvailableTransportSupply[_transportID].length,
            "Offer not found.Double cheack the address"
        );
        uint256 askPrice = AvailableTransportSupply[_transportID][i].askPrice;
        require(
            onGoingTransportation[_transportID] == TransportState.Unallocated,
            "Transport has already been allocated"
        );
        require(
            askPrice != 0,
            "No supply was provided by this address. Ask price must be greater than 0."
        );
        require(
            msg.value >= askPrice,
            "Not enough funds to match transporter offered price."
        );
        ///@dev register transport allocation
        onGoingTransportation[_transportID] = TransportState.Allocated;
        transportDemandPool[_transportID].transporter = _selectedTransporter;
        transportDemandPool[_transportID].price = askPrice;

        ///@dev log allocated event
        emit TransportationAllocated(
            _transportID,
            _selectedTransporter,
            askPrice
        );
        ///@dev return change to sender
        pendingWithdrawals[msg.sender] += msg.value - askPrice;
    }

    function confirmPickUp(uint256 _transportID)
        external
        verifyTransporter(_transportID) ///@dev ensures the transport has been allocated
    {
        ///@notice to confirm transporter has picked up the packet
        ///@param _transportID the transport identifier
        ///@dev transport state is moved to pickedup and available transport supplies are deleted
        onGoingTransportation[_transportID] = TransportState.PickedUp;
        delete AvailableTransportSupply[_transportID];
        ///@dev log the pickup event
        emit PickUp(_transportID);
    }

    function confirmDelivery(uint256 _transportID) external {
        ///@notice to confirm destination delivery
        ///@param _transportID the transport identifier
        ///@dev require the delivery confirmation comes from the receiver
        require(
            transportDemandPool[_transportID].toAddress == msg.sender,
            "This function must be called by the destination."
        );
        ///@dev pay the transporter
        pendingWithdrawals[transportDemandPool[_transportID]
            .transporter] += transportDemandPool[_transportID].price;
        ///@dev log delivery and delete all records regarding this transport
        emit Delivery(_transportID);
        delete transportDemandPool[_transportID];
        delete onGoingTransportation[_transportID];
    }

    function cancelTransportDemand(uint256 _transportID)
        external
        verifySender(_transportID) ///@dev check packet has not been picked up yet
        verifyNotPickedUp(_transportID)
    {
        ///@notice cancel the transportation demand
        ///@param _transportID the transport identifier
        ///@dev deleted transport
        emit transportDemandCancellation(_transportID);
        if (onGoingTransportation[_transportID] == TransportState.Allocated) {
            ///@dev if transport has been allocated return the fee locked to the customer
            pendingWithdrawals[msg.sender] += transportDemandPool[_transportID]
                .price;
        }
        ///@dev delete all records related to this transport identifier
        delete AvailableTransportSupply[_transportID];
        delete transportDemandPool[_transportID];
        delete onGoingTransportation[_transportID];

    }

    function cancelTransportSupply(uint256 _transportID)
        external
        verifyNotPickedUp(_transportID)
    {
        ///@notice cancel transportation supply
        ///@param _transportID the transport identifier
        ///@dev delete offer and emit corresponding event
        for (
            uint256 i = 0;
            i < AvailableTransportSupply[_transportID].length;
            i++
        ) {
            if (
                AvailableTransportSupply[_transportID][i].transporter ==
                msg.sender
            ) {
                delete AvailableTransportSupply[_transportID][i];
            }
        }
        if (
            onGoingTransportation[_transportID] == TransportState.Allocated &&
            transportDemandPool[_transportID].transporter == msg.sender
        ) {
            ///@dev delete allocated transporter, set back transport to unallocated and return fee to customer
            delete transportDemandPool[_transportID].transporter;
            onGoingTransportation[_transportID] = TransportState.Unallocated;
            pendingWithdrawals[transportDemandPool[_transportID].fromAddress] += transportDemandPool[_transportID].price;
            ///@dev and emit corresponding event
            emit AllocatedTransportSupplyCancelled(_transportID, msg.sender);
        } else {
            ///@dev else (if unallocated or not allocated to this transporter) just delete offer and emit corresponding event
            emit UnallocatedTransportSupplyCancelled(_transportID, msg.sender);
        }
    }
}
