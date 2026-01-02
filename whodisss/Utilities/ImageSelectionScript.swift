import Foundation

enum ImageSelectionScript {
    static let messageHandlerName = "imageSelected"

    static let script = """
        if (window.imageSelectionHandler) {
            document.removeEventListener('click', window.imageSelectionHandler, true);
        }

        window.imageSelectionHandler = function(e) {
            var element = e.target;
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
