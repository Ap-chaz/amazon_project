let productsHTML = '';

window.addEventListener('DOMContentLoaded', () => {

  products.forEach((product) => {
    productsHTML += `
      <div class="product-container">

        <div class="product-image-container">
          <img class="product-image"
            src="${product.image}">
        </div>

        <div class="product-name limit-text-to-2-lines">
          ${product.name}
        </div>

        <div class="product-rating-container">
          <img class="product-rating-stars"
            src="images/ratings/rating-${product.rating.stars * 10}.png">
          <div class="product-rating-count link-primary">
            ${product.rating.count}
          </div>
        </div>

        <div class="product-price">
          $${(product.priceCents / 100).toFixed(2)}
        </div>

        <button class="add-to-cart-button button-primary js-add-to-cart"
          data-product-id="${product.id}">
          Add to Cart
        </button>

      </div>
    `;
  });


  document.querySelector('.js-products-grid').innerHTML = productsHTML;


  document.querySelectorAll('.js-add-to-cart')
    .forEach((button) => {

      button.addEventListener('click', () => {
        
        const productId = button.dataset.productId;
        console.log(productId);

      let matchingItem;

      cart.forEach((item) => {
        if (item.productId === productId) {
          matchingItem = item;
        }
      });

      if (matchingItem) {
        matchingItem.quantity += 1;
      } else {
        cart.push({
          productId: productId,
          quantity: 1
        });
      }

      console.log(cart);

    });

  });

});
  