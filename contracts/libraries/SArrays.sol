// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "hardhat/console.sol";
/**
 * @dev Collection of functions related to array types.
 */
library SArrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    function findIndex(uint256[] storage array, uint256 element
    ) internal view returns (uint256) {
        if (array.length == 0) return 0;
        // console.log('findIndex %s %s %s',array.length, array[0], element);

        // Shortcut for the actual value
        if (element >= array[array.length-1])
            return (array.length-1);
        if (element < array[0]) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = array.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            //console.log('findIndex mid %s %s',mid, array[mid]);

            if (array[mid] <= element) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        //console.log('findIndex return min %s %s',min, array[min]);
        return min;
    }

    function findValue(uint256[] storage array, uint256 element
    ) internal view returns (uint256) {
        if (array.length == 0) return 0;
        // console.log('findValue %s %s %s',array.length, array[0], element);

        // Shortcut for the actual value
        if (element >= array[array.length-1])
            return (array[array.length-1]);
        if (element < array[0]) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = array.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            // console.log('findValue mid %s %s',mid, array[mid]);

            if (array[mid] <= element) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        // console.log('findValue return min %s %s',min, array[min]);
        return array[min];
    }


}
