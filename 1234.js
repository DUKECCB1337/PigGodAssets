// 1234.js - Cookie Manager Modal
(function() {
    if (window.cookieManagerLoaded) {
        toggleCookieManager();
        return;
    }
    window.cookieManagerLoaded = true;

    // 创建模态框
    const modal = document.createElement('div');
    modal.id = 'cookie-manager-modal';
    modal.style.cssText = `
        position: fixed; top: 0; left: 0; width: 100%; height: 100%; 
        background: rgba(0,0,0,0.85); z-index: 2147483647; 
        display: flex; align-items: center; justify-content: center;
        font-family: system-ui, -apple-system, sans-serif; color: #fff;
    `;

    modal.innerHTML = `
        <div style="background:#1f2937; border-radius:12px; width:90%; max-width:720px; max-height:90vh; overflow:hidden; display:flex; flex-direction:column; box-shadow:0 20px 40px rgba(0,0,0,0.5);">
            <!-- 头部 -->
            <div style="padding:16px 20px; border-bottom:1px solid #374151; display:flex; justify-content:space-between; align-items:center; background:#111827;">
                <h2 style="margin:0; font-size:18px;">🍪 Cookie 管理器</h2>
                <div style="display:flex; gap:8px;">
                    <button id="btn-refresh" style="padding:6px 12px; background:#374151; border:none; border-radius:6px; color:#fff; cursor:pointer;">刷新</button>
                    <button id="btn-add" style="padding:6px 12px; background:#3b82f6; border:none; border-radius:6px; color:#fff; cursor:pointer;">新增 Cookie</button>
                    <button id="btn-close" style="padding:6px 12px; background:#ef4444; border:none; border-radius:6px; color:#fff; cursor:pointer;">关闭</button>
                </div>
            </div>
            
            <!-- 内容 -->
            <div style="flex:1; overflow:auto; padding:16px;" id="cookie-list">
                <!-- 动态填充 -->
            </div>
            
            <!-- 底部提示 -->
            <div style="padding:12px 20px; font-size:12px; color:#9ca3af; border-top:1px solid #374151;">
                注意：修改仅影响当前页面域名 • 部分Cookie可能因HttpOnly无法修改
            </div>
        </div>
    `;

    document.body.appendChild(modal);

    let currentCookies = {};

    function parseCookies() {
        const cookies = {};
        document.cookie.split(';').forEach(cookie => {
            const [name, ...rest] = cookie.trim().split('=');
            if (name) {
                cookies[name] = rest.join('=');
            }
        });
        return cookies;
    }

    function renderCookies() {
        currentCookies = parseCookies();
        const container = document.getElementById('cookie-list');
        let html = `
            <table style="width:100%; border-collapse:collapse;">
                <thead>
                    <tr style="background:#111827;">
                        <th style="text-align:left; padding:10px; border-bottom:1px solid #374151;">名称</th>
                        <th style="text-align:left; padding:10px; border-bottom:1px solid #374151;">值</th>
                        <th style="width:160px; border-bottom:1px solid #374151;">操作</th>
                    </tr>
                </thead>
                <tbody>
        `;

        if (Object.keys(currentCookies).length === 0) {
            html += `<tr><td colspan="3" style="text-align:center; padding:40px; color:#9ca3af;">当前页面没有Cookie</td></tr>`;
        } else {
            Object.entries(currentCookies).forEach(([name, value]) => {
                const shortValue = value.length > 60 ? value.substring(0, 57) + '...' : value;
                html += `
                    <tr style="border-bottom:1px solid #374151;">
                        <td style="padding:10px; font-weight:500;">${escapeHtml(name)}</td>
                        <td style="padding:10px; word-break:break-all; font-size:13px;">${escapeHtml(shortValue)}</td>
                        <td style="padding:10px;">
                            <button onclick="copyCookie('${escapeHtml(name)}')" style="margin-right:4px; padding:4px 8px; font-size:12px; background:#10b981;">复制</button>
                            <button onclick="editCookie('${escapeHtml(name)}')" style="margin-right:4px; padding:4px 8px; font-size:12px; background:#3b82f6;">修改</button>
                            <button onclick="deleteCookie('${escapeHtml(name)}')" style="padding:4px 8px; font-size:12px; background:#ef4444;">删除</button>
                        </td>
                    </tr>
                `;
            });
        }

        html += `</tbody></table>`;
        container.innerHTML = html;
    }

    function escapeHtml(unsafe) {
        return unsafe
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    // 全局函数供 onclick 调用
    window.copyCookie = function(name) {
        const value = currentCookies[name];
        if (!value) return;
        navigator.clipboard.writeText(`\( {name}= \){value}`).then(() => {
            showToast(`已复制: ${name}`);
        });
    };

    window.editCookie = function(name) {
        const value = currentCookies[name] || '';
        const newValue = prompt(`修改 Cookie "${name}" 的值：`, value);
        if (newValue !== null) {
            setCookie(name, newValue);
            renderCookies();
            showToast(`已更新 Cookie: ${name}`);
        }
    };

    window.deleteCookie = function(name) {
        if (confirm(`确定要删除 Cookie "${name}" 吗？`)) {
            document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/`;
            renderCookies();
            showToast(`已删除 Cookie: ${name}`);
        }
    };

    function setCookie(name, value) {
        // 基础设置，尽量持久化
        document.cookie = `\( {name}= \){value}; path=/; max-age=31536000`;
    }

    function showToast(msg) {
        const toast = document.createElement('div');
        toast.style.cssText = `
            position:fixed; bottom:20px; left:50%; transform:translateX(-50%);
            background:#10b981; color:white; padding:12px 24px; border-radius:8px;
            z-index:2147483647; box-shadow:0 10px 15px rgba(0,0,0,0.3);
        `;
        toast.textContent = msg;
        document.body.appendChild(toast);
        setTimeout(() => toast.remove(), 2000);
    }

    // 新增 Cookie
    function addNewCookie() {
        const name = prompt('请输入 Cookie 名称：');
        if (!name) return;
        const value = prompt('请输入 Cookie 值：', '');
        if (value !== null) {
            setCookie(name, value);
            renderCookies();
            showToast(`已新增 Cookie: ${name}`);
        }
    }

    // 事件绑定
    function bindEvents() {
        document.getElementById('btn-refresh').onclick = renderCookies;
        document.getElementById('btn-add').onclick = addNewCookie;
        document.getElementById('btn-close').onclick = () => modal.remove();
        
        // 点击背景关闭
        modal.addEventListener('click', (e) => {
            if (e.target === modal) modal.remove();
        });
    }

    // 初始化
    function init() {
        renderCookies();
        bindEvents();
        
        // 按 ESC 关闭
        document.addEventListener('keydown', function handler(e) {
            if (e.key === 'Escape') {
                modal.remove();
                document.removeEventListener('keydown', handler);
            }
        });
    }

    function toggleCookieManager() {
        const existing = document.getElementById('cookie-manager-modal');
        if (existing) {
            existing.remove();
        } else {
            init();
        }
    }

    // 启动
    init();

    console.log('%cCookie Manager 已加载 ✓', 'color:#10b981; font-size:14px;');
})();
