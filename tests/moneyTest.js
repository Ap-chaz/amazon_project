import {formatCurrency} from "../scripts/utils/money.js";

const result1 = formatCurrency(2095) === `20.95` ? 'PASSED' : 'FAILED';
const result2 = formatCurrency(0) === `0.00` ? 'PASSED' : 'FAILED';
const result3 = formatCurrency(2000.5) === `20.01` ? 'PASSED' : 'FAILED';
const result4 = formatCurrency(2000.4) === `20.00` ? 'PASSED' : 'FAILED';

document.body.innerHTML = `
  <h1 style="font-family: sans-serif; font-size: 40px;">Test 1: ${result1}</h1>
  <h1 style="font-family: sans-serif; font-size: 40px;">Test 2: ${result2}</h1>
  <h1 style="font-family: sans-serif; font-size: 40px;">Test 3: ${result3}</h1>
  <h1 style="font-family: sans-serif; font-size: 40px;">Test 4: ${result4}</h1>
`;