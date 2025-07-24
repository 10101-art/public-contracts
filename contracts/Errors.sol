//Error constants

//constant

contract Errors {
    // "Deletion is not possible because the primary sale has started."
    string constant ERROR_DELETION_PRIMARY_SALE_STARTED = "1";
    //"Function BurnAll is not available!"
    string constant ERROR_BURN_ALL_NOT_AVAILABLE = "2";
    //"There is nothing on the balance of the contract now."
    string constant ERROR_NOTHING_ON_BALANCE = "3";
    //"This collection has been burned, the purchase of tokens is not possible."
    string constant ERROR_COLLECTION_BURNED = "4";
    //"The purchase of the collection is not possible because the purchase time has ended"
    string constant ERROR_PURCHASE_TIME_ENDED = "5";
    //"This number of fragments from the collection could not be found, as it exceeds the total number."
    string constant ERROR_NUMBER_FRAGMENTS_NOT_FOUND = "6";
    // "Address beneficiary cannot be null!"
    string constant ERROR_ADDRESS_BENEFICIARY_NULL = "7";
    // "The purchase of the collection is not possible because the purchase time has not yet come"
    string constant ERROR_PURCHASE_TIME_NOT_YET = "8";
    //"This collection does not support the purchase of tokens for wei"
    string constant ERROR_COLLECTION_NOT_SUPPORT_PURCHASE_WEI = "9";
    //"Not enough money to buy"
    string constant ERROR_NOT_ENOUGH_MONEY = "10";
    //"Collection tokens were not burned."
    string constant ERROR_COLLECTION_TOKENS_NOT_BURNED = "11";
    //"Nothing to return"
    string constant ERROR_NOTHING_TO_RETURN = "12";
    // "Not enough money to return"
    string constant ERROR_NOT_ENOUGH_MONEY_TO_RETURN = "13";
    //"Presale: ERC20 address cannot be null!"
    string constant ERROR_ERC20_ADDRESS_NULL = "14";
    // "Presale: 'whitelistPrice' must be less than 'publicPrice'!"
    string constant ERROR_WHITELIST_PRICE_LESS_THAN_PUBLIC_PRICE = "15";
    //"Presale: 'startWhitelistTimestamp' must be less or equal 'startPublicTimestamp'!"
    string constant ERROR_START_WHITELIST_TIMESTAMP_LESS_OR_EQUAL_START_PUBLIC_TIMESTAMP = "16";
    //"Presale: 'startWhitelistTimestamp' must be less than 'stopWhitelistTimestamp'!"
    string constant ERROR_START_WHITELIST_TIMESTAMP_LESS_STOP_WHITELIST_TIMESTAMP = "17";
    // "Presale: 'startWhitelistTimestamp' must be less than 'stopTimestamp'!"
    string constant ERROR_START_WHITELIST_TIMESTAMP_LESS_STOP_TIMESTAMP = "18";


}
