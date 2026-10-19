(() => {
    const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'kairo-bridge';

    // SVG Icons
    const ICONS = {
        info: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>`,
        success: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>`,
        warning: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>`,
        error: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>`,
        interact: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>`,
    };

    function post(endpoint, data = {}) {
        return fetch(`https://${resourceName}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data),
        }).catch(() => {});
    }

    // =========================================================================
    // Notifications
    // =========================================================================
    const notifyContainer = document.getElementById('notify-container');

    function showNotify(data) {
        const type = data.type || 'info';
        const title = data.title || (type.charAt(0).toUpperCase() + type.slice(1));
        const description = data.description || data.message || '';
        const duration = Number(data.duration) || 4000;

        const card = document.createElement('div');
        card.className = `notify-card ${type}`;

        const iconSvg = ICONS[type] || ICONS.info;

        card.innerHTML = `
            <div class="notify-main">
                <div class="notify-icon">${iconSvg}</div>
                <div class="notify-body">
                    <div class="notify-title">${escapeHtml(title)}</div>
                    ${description ? `<div class="notify-desc">${escapeHtml(description)}</div>` : ''}
                </div>
            </div>
            <div class="notify-meter">
                <div class="notify-meter-fill"></div>
            </div>
        `;

        notifyContainer.appendChild(card);

        // Slide in
        requestAnimationFrame(() => {
            card.classList.add('show');
            const fill = card.querySelector('.notify-meter-fill');
            fill.style.transition = `width ${duration}ms linear`;
            requestAnimationFrame(() => {
                fill.style.width = '0%';
            });
        });

        setTimeout(() => {
            card.classList.remove('show');
            card.classList.add('hide');
            setTimeout(() => {
                if (card.parentNode) card.parentNode.removeChild(card);
            }, 350);
        }, duration);
    }

    // =========================================================================
    // TextUI
    // =========================================================================
    const textuiContainer = document.getElementById('textui-container');
    const textuiKey = document.getElementById('textui-key');
    const textuiIcon = document.getElementById('textui-icon');
    const textuiLabel = document.getElementById('textui-label');

    function showTextUI(data) {
        textuiLabel.textContent = data.text || 'Interact';
        textuiKey.textContent = data.key || 'E';
        textuiIcon.innerHTML = ICONS.interact;
        textuiContainer.classList.remove('hidden');
    }

    function hideTextUI() {
        textuiContainer.classList.add('hidden');
    }

    // =========================================================================
    // Progress Bar
    // =========================================================================
    const progressContainer = document.getElementById('progress-container');
    const progressLabel = document.getElementById('progress-label');
    const progressPercent = document.getElementById('progress-percent');
    const progressFill = document.getElementById('progress-fill');

    let progressInterval = null;

    function startProgressBar(data) {
        clearInterval(progressInterval);
        const duration = Number(data.duration) || 3000;
        const label = data.label || 'Processing...';

        progressLabel.textContent = label;
        progressPercent.textContent = '0%';
        progressFill.style.width = '0%';
        progressContainer.classList.remove('hidden');

        const startTime = Date.now();

        progressInterval = setInterval(() => {
            const elapsed = Date.now() - startTime;
            const pct = Math.min(100, Math.floor((elapsed / duration) * 100));
            progressPercent.textContent = `${pct}%`;
            progressFill.style.width = `${pct}%`;

            if (pct >= 100) {
                clearInterval(progressInterval);
                progressInterval = null;
                setTimeout(() => {
                    progressContainer.classList.add('hidden');
                    post('progressComplete');
                }, 150);
            }
        }, 30);
    }

    function cancelProgressBar() {
        if (progressInterval) {
            clearInterval(progressInterval);
            progressInterval = null;
            progressContainer.classList.add('hidden');
            post('progressCancel');
        }
    }

    // =========================================================================
    // Modals
    // =========================================================================
    const backdrop = document.getElementById('modal-backdrop');
    let activeModal = null;

    function closeModal() {
        if (!activeModal) return;
        activeModal.classList.add('hidden');
        backdrop.classList.add('hidden');
        const prev = activeModal;
        activeModal = null;
        return prev;
    }

    // Alert Modal
    const alertModal = document.getElementById('alert-modal');
    const alertHeader = document.getElementById('alert-header');
    const alertContent = document.getElementById('alert-content');
    const alertIcon = document.getElementById('alert-icon');
    const alertConfirmBtn = document.getElementById('alert-confirm-btn');
    const alertCancelBtn = document.getElementById('alert-cancel-btn');

    function openAlert(data) {
        closeModal();
        alertHeader.textContent = data.header || 'Confirmation';
        alertContent.textContent = data.content || '';
        alertConfirmBtn.textContent = data.confirmText || 'Confirm';
        alertCancelBtn.textContent = data.cancelText || 'Cancel';
        if (data.cancel === false) {
            alertCancelBtn.classList.add('hidden');
        } else {
            alertCancelBtn.classList.remove('hidden');
        }
        alertIcon.innerHTML = ICONS.warning;

        alertModal.classList.remove('hidden');
        backdrop.classList.remove('hidden');
        activeModal = alertModal;
    }

    alertConfirmBtn.addEventListener('click', () => {
        closeModal();
        post('alertConfirm');
    });

    alertCancelBtn.addEventListener('click', () => {
        closeModal();
        post('alertCancel');
    });

    // Input Modal
    const inputModal = document.getElementById('input-modal');
    const inputHeader = document.getElementById('input-header');
    const inputForm = document.getElementById('input-form');
    const inputCloseBtn = document.getElementById('input-close-btn');
    const inputCancelBtn = document.getElementById('input-cancel-btn');
    const inputSubmitBtn = document.getElementById('input-submit-btn');

    let currentInputRows = [];

    function openInput(data) {
        closeModal();
        inputHeader.textContent = data.header || 'Dialog';
        inputForm.innerHTML = '';
        currentInputRows = data.rows || [];

        currentInputRows.forEach((row, idx) => {
            const group = document.createElement('div');
            group.className = 'input-group';

            const labelText = row.label || `Field ${idx + 1}`;
            const rowType = row.type || 'input';

            if (rowType === 'checkbox') {
                const label = document.createElement('label');
                label.className = 'checkbox-row';
                const input = document.createElement('input');
                input.type = 'checkbox';
                input.checked = !!row.default;
                input.id = `input-field-${idx}`;
                const span = document.createElement('span');
                span.className = 'input-label';
                span.textContent = labelText;
                label.appendChild(input);
                label.appendChild(span);
                group.appendChild(label);
            } else if (rowType === 'select') {
                const label = document.createElement('label');
                label.className = 'input-label';
                label.textContent = labelText;
                const select = document.createElement('select');
                select.className = 'form-control';
                select.id = `input-field-${idx}`;

                (row.options || []).forEach((opt) => {
                    const option = document.createElement('option');
                    if (typeof opt === 'object') {
                        option.value = opt.value;
                        option.textContent = opt.label || opt.value;
                    } else {
                        option.value = opt;
                        option.textContent = opt;
                    }
                    if (option.value === row.default) option.selected = true;
                    select.appendChild(option);
                });
                group.appendChild(label);
                group.appendChild(select);
            } else if (rowType === 'textarea') {
                const label = document.createElement('label');
                label.className = 'input-label';
                label.textContent = labelText;
                const textarea = document.createElement('textarea');
                textarea.className = 'form-control';
                textarea.id = `input-field-${idx}`;
                textarea.placeholder = row.placeholder || '';
                textarea.value = row.default !== undefined ? row.default : '';
                group.appendChild(label);
                group.appendChild(textarea);
            } else {
                const label = document.createElement('label');
                label.className = 'input-label';
                label.textContent = labelText;
                const input = document.createElement('input');
                input.className = 'form-control';
                input.id = `input-field-${idx}`;
                input.type = rowType === 'number' ? 'number' : (rowType === 'password' ? 'password' : 'text');
                input.placeholder = row.placeholder || '';
                input.value = row.default !== undefined ? row.default : '';
                if (row.min !== undefined) input.min = row.min;
                if (row.max !== undefined) input.max = row.max;
                group.appendChild(label);
                group.appendChild(input);
            }

            inputForm.appendChild(group);
        });

        inputModal.classList.remove('hidden');
        backdrop.classList.remove('hidden');
        activeModal = inputModal;

        const firstInput = inputForm.querySelector('input, textarea, select');
        if (firstInput) firstInput.focus();
    }

    function submitInput() {
        const values = [];
        currentInputRows.forEach((row, idx) => {
            const el = document.getElementById(`input-field-${idx}`);
            if (!el) {
                values.push(null);
                return;
            }
            if (row.type === 'checkbox') {
                values.push(el.checked);
            } else if (row.type === 'number') {
                values.push(el.value === '' ? null : Number(el.value));
            } else {
                values.push(el.value);
            }
        });
        closeModal();
        post('inputSubmit', { values });
    }

    inputSubmitBtn.addEventListener('click', submitInput);
    inputCloseBtn.addEventListener('click', () => {
        closeModal();
        post('inputCancel');
    });
    inputCancelBtn.addEventListener('click', () => {
        closeModal();
        post('inputCancel');
    });

    // Context Menu
    const menuModal = document.getElementById('menu-modal');
    const menuTitle = document.getElementById('menu-title');
    const menuSubtitle = document.getElementById('menu-subtitle');
    const menuBackBtn = document.getElementById('menu-back-btn');
    const menuCloseBtn = document.getElementById('menu-close-btn');
    const menuOptions = document.getElementById('menu-options');

    let currentMenuData = null;

    function openMenu(data) {
        closeModal();
        currentMenuData = data;
        menuTitle.textContent = data.title || 'Menu';
        if (data.subtitle) {
            menuSubtitle.textContent = data.subtitle;
            menuSubtitle.classList.remove('hidden');
        } else {
            menuSubtitle.classList.add('hidden');
        }

        if (data.parent) {
            menuBackBtn.classList.remove('hidden');
        } else {
            menuBackBtn.classList.add('hidden');
        }

        menuOptions.innerHTML = '';
        (data.options || []).forEach((opt, idx) => {
            const item = document.createElement('div');
            item.className = `menu-item ${opt.disabled ? 'disabled' : ''}`;

            item.innerHTML = `
                <div class="menu-item-left">
                    <div class="menu-item-icon">${ICONS.interact}</div>
                    <div class="menu-item-text">
                        <div class="menu-item-title">${escapeHtml(opt.title || `Option ${idx + 1}`)}</div>
                        ${opt.description ? `<div class="menu-item-desc">${escapeHtml(opt.description)}</div>` : ''}
                    </div>
                </div>
                <div class="menu-item-arrow">&#8250;</div>
            `;

            if (!opt.disabled) {
                item.addEventListener('click', () => {
                    closeModal();
                    post('menuSelect', { id: data.id, index: idx + 1, args: opt.args });
                });
            }

            menuOptions.appendChild(item);
        });

        menuModal.classList.remove('hidden');
        backdrop.classList.remove('hidden');
        activeModal = menuModal;
    }

    menuCloseBtn.addEventListener('click', () => {
        closeModal();
        post('menuClose');
    });
    menuBackBtn.addEventListener('click', () => {
        closeModal();
        post('menuClose', { back: true });
    });

    // ESC Handler
    window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            if (activeModal === inputModal) {
                closeModal();
                post('inputCancel');
            } else if (activeModal === menuModal) {
                closeModal();
                post('menuClose');
            } else if (activeModal === alertModal) {
                closeModal();
                post('alertCancel');
            }
        }
    });

    // Message Dispatcher
    window.addEventListener('message', (event) => {
        const item = event.data;
        if (!item || !item.action) return;

        switch (item.action) {
            case 'notify':
                showNotify(item.data || {});
                break;
            case 'showTextUI':
                showTextUI(item.data || {});
                break;
            case 'hideTextUI':
                hideTextUI();
                break;
            case 'progressBar':
                startProgressBar(item.data || {});
                break;
            case 'cancelProgressBar':
                cancelProgressBar();
                break;
            case 'openInput':
                openInput(item.data || {});
                break;
            case 'openMenu':
                openMenu(item.data || {});
                break;
            case 'openAlert':
                openAlert(item.data || {});
                break;
            case 'close':
                closeModal();
                break;
        }
    });

    function escapeHtml(str) {
        if (!str) return '';
        const div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    }
})();
