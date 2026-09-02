import {formatCurrency} from "../scripts/utils/money.js";

console.log("Test Suite: formatCurrency");

 console.log("Converts Cents to Dollars");

if (formatCurrency(2095) === "20.95") {
    console.log("formatCurrency test passed");
} else {
    console.log("formatCurrency test failed");s
}

console.log("Works with 0");

if (formatCurrency(0) === "0.00") {
    console.log("formatCurrency test passed");
} else {
    console.log("formatCurrency test failed");
}

console.log("Rounds up to nearest cent");

if (formatCurrency(2000.5) === "20.01") {
    console.log("formatCurrency test passed");
} else {
    console.log("formatCurrency test failed");
}

console.log("Rounds down to nearest cent");

if (formatCurrency(2000.4) === "20.00") {
    console.log("formatCurrency test passed");
} else {
    console.log("formatCurrency test failed");
}