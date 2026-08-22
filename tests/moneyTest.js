import {formatCurrency} from "../scripts/utils/money.js";

formatCurrency(2095);

if (formatCurrency(2095) === `20.95`) {
  console.log('PASSED')
} else {
  console.log('FAILED')
}
  
  

