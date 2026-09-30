(function () {
    'use strict';

    function isBuilderOrPreview() {
        var href = (window.location.href || '').toLowerCase();
        var path = (window.location.pathname || '').toLowerCase();
        var host = (window.location.hostname || '').toLowerCase();

        if (host.indexOf('builder.') !== -1) {
            return true;
        }
        if (
            href.indexOf('commeditor.jsp') !== -1 ||
            href.indexOf('experiencebuilder') !== -1 ||
            href.indexOf('live-preview') !== -1 ||
            href.indexOf('sitepreview') !== -1 ||
            href.indexOf('sfsites/c/cms') !== -1 ||
            href.indexOf('/cms/editor') !== -1 ||
            href.indexOf('.preview.') !== -1 ||
            path.indexOf('/cms/') !== -1 ||
            path.indexOf('/editor') !== -1
        ) {
            return true;
        }

        try {
            if (window.self !== window.top) {
                var parentHref = (window.parent.location.href || '').toLowerCase();
                if (
                    parentHref.indexOf('cms') !== -1 ||
                    parentHref.indexOf('editor') !== -1 ||
                    parentHref.indexOf('builder') !== -1 ||
                    parentHref.indexOf('experiencebuilder') !== -1
                ) {
                    return true;
                }
            }
        } catch (e) {
            return true;
        }

        return false;
    }

    function isLiveCategoryPage() {
        if (isBuilderOrPreview()) {
            return false;
        }
        var href = (window.location.href || '').toLowerCase();
        var path = (window.location.pathname || '').toLowerCase();
        if (href.indexOf('detail-01t') !== -1 || path.indexOf('/product/') !== -1) {
            return false;
        }
        return href.indexOf('detail-0zg') !== -1 || path.indexOf('/category/') !== -1;
    }

    if (!isLiveCategoryPage()) {
        return;
    }

    if (window.__dealerCardEnhanceBooted) {
        return;
    }
    window.__dealerCardEnhanceBooted = true;

    var BULLETS = [
        'Includes premium attachments',
        'Advanced cleaning power',
        'Lightweight and versatile',
        'Professional-grade results'
    ];
    var RETRY_DELAYS_MS = [0, 500, 1500, 3000, 6000];
    var cardIndex = 0;

    function walkDeep(node, visit) {
        if (!node) {
            return;
        }
        visit(node);
        if (node.shadowRoot) {
            walkDeep(node.shadowRoot, visit);
        }
        if (node.children) {
            Array.prototype.forEach.call(node.children, function (child) {
                walkDeep(child, visit);
            });
        }
    }

    function isModelLine(el) {
        if (!el || el.dataset.dealerDone) {
            return false;
        }
        if (el.querySelector && el.querySelector('.dealer-card-rating')) {
            return false;
        }
        var text = (el.textContent || '').trim();
        return /^Model:\s*\S/.test(text) && text.length < 60;
    }

    function isInnermostModel(candidates, el) {
        for (var i = 0; i < candidates.length; i += 1) {
            if (candidates[i] !== el && candidates[i].contains(el)) {
                return false;
            }
        }
        return true;
    }

    function isAddToCart(el) {
        if (!el || el.nodeType !== 1) {
            return false;
        }
        var tag = el.tagName;
        if (tag !== 'A' && tag !== 'BUTTON') {
            return false;
        }
        return /add to cart/i.test(el.textContent || '');
    }

    function enhanceImage(img) {
        var wrap = img.parentElement;
        if (!wrap || wrap.classList.contains('dealer-img-wrap')) {
            return;
        }
        wrap.classList.add('dealer-img-wrap');
        if (wrap.querySelector('.dealer-badge')) {
            return;
        }
        cardIndex += 1;
        var badge = document.createElement('span');
        badge.className = 'dealer-badge dealer-badge--new';
        badge.textContent = 'New';
        if (cardIndex % 4 === 3) {
            badge.className = 'dealer-badge dealer-badge--sale';
            badge.textContent = 'Sale';
        } else if (cardIndex % 4 === 2 || cardIndex % 4 === 0) {
            badge.style.display = 'none';
        }
        wrap.insertBefore(badge, wrap.firstChild);
    }

    function enhanceModel(el) {
        el.dataset.dealerDone = '1';

        var rating = document.createElement('div');
        rating.className = 'dealer-card-rating';
        rating.textContent = '\u2605\u2605\u2605\u2605\u2605  4.8  (54)  \u2304';
        el.insertAdjacentElement('afterend', rating);

        var bullets = document.createElement('ul');
        bullets.className = 'dealer-card-bullets';
        BULLETS.forEach(function (text) {
            var li = document.createElement('li');
            li.textContent = text;
            bullets.appendChild(li);
        });
        rating.insertAdjacentElement('afterend', bullets);

        var promo = document.createElement('div');
        promo.className = 'dealer-card-promo';
        promo.textContent = 'Exclusive offer applied in cart';
        bullets.insertAdjacentElement('afterend', promo);
    }

    function run() {
        if (!isLiveCategoryPage()) {
            return;
        }

        var models = [];
        walkDeep(document.body, function (node) {
            if (node.nodeType === 1 && isModelLine(node)) {
                models.push(node);
            }
        });

        if (models.length === 0) {
            return;
        }

        walkDeep(document.body, function (node) {
            if (node.nodeType !== 1) {
                return;
            }
            if (node.tagName === 'IMG') {
                enhanceImage(node);
            }
            if (models.indexOf(node) !== -1 && isInnermostModel(models, node)) {
                enhanceModel(node);
            }
            if (isAddToCart(node) && !node.classList.contains('dealer-pill-btn')) {
                node.classList.add('dealer-pill-btn');
            }
        });
    }

    function boot() {
        if (!isLiveCategoryPage()) {
            return;
        }
        RETRY_DELAYS_MS.forEach(function (delay) {
            setTimeout(run, delay);
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', boot);
    } else {
        boot();
    }
})();
