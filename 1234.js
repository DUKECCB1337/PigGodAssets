// 1234.js - Cookie Manager (弹窗提醒版)
(function() {
    // 提取 showToast 到最前面，方便在初始化和切换时调用
    function showToast(msg) {
        const t = document.createElement('div');
        t.style.cssText = `position:fixed;bottom:20px;left:50%;transform:translateX(-50%);background:#10b981;color:#fff;padding:12px 24px;border-radius:8px;z-index:2147483647;box-shadow:0 4px 12px rgba(0,0,0,0.3);font-family:system-ui,-apple-system,sans-serif;font-size:14px;`;
        t.textContent = msg;
        document.body.appendChild(t);
        setTimeout(() => t.remove(), 1800);
    }

    if (window.cookieManagerLoaded) {
        toggleCookieManager();
        return;
    }
    window.cookieManagerLoaded = true;

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
            <div style="padding:16px 20px; border-bottom:1px solid #374151; display:flex; justify-content:space-between; align-items:center; background:#111827;">
                <h2 style="margin:0; font-size:18px;">🍪 Cookie 管理器</h2>
                <div style="display:flex; gap:8px;">
                    <button id="btn-refresh" style="padding:6px 12px; background:#374151; border:none; border-radius:6px; color:#fff; cursor:pointer;">刷新</button>
                    <button id="btn-add" style="padding:6px 12px; background:#3b82f6; border:none; border-radius:6px; color:#fff; cursor:pointer;">新增 Cookie</button>
                    <button id="btn-close" style="padding:6px 12px; background:#ef4444; border:none; border-radius:6px; color:#fff; cursor:pointer;">关闭</button>
                </div>
            </div>
            
            <div style="flex:1; overflow:auto; padding:16px;" id="cookie-list"></div>
            
            <div style="padding:12px 20px; font-size:12px; color:#9ca3af; border-top:1px solid #374151;">
                注意：修改仅影响当前域名 • HttpOnly的Cookie无法修改
            </div>
        </div>
    `;

    document.body.appendChild(modal);

    let currentCookies = {};

    function parseCookies() {
        const cookies = {};
        document.cookie.split(';').forEach(c => {
            const [name, ...rest] = c.trim().split('=');
            if (name) cookies[name] = rest.join('=');
        });
        return cookies;
    }

    function escapeHtml(str) {
        return str.replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'})[m]);
    }

    function renderCookies() {
        currentCookies = parseCookies();
        const container = document.getElementById('cookie-list');
        let html = `<table style="width:100%; border-collapse:collapse;">
            <thead><tr style="background:#111827;">
                <th style="text-align:left;padding:10px;border-bottom:1px solid #374151;">名称</th>
                <th style="text-align:left;padding:10px;border-bottom:1px solid #374151;">值</th>
                <th style="width:160px;border-bottom:1px solid #374151;">操作</th>
            </tr></thead><tbody>`;

        if (Object.keys(currentCookies).length === 0) {
            html += `<tr><td colspan="3" style="text-align:center;padding:60px;color:#9ca3af;">当前页面没有 Cookie</td></tr>`;
        } else {
            Object.entries(currentCookies).forEach(([name, value]) => {
                const short = value.length > 60 ? value.slice(0,57)+'...' : value;
                html += `<tr style="border-bottom:1px solid #374151;">
                    <td style="padding:10px;font-weight:500;">${escapeHtml(name)}</td>
                    <td style="padding:10px;word-break:break-all;font-size:13px;">${escapeHtml(short)}</td>
                    <td style="padding:10px;">
                        <button onclick="copyCookie('${escapeHtml(name)}')" style="margin:2px;padding:4px 8px;font-size:12px;background:#10b981;color:white;border:none;border-radius:4px;">复制</button>
                        <button onclick="editCookie('${escapeHtml(name)}')" style="margin:2px;padding:4px 8px;font-size:12px;background:#3b82f6;color:white;border:none;border-radius:4px;">修改</button>
                        <button onclick="deleteCookie('${escapeHtml(name)}')" style="margin:2px;padding:4px 8px;font-size:12px;background:#ef4444;color:white;border:none;border-radius:4px;">删除</button>
                    </td>
                </tr>`;
            });
        }
        html += `</tbody></table>`;
        container.innerHTML = html;
    }

    window.copyCookie = function(name) {
        const val = currentCookies[name];
        if (val) navigator.clipboard.writeText(name + '=' + val).then(() => showToast('已复制：' + name));
    };

    window.editCookie = function(name) {
        const val = currentCookies[name] || '';
        const newVal = prompt('修改 "' + name + '" 的值：', val);
        if (newVal !== null) {
            document.cookie = name + '=' + newVal + '; path=/; max-age=31536000';
            renderCookies();
            showToast('已更新：' + name);
        }
    };

    window.deleteCookie = function(name) {
        if (confirm('确定删除 "' + name + '" 吗？')) {
            document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/';
            renderCookies();
            showToast('已删除：' + name);
        }
    };

    function addNewCookie() {
        const name = prompt('新 Cookie 名称：');
        if (!name) return;
        const value = prompt('Cookie 值：', '');
        if (value !== null) {
            document.cookie = name + '=' + value + '; path=/; max-age=31536000';
            renderCookies();
            showToast('已新增：' + name);
        }
    }

    function bindEvents() {
        document.getElementById('btn-refresh').onclick = renderCookies;
        document.getElementById('btn-add').onclick = addNewCookie;
        
        // 关闭时重置加载状态，这样再次点击小书签能重新正常打开
        const closeManager = () => {
            modal.remove();
            window.cookieManagerLoaded = false;
        };
        document.getElementById('btn-close').onclick = closeManager;
        modal.onclick = e => { if (e.target === modal) closeManager(); };
    }

    function init() {
        renderCookies();
        bindEvents();
        showToast('🍪 Cookie Manager 已成功加载'); // 替换原有的 console.log
    }

    window.toggleCookieManager = function() {
        const exist = document.getElementById('cookie-manager-modal');
        if (exist) {
            exist.remove();
            window.cookieManagerLoaded = false;
            showToast('已关闭 Cookie 管理器');
        } else {
            init();
        }
    }

    init();
})();
