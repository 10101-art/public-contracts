// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../OwnableExt.sol";
import "./ExchangeDomain.sol";
import "../libs/UintLibrary.sol";
import "../libs/ECDSA.sol";
import "./ExchangeState.sol";
import "./ExchangeOrdersHolder.sol";
import "./HasSecondarySaleFees.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

/// @title Token Exchange contract.
/// @notice Supports ETH, ERC20, ERC721, ERC721A and ERC1155 tokens.
/// @notice This contracts relies on offchain signatures for order and fees verification.
contract MarketMaker is OwnableExt, ExchangeDomain {
    using Math for uint256;
    using UintLibrary for uint256;
    using ECDSA for bytes32;
    using Address for address payable;

    enum FeeSide {
        NONE,
        SELL,
        BUY
    }

    event Buy(
        address indexed sellToken,
        uint256 indexed sellTokenId,
        uint256 sellValue,
        address owner,
        address buyToken,
        uint256 buyTokenId,
        uint256 buyValue,
        address buyer,
        uint256 amount,
        uint256 salt
    );

    event Cancel(
        address indexed sellToken,
        uint256 indexed sellTokenId,
        address owner,
        address buyToken,
        uint256 buyTokenId,
        uint256 salt
    );

    bytes4 private constant _INTERFACE_ID_FEES =
        type(IHasSecondarySaleFees).interfaceId;
    uint256 private constant UINT256_MAX = type(uint256).max;

    address payable public beneficiary;
    address public aliveUntilSigner;

    /// @notice The address of a state contract, which counts the amount of selled tokens.
    ExchangeState public state;
    /// @notice The address of a orders holder contract, which can contain unsigned orders.
    ExchangeOrdersHolder public ordersHolder;

    /// @notice Contract constructor.
    /// @param _state - The address of a deployed ExchangeStateV1 contract.
    /// @param _ordersHolder - The address of a deployed ExchangeOrdersHolderV1 contract.
    /// @param _beneficiary - The address wich will receive collected fees.
    /// @param _aliveUntilSigner - The address alive until Signer.
    constructor(
        ExchangeState _state,
        ExchangeOrdersHolder _ordersHolder,
        address payable _beneficiary,
        address _aliveUntilSigner
    ) {
        require(
            address(_state) != address(0),
            "ExchangeState contract address cannot be null!"
        );
        require(
            address(_ordersHolder) != address(0),
            "ExchangeOrdersHolder contract address cannot be null!"
        );
        require(
            _beneficiary != address(0),
            "Beneficiary address cannot be null!"
        );
        require(
            _aliveUntilSigner != address(0),
            "AliveUntilSigner contract address cannot be null!"
        );

        state = _state;
        ordersHolder = _ordersHolder;
        beneficiary = _beneficiary;
        aliveUntilSigner = _aliveUntilSigner;

        emit ChangingBeneficiary(beneficiary, address(0));
        emit ChangingAliveUntilSigner(aliveUntilSigner, address(0));
        emit ChangingExchangeState(address(state), address(0));
        emit ChangingExchangeOrdersHolder(address(ordersHolder), address(0));
    }

    /// @notice This function is called by contract owner and sets fee receiver address.
    /// @param newBeneficiary - new address, who where all the fees will be transfered
    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        require(
            newBeneficiary != address(0),
            "Beneficiary address cannot be null!"
        );

        address oldBeneficiary = beneficiary;

        beneficiary = newBeneficiary;

        emit ChangingBeneficiary(newBeneficiary, oldBeneficiary);
    }

    /// @notice This function is signer aliveUntil and sets alive until signer address.
    /// @param newAliveUntilSigner - new address alive until signer
    function setAliveUntliSigner(
        address newAliveUntilSigner
    ) external onlyOwner {
        address oldAliveUntilSigner = aliveUntilSigner;

        aliveUntilSigner = newAliveUntilSigner;

        emit ChangingAliveUntilSigner(newAliveUntilSigner, oldAliveUntilSigner);
    }

    /// @notice This function is called by contract owner and sets exchange state address.
    function setExchangeState(ExchangeState _exchangeState) external onlyOwner {
        address oldExchangeState = address(state);
        address newExchangeState = address(_exchangeState);

        state = _exchangeState;

        emit ChangingExchangeState(newExchangeState, oldExchangeState);
    }

    /// @notice This function is called by contract owner and sets exchange orders holders address.
    function setExchangeOrdersHolder(
        ExchangeOrdersHolder _exchangeOrdersHolder
    ) external onlyOwner {
        address oldExchangeOrdersHolder = address(ordersHolder);
        address newExchangeOrdersHolder = address(_exchangeOrdersHolder);

        ordersHolder = _exchangeOrdersHolder;

        emit ChangingExchangeOrdersHolder(
            newExchangeOrdersHolder,
            oldExchangeOrdersHolder
        );
    }

    /// @notice This function is called to execute the exchange.
    /// @notice ERC20, ERC721 or ERC1155 tokens from buyer's or seller's side must be approved for this contract before calling this function.
    /// @notice To pay with ETH, transaction must send ether within the calling transaction.
    /// @notice Buyer's payment value is calculated as `order.buying * amount / order.selling + buyerFee%`.
    /// @dev Emits Buy event.
    /// @param order - Order struct (see ExchangeDomainV1).
    /// @param sig - Signed order message. To generate the message call `prepareMessage` function.
    ///        Message must be prefixed with: `"\x19Ethereum Signed Message:\n" + message.length`.
    ///        For example, web3.accounts.sign will automatically prefix the message.
    ///        Also, the signature might be all zeroes, if specified order record was added to the ordersHolder.
    /// @param aliveUntil System subscription period
    /// @param aliveUntilSig System subscription period signature
    /// @param amount - Amount of tokens to buy.
    /// @param buyer - The buyer's address.
    function exchange(
        Order calldata order,
        ECDSASig calldata sig,
        uint256 aliveUntil,
        ECDSASig calldata aliveUntilSig,
        uint256 amount,
        address buyer
    ) external {
        _beforeExchange(order, sig, aliveUntil, aliveUntilSig, amount, buyer);

        uint256 paying = (order.buying * amount) / order.selling;

        FeeSide feeSide = getFeeSide(
            order.key.sellAsset.assetType,
            order.key.buyAsset.assetType
        );

        if (buyer == address(0x0)) {
            buyer = msg.sender;
        } else {
            require(
                admins[msg.sender],
                "Invalid buyer because the caller is not allowed to set its own buyer"
            );
        }

        transferWithFeesPossibility(
            order.key.sellAsset,
            amount,
            payable(order.key.owner),
            payable(buyer),
            feeSide == FeeSide.SELL,
            order.fee
        );
        transferWithFeesPossibility(
            order.key.buyAsset,
            paying,
            payable(buyer),
            payable(order.key.owner),
            feeSide == FeeSide.BUY,
            order.fee
        );
        emitBuy(order, amount, buyer);
    }

    /// @notice Cancel the token exchange order. Can be called only by the order owner.
    ///         The function makes all exchnage calls for this order revert with error.
    /// @param key - The OrderKey struct of the order.
    function cancel(OrderKey calldata key) external {
        require(key.owner == msg.sender, "not an owner");
        state.setCompleted(key, UINT256_MAX);
        emit Cancel(
            key.sellAsset.token,
            key.sellAsset.tokenId,
            msg.sender,
            key.buyAsset.token,
            key.buyAsset.tokenId,
            key.salt
        );
    }

    /// @notice This function validates order message.
    /// @param order Order struct.
    /// @param sig Signature order
    function validateOrderSig(
        Order memory order,
        ECDSASig memory sig
    ) internal view {
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            require(ordersHolder.exists(order), "incorrect signature order");
        } else {
            require(
                prepareMessage(order).recover(sig.v, sig.r, sig.s, true) ==
                    order.key.owner,
                "ECDSA: incorrect signature order"
            );
        }
    }

    /// @notice This function validates alive until message.
    /// @param order Order struct.
    /// @param aliveUntil System subscription period
    /// @param sig Signature Alive Until
    function validateAliveUntilSig(
        Order memory order,
        uint256 aliveUntil,
        ECDSASig memory sig
    ) internal view {
        require(
            prepareAliveUntilMessage(order, aliveUntil).recover(
                sig.v,
                sig.r,
                sig.s,
                true
            ) == aliveUntilSigner,
            "ECDSA: incorrect signature aliveUntil"
        );

        require(aliveUntil >= block.timestamp, "Timeout signature aliveUntil");
    }

    /// @notice This function generates alive until message to sign for exchange call.
    /// @param order Order struct.
    /// @param aliveUntil System subscription period
    /// @return Encoded alive until message, wich should be signed by the token owner. Does not contain standard prefix.
    function prepareAliveUntilMessage(
        Order memory order,
        uint256 aliveUntil
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(order, aliveUntil));
    }

    /// @notice This function generates order message to sign for exchange call.
    /// @param order - Order struct.
    /// @return Encoded order message, wich should be signed by the token owner. Does not contain standard prefix.
    function prepareMessage(Order memory order) private pure returns (bytes32) {
        return keccak256(abi.encode(order));
    }

    function transferWithFeesPossibility(
        Asset memory firstType,
        uint256 value,
        address payable from,
        address payable to,
        bool hasFee,
        uint256 fee
    ) internal {
        if (!hasFee) {
            transfer(firstType, value, from, to);
        } else {
            transferWithFees(firstType, value, from, to, fee);
        }
    }

    function transfer(
        Asset memory asset,
        uint256 value,
        address from,
        address to
    ) internal {
        if (asset.assetType == AssetType.ERC20) {
            require(asset.tokenId == 0, "tokenId should be 0");

            IERC20 token = IERC20(asset.token);

            SafeERC20.safeTransferFrom(token, from, to, value);
        } else {
            require(value == 1, "value should be 1 for ERC-721");

            IERC721 token = IERC721(asset.token);

            token.safeTransferFrom(from, to, asset.tokenId);
        }
    }

    function transferWithFees(
        Asset memory firstType,
        uint256 value,
        address from,
        address to,
        uint256 fee
    ) internal {
        uint256 restValue = transferFeeToBeneficiary(
            firstType,
            from,
            value,
            fee
        );

        transfer(firstType, restValue, from, to);
    }

    function transferFeeToBeneficiary(
        Asset memory asset,
        address from,
        uint256 total,
        uint256 fee
    ) internal returns (uint256) {
        (uint256 restValue, uint256 restFee) = subFeeInBp(total, fee);

        if (restFee > 0) {
            transfer(asset, restFee, from, beneficiary);
        }

        return restValue;
    }

    function emitBuy(
        Order memory order,
        uint256 amount,
        address buyer
    ) internal {
        emit Buy(
            order.key.sellAsset.token,
            order.key.sellAsset.tokenId,
            order.selling,
            order.key.owner,
            order.key.buyAsset.token,
            order.key.buyAsset.tokenId,
            order.buying,
            buyer,
            amount,
            order.key.salt
        );
    }

    function subFeeInBp(
        uint256 value,
        uint256 feeInBp
    ) internal pure returns (uint256 newValue, uint256 realFee) {
        return subFee(value, value.bp(feeInBp));
    }

    function subFee(
        uint256 value,
        uint256 fee
    ) internal pure returns (uint256 newValue, uint256 realFee) {
        if (value > fee) {
            newValue = value - fee;
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }

    function verifyOpenAndModifyOrderState(
        OrderKey memory key,
        uint256 selling,
        uint256 amount
    ) internal {
        uint256 completed = state.getCompleted(key);
        uint256 newCompleted = completed + amount;

        require(
            newCompleted <= selling,
            "not enough stock of order for buying"
        );
        state.setCompleted(key, newCompleted);
    }

    function getFeeSide(
        AssetType sellType,
        AssetType buyType
    ) internal pure returns (FeeSide) {
        if ((sellType == AssetType.ERC721) && (buyType == AssetType.ERC721)) {
            return FeeSide.NONE;
        }
        if (sellType == AssetType.ERC721) {
            return FeeSide.BUY;
        }
        return FeeSide.SELL;
    }

    function _beforeExchange(
        Order calldata order,
        ECDSASig calldata sig,
        uint256 aliveUntil,
        ECDSASig calldata aliveUntilSig,
        uint256 amount,
        address buyer
    ) private {
        require(
            order.fee <= 100_00,
            "The order fee exceeds the allowable value!"
        );
        validateOrderSig(order, sig);
        validateAliveUntilSig(order, aliveUntil, aliveUntilSig);
        verifyOpenAndModifyOrderState(order.key, order.selling, amount);
    }

    /// @notice Event changing beneficiary
    /// @param newAddress new address beneficiary
    /// @param oldAddress old address beneficiary
    event ChangingBeneficiary(address newAddress, address oldAddress);

    /// @notice Event changing AliveUntilSigner
    /// @param newAddress new address beneficiary
    /// @param oldAddress old address beneficiary
    event ChangingAliveUntilSigner(address newAddress, address oldAddress);

    /// @notice Event changing ExchangeState
    /// @param newAddress new address beneficiary
    /// @param oldAddress old address beneficiary
    event ChangingExchangeState(address newAddress, address oldAddress);

    /// @notice Event changing ExchangeOrdersHolder
    /// @param newAddress new address beneficiary
    /// @param oldAddress old address beneficiary
    event ChangingExchangeOrdersHolder(address newAddress, address oldAddress);
}
