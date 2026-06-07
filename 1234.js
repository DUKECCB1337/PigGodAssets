 <!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>网页Cookie管理器</title>
    <style>
        body { font-family: "Microsoft YaHei", Arial, sans-serif; margin: 0; padding: 0; background: rgba(0,0,0,0.7); }
        #cookie-modal {
            position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%);
            background: white; border-radius: 12px; box-shadow: 0 10px 30px rgba(0,0,0,0.5);
            width: 920px; max-height: 88vh; overflow: hidden; z-index: 2147483647;
            display: flex; flex-direction: column;
        }
        .header { background: #1e88e5; color: white; padding: 15px 20px; font-size: 18px; font-weight: bold; display: flex; justify-content: space-between; align-items: center; }
        .close-btn { cursor: pointer; font-size: 26px; }
        .content { flex: 1; overflow: auto; padding: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; border-bottom: 1px solid #eee; text-align: left; }
        th { background: #f5f5f5; }
        input[type="text"] { width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; }
        .actions { padding: 15px 20px; background: #f8f9fa; display: flex; gap: 10px; flex-wrap: wrap; }
        button { padding: 8px 16px; border: none; border-radius: 6px; cursor: pointer; }
        .btn-primary { background: #1e88e5; color: white; }
        .btn-success { background: #43a047; color: white; }
        .btn-danger { background: #e53935; color: white; }
        .btn-secondary { background: #607d8b; color: white; }
        .new-row { background: #fff3e0; }
        .status { margin-left: auto; font-size: 14px; }
    </style>
</head>
<body>
<div id="cookie-modal">
    <div class="header">
        <span>📋 当前网页 Cookie 管理器</span>
        <span class="close-btn" onclick="closeModal()">×</span>
    </div>
    <div class="content">
        <table id="cookie-table">
            <thead><tr><th width="25%">名称</th><th width="45%">值</th><th width="15%">操作</th></tr></thead>
            <tbody id="cookie-body"></tbody>
        </table>
    </div>
    <div class="actions">
        <button class="btn-primary" onclick="addNewRow()">➕ 新增</button>
        <button class="btn-success" onclick="applyAllChanges()">✅ 全部应用</button>
        <button class="btn-secondary" onclick="copyAllCookies()">📋 复制全部</button>
        <button class="btn-danger" onclick="clearAllCookies()">🗑 清空所有</button>
        <button class="btn-secondary" onclick="closeModal()">关闭</button>
        <span class="status" id="status"></span>
    </div>
</div>

<script>
let cookies = [];

function parseCookies() {
    cookies = [];
    document.cookie.split(';').forEach(item => {
        const [name, ...valueParts] = item.trim().split('=');
        if (name) {
            const value = valueParts.join('=').trim();
            cookies.push({name: decodeURIComponent(name.trim()), value: decodeURIComponent(value)});
        }
    });
}

function renderTable() {
    const tbody = document.getElementById('cookie-body');
    tbody.innerHTML = '';
    cookies.forEach((c, i) => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><input type="text" value="\( {escapeHtml(c.name)}" onchange="cookies[ \){i}].name=this.value"></td>
            <td><input type="text" value="\( {escapeHtml(c.value)}" onchange="cookies[ \){i}].value=this.value"></td>
            <td><button onclick="deleteCookie(${i})" style="background:#e53935;color:white;padding:4px 8px;">删除</button></td>
        `;
        tbody.appendChild(tr);
    });
}

function escapeHtml(t) { return String(t).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }

function addNewRow() { cookies.push({name:'',value:''}); renderTable(); }
function deleteCookie(i) { if(confirm('删除？')) { cookies.splice(i,1); renderTable(); } }
function copyAllCookies() { navigator.clipboard.writeText(cookies.map(c=>`\( {c.name}= \){c.value}`).join('; ')); alert('已复制！'); }

function applyAllChanges() {
    document.cookie.split(';').forEach(c => {
        const n = c.split('=')[0].trim();
        if(n) document.cookie = n + '=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/';
    });
    cookies.forEach(c => {
        if(c.name) document.cookie = encodeURIComponent(c.name) + '=' + encodeURIComponent(c.value) + '; path=/; max-age=31536000';
    });
    alert('✅ 已应用修改！');
    parseCookies(); renderTable();
}

function clearAllCookies() {
    if(!confirm('确定清空所有Cookie？')) return;
    document.cookie.split(';').forEach(c => {
        const n = c.split('=')[0].trim();
        document.cookie = n + '=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/';
    });
    cookies = []; renderTable();
}

function closeModal() { document.getElementById('cookie-modal').remove(); }

// 初始化
parseCookies();
renderTable();
</script>
</body>
</html>
