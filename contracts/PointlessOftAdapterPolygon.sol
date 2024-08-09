// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IERC20Metadata, IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { OFTAdapter } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTAdapter.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract PointlessOftAdapterPolygon is OFTAdapter {
    using SafeERC20 for IERC20;
    
    // below are the default values, we can change these using the setter functions.
    uint256 public bridgeFeeTreasury = 500000 * 10 ** 18; 
    uint256 public bridgeFeeBurned = 2000000 * 10 ** 18;
    address public treasuryAddress = 0x810B93F0DEc3a84AA3B8a210D033858fbEE41204; // pointless treasury
    address public constant polygonBurnAddress = 0x000000000000000000000000000000000000dEaD;

     constructor(
        address _tokenAddress,
        address _lzEndpoint,
        address _delegate
    ) OFTAdapter(_tokenAddress, _lzEndpoint, _delegate) Ownable(_delegate) {}

    // @dev allows the quote functions to mock sending the actual values that would be sent in a send()
    function _debitView(
        uint256 _amountLD,
        uint256 /*_minAmountLD*/,
        uint32 /*_dstEid*/
    ) internal view override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        
        uint256 totalFee = bridgeFeeTreasury + bridgeFeeBurned;
        
        // @dev Remove the dust so nothing is lost on the conversion between chains with different decimals for the token.
        amountSentLD = _removeDust(_amountLD);
        if(amountSentLD <= totalFee)
        {
            revert("not enough pointless to send.");
        }

        amountReceivedLD = amountSentLD - totalFee;
    }

    /**
     * @dev Burns/locks tokens from the sender's specified balance, ie. pull method.
     * @param _from The address to debit from.
     * @param _amountLD The amount of tokens to send in local decimals.
     * @param _minAmountLD The minimum amount to send in local decimals.
     * @param _dstEid The destination chain ID.
     * @return amountSentLD The amount sent in local decimals.
     * @return amountReceivedLD The amount received in local decimals on the remote.
     *
     * @dev msg.sender will need to approve this _amountLD of tokens to be locked inside of the contract.
     * @dev WARNING: The default OFTAdapter implementation assumes LOSSLESS transfers, ie. 1 token in, 1 token out.
     * IF the 'innerToken' applies something like a transfer fee, the default will NOT work...
     * a pre/post balance check will need to be done to calculate the amountReceivedLD.
     */
    function _debit(
        address _from,
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    ) internal override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);
        // @dev Lock tokens by moving them into this contract from the caller.
        innerToken.safeTransferFrom(_from, address(this), amountReceivedLD);
        
        // @dev send the treasuryTax amount to the pointless treasury
        innerToken.safeTransferFrom(_from, treasuryAddress, bridgeFeeTreasury);
        
        // @dev burn a portion of the custom fee
        innerToken.safeTransferFrom(_from, polygonBurnAddress, bridgeFeeBurned);
    }

    function setBridgeFeeTreasury(uint256 newBridgeFeeTreasury) public onlyOwner {
        bridgeFeeTreasury = newBridgeFeeTreasury;
    }

    function setTreasuryAddress(address newTreasuryAddress) public onlyOwner {
        treasuryAddress = newTreasuryAddress;
    }

    function setBridgeFeeBurned(uint256 newBridgeFeeBurned) public onlyOwner {
        bridgeFeeBurned = newBridgeFeeBurned;
    }
}
