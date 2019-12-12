pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    uint PRICE_TICKET = 100 wei;
    address payable public owner;

    constructor ()
        public
    {
        owner = msg.sender;
    }

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */

    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */

    mapping (uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner() {
        require(owner == msg.sender, 'Check owner.');
        _;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */

    function addEvent(string memory _description, string memory _website, uint _totalTickets)
        public
        onlyOwner()
        returns (uint)
    {
        Event storage myEvent = events[idGenerator];
        myEvent.description = _description;
        myEvent.website = _website;
        myEvent.totalTickets = _totalTickets;
        myEvent.isOpen = true;
        idGenerator ++;
        emit LogEventAdded(_description, _website, _totalTickets, idGenerator);
        return idGenerator;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint _eventID)
        public
        view
        returns(
            string memory _description,
            string memory _website,
            uint _totalTickets,
            uint _sales,
            bool isOpen
        )
    {
        return (
            events[_eventID].description,
            events[_eventID].website,
            events[_eventID].totalTickets,
            events[_eventID].sales,
            events[_eventID].isOpen
        );
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint _eventID, uint _ticketsPurchased)
        public
        payable
    {
        require(events[_eventID].isOpen, 'Event sales not open.');
        require(msg.value >= (PRICE_TICKET * _ticketsPurchased), 'Not enough money.');
        require((events[_eventID].totalTickets - events[_eventID].sales) >= _ticketsPurchased, 'Not enough tickets left');

        events[_eventID].sales += _ticketsPurchased;
        events[_eventID].buyers[msg.sender] += _ticketsPurchased;
        msg.sender.transfer(msg.value - (PRICE_TICKET * _ticketsPurchased));
        emit LogBuyTickets(msg.sender, _eventID, _ticketsPurchased);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */

    function getRefund(uint _eventID)
        public
        payable
    {
        uint ticketsPurchased = events[_eventID].buyers[msg.sender];
        require(ticketsPurchased > 0,'No event tickets purchased.');
        events[_eventID].sales -= ticketsPurchased;
        msg.sender.transfer(ticketsPurchased * PRICE_TICKET);

        emit LogGetRefund(msg.sender, _eventID, ticketsPurchased);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _eventID)
        public
        view
        returns (uint)
    {
        return events[_eventID].buyers[msg.sender];
    }
    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _eventID)
        public
        onlyOwner()
    {
        events[_eventID].isOpen = false;
        uint balance = events[_eventID].sales * PRICE_TICKET;
        msg.sender.transfer(balance);

        emit LogEndSale(msg.sender, balance, _eventID);
    }
}
