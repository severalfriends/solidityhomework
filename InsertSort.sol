// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract InsertSort {
    function sort(int32[] memory arr) public pure returns (int32[] memory) {
        for (uint32 i = 1; i < arr.length; i++) {
            int32 key = arr[i];
            uint32 j = i - 1;
            bool t = false;

            while (j >= 0 && arr[j] > key) {
                arr[j + 1] = arr[j];
                if (j == 0) {
                    t = true;
                    break;
                }
                j--;
            }

            if (t) {
                arr[0] = key;
            } else {
                arr[j + 1] = key;
            }
        }
        return arr;
    }
}
