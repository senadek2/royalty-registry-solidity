// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./IRoyaltyRegistry.sol";
import "./specs/INiftyGateway.sol";

/**
 * @dev Registry to lookup royalty configurations
 */
contract RoyaltyRegistry is ERC165, OwnableUpgradeable, IRoyaltyRegistry {
    using AddressUpgradeable for address;

    // Override addresses
    mapping (address => address) private _overrides;

    function initialize() public initializer {
        __Ownable_init_unchained();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRoyaltyRegistry).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IRegistry-setRoyaltyLookupAddress}.
     */
    function setRoyaltyLookupAddress(address tokenAddress, address royaltyLookupAddress) public override {
        require(tokenAddress.isContract() && (royaltyLookupAddress.isContract() || royaltyLookupAddress == address(0)), "Invalid input");
        require(_overrideAllowed(tokenAddress), "Permission denied");
        _overrides[tokenAddress] = royaltyLookupAddress;
        emit RoyaltyOverride(_msgSender(), tokenAddress, royaltyLookupAddress);
    }

    /**
     * Function to check whether or not the message sender is allowed to override the royalty lookup location of the given token address
     */
    function _overrideAllowed(address tokenAddress) private view returns(bool) {
        if (owner() == _msgSender()) return true;
        if (OwnableUpgradeable(tokenAddress).owner() == _msgSender()) return true;

        // Nifty Gateway overrides
        try INiftyBuilderInstance(tokenAddress).niftyRegistryContract() returns (address niftyRegistry) {
            try INiftyRegistry(niftyRegistry).isValidNiftySender(_msgSender()) returns (bool valid) {
                return valid;
            } catch {}
        } catch {}

        // OpenSea overrides
        // TODO

        // Foundation overrides
        // TODO

        // Superrare overrides
        // TODO

        // Rarible overrides
        // Tokens already support Ownable

        return false;
    }

    /**
     * @dev See {IRegistry-getRoyaltyLookupAddress}.
     */
    function getRoyaltyLookupAddress(address tokenAddress) external view override returns(address) {
        address override_ = _overrides[tokenAddress];
        if (override_ != address(0)) return override_;
        return tokenAddress;
    }

}