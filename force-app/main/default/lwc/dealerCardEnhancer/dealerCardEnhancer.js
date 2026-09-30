import { LightningElement } from 'lwc';

const LOADED_FLAG = '__dealerCardEnhanceRequested';

export default class DealerCardEnhancer extends LightningElement {
    connectedCallback() {
        if (!this._shouldLoad()) {
            return;
        }
        if (window[LOADED_FLAG]) {
            return;
        }
        window[LOADED_FLAG] = true;

        const basePath = this._getBasePath();
        if (!basePath) {
            return;
        }

        const oasis = document.createElement('x-oasis-script');
        oasis.src = `${basePath}/sfsites/c/resource/DealerCardEnhance`;
        document.head.appendChild(oasis);
    }

    _shouldLoad() {
        if (this._isBuilderOrPreview()) {
            return false;
        }
        return this._isCategoryPage();
    }

    _isBuilderOrPreview() {
        const href = window.location.href.toLowerCase();
        const path = window.location.pathname.toLowerCase();
        const host = window.location.hostname.toLowerCase();

        if (host.includes('builder.')) {
            return true;
        }
        if (
            href.includes('commeditor.jsp') ||
            href.includes('experiencebuilder') ||
            href.includes('live-preview') ||
            href.includes('sitepreview') ||
            href.includes('sfsites/c/cms') ||
            href.includes('/cms/editor') ||
            href.includes('.preview.') ||
            path.includes('/cms/') ||
            path.includes('/editor')
        ) {
            return true;
        }

        try {
            if (window.self !== window.top) {
                const parentHref = window.parent.location.href.toLowerCase();
                if (
                    parentHref.includes('cms') ||
                    parentHref.includes('editor') ||
                    parentHref.includes('builder') ||
                    parentHref.includes('experiencebuilder')
                ) {
                    return true;
                }
            }
        } catch (e) {
            return true;
        }

        return false;
    }

    _isCategoryPage() {
        const href = window.location.href.toLowerCase();
        const path = window.location.pathname.toLowerCase();
        if (href.includes('detail-01t') || path.includes('/product/')) {
            return false;
        }
        return href.includes('detail-0zg') || path.includes('/category/');
    }

    _getBasePath() {
        const theme = document.querySelector('link[href*="theme2.css"]');
        if (theme?.href) {
            try {
                const url = new URL(theme.href);
                const match = url.pathname.match(/^(\/.+?)\/assets\/css\/theme2\.css/);
                if (match) {
                    return match[1];
                }
            } catch (e) {
                // fall through
            }
        }

        const parts = window.location.pathname.split('/').filter(Boolean);
        if (parts.length > 0) {
            return `/${parts[0]}`;
        }
        return '';
    }
}
