import {formatCurrency} from "../scripts/utils/money.js";

if (formatCurrency(2095) === "20.95") {
    console.log("formatCurrency test passed");
} else {
    console.log("formatCurrency test failed");
}
 
if (formatCurrency(0) === "0.00") {
    console.log("formatCurrency test passed");
} else {
    console.log("formatCurrency test failed");
}

if (formatCurrency(2000.5) === "20.01") {
    console.log("formatCurrency test passed");
} else {
    console.log("formatCurrency test failed");
}

if (formatCurrency(2000.4) === "20.00") {
    console.log("formatCurrency test passed");
} else {
    console.log("formatCurrency test failed");
}