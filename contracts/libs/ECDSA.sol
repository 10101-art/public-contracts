// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    function recover(
        bytes32 message,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool isEthSignedMessage
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(
            message,
            v,
            r,
            s,
            isEthSignedMessage
        );

        _throwError(error);

        return recovered;
    }

    function tryRecover(
        bytes32 message,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool isEthSignedMessage
    ) private pure returns (address, RecoverError) {
        uint256 signatureSMaxValue = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;

        if (uint256(s) > signatureSMaxValue) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        bytes32 hashSigned = isEthSignedMessage
            ? toEthSignedMessageHash(message)
            : message;

        address signer = ecrecover(hashSigned, v, r, s);

        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    function toEthSignedMessageHash(
        bytes32 message
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
            );
    }
}
