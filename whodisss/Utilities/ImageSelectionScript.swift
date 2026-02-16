import Foundation

enum ImageSelectionScript {
    static let messageHandlerName = "imageSelected"

    static let script = """
        if (window.imageSelectionHandler) {
            document.removeEventListener('click', window.imageSelectionHandler, true);
        }

        window.imageSelectionHandler = function(e) {
            var element = e.target;
            var resultsContainer = document.querySelector('#islrg') || document.querySelector('.islrc');
            var ignoreSelectors = [
                'form[role="search"]',
                'form[action*="/search"]',
                'div[role="search"]',
                '#searchform',
                'input[type="text"]',
                'input[type="search"]',
                'textarea',
                'button',
                '[aria-label*="Clear"]',
                '[aria-label*="Search"]',
                '[aria-label*="clear"]',
                '[aria-label*="search"]'
            ];

            for (var i = 0; i < ignoreSelectors.length; i++) {
                if (element.closest && element.closest(ignoreSelectors[i])) {
                    return;
                }
            }

            if (resultsContainer && !resultsContainer.contains(element)) {
                return;
            }
            var imageUrl = null;

            var currentElement = element;
            while (currentElement && !imageUrl) {
                if (currentElement.tagName === 'IMG') {
                    imageUrl = currentElement.src;
                    break;
                }

                var style = window.getComputedStyle(currentElement);
                var backgroundImage = style.backgroundImage;
                if (backgroundImage && backgroundImage !== 'none') {
                    var match = backgroundImage.match(/url\\("(.+?)"\\)/);
                    if (match) {
                        imageUrl = match[1];
                        break;
                    }
                }

                var imgChild = currentElement.querySelector('img');
                if (imgChild) {
                    imageUrl = imgChild.src;
                    break;
                }

                currentElement = currentElement.parentElement;
            }

            if (imageUrl) {
                e.preventDefault();
                e.stopPropagation();
                window.webkit.messageHandlers.\(messageHandlerName).postMessage(imageUrl);
            }
        };

        document.addEventListener('click', window.imageSelectionHandler, true);
    """
}
