const express = require('express');
const router = express.Router();
const User = require('../models/user');
const ApiError = require('../utils/apiError');

const isLocalIp = (ipRaw) => {
  const ip = (ipRaw || '').toString();
  return ip === '127.0.0.1' || ip === '::1' || ip.endsWith('127.0.0.1');
};

const allowRemoteAdmin = () => {
  const v = (process.env.ADMIN_ALLOW_REMOTE || '').toString().trim().toLowerCase();
  return v === '1' || v === 'true' || v === 'yes';
};

const adminAuth = (req, res, next) => {
  const ip = req.ip || req.connection?.remoteAddress || '';
  const isLocal = isLocalIp(ip);
  if (!isLocal && !allowRemoteAdmin()) {
    return next(new ApiError('FORBIDDEN', 'Admin endpoints are only available from localhost', 403));
  }

  const expected = process.env.ADMIN_TOKEN;
  const provided = req.get('x-admin-token');

  if (!expected) {
    return next(new ApiError('ADMIN_TOKEN_MISSING', 'ADMIN_TOKEN is not configured on server', 500));
  }

  if (!provided || provided !== expected) {
    return next(new ApiError('UNAUTHORIZED', 'Invalid admin token', 401));
  }

  next();
};

const adminPanelAccess = (req, res, next) => {
  const ip = req.ip || req.connection?.remoteAddress || '';
  const isLocal = isLocalIp(ip);
  if (isLocal) {
    return next();
  }
  if (!allowRemoteAdmin()) {
    return next(new ApiError('FORBIDDEN', 'Admin panel is only available from localhost', 403));
  }
  const expected = process.env.ADMIN_TOKEN;
  const provided = (req.query.token || '').toString();
  if (!expected) {
    return next(new ApiError('ADMIN_TOKEN_MISSING', 'ADMIN_TOKEN is not configured on server', 500));
  }
  if (!provided || provided !== expected) {
    return next(new ApiError('UNAUTHORIZED', 'Missing/invalid admin token', 401));
  }
  next();
};

router.get('/users', adminAuth, async (req, res, next) => {
  try {
    const q = (req.query.q || '').toString().trim();
    const limitRaw = parseInt(req.query.limit, 10);
    const skipRaw = parseInt(req.query.skip, 10);

    const limit = Number.isFinite(limitRaw) ? Math.min(Math.max(limitRaw, 1), 200) : 50;
    const skip = Number.isFinite(skipRaw) ? Math.max(skipRaw, 0) : 0;

    const filter = {};
    if (q) {
      const rx = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
      filter.$or = [{ phoneNumber: rx }, { name: rx }, { email: rx }];
    }

    const users = await User.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .select({ __v: 0, ageGroup: 0 })
      .lean();

    const total = await User.countDocuments(filter);

    res.json({
      success: true,
      total,
      count: users.length,
      users
    });
  } catch (err) {
    next(err);
  }
});

router.get('/users/export', adminAuth, async (req, res, next) => {
  try {
    const q = (req.query.q || '').toString().trim();
    const format = (req.query.format || 'json').toString().trim().toLowerCase();

    const filter = {};
    if (q) {
      const rx = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
      filter.$or = [{ phoneNumber: rx }, { name: rx }, { email: rx }];
    }

    const users = await User.find(filter)
      .sort({ createdAt: -1 })
      .select({ __v: 0, ageGroup: 0 })
      .lean();

    if (format === 'csv') {
      const escapeCsv = (value) => {
        const s = (value ?? '').toString();
        if (/[\n\r,\"]/g.test(s)) {
          return '"' + s.replace(/\"/g, '""') + '"';
        }
        return s;
      };

      const header = ['_id', 'phoneNumber', 'name', 'email', 'aadhaarNumber', 'dob', 'age', 'emergencyContact', 'profilePhotoUrl', 'profileCompleteness', 'createdAt', 'updatedAt'];
      const lines = [header.join(',')];
      for (const u of users) {
        const row = header.map((k) => escapeCsv(u[k]));
        lines.push(row.join(','));
      }

      res.setHeader('content-type', 'text/csv; charset=utf-8');
      res.setHeader('content-disposition', 'attachment; filename="users.csv"');
      res.send(lines.join('\n'));
      return;
    }

    res.setHeader('content-type', 'application/json; charset=utf-8');
    res.setHeader('content-disposition', 'attachment; filename="users.json"');
    res.send(JSON.stringify({ success: true, count: users.length, users }, null, 2));
  } catch (err) {
    next(err);
  }
});

router.get('/panel', adminPanelAccess, (req, res) => {
  res.setHeader('content-type', 'text/html; charset=utf-8');
  res.send(`<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>TrainBuddy Admin</title>
    <style>
      :root { color-scheme: light; }
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; margin: 0; background: #0b1220; color: #e5e7eb; }
      header { padding: 18px 20px; border-bottom: 1px solid rgba(255,255,255,.08); display: flex; align-items: center; justify-content: space-between; }
      h1 { font-size: 16px; margin: 0; font-weight: 700; letter-spacing: .3px; }
      main { padding: 18px 20px; }
      .row { display: flex; gap: 10px; flex-wrap: wrap; }
      .card { background: rgba(255,255,255,.06); border: 1px solid rgba(255,255,255,.08); border-radius: 12px; padding: 14px; }
      .card h2 { margin: 0 0 10px 0; font-size: 14px; }
      label { font-size: 12px; color: rgba(229,231,235,.8); display: block; margin-bottom: 6px; }
      input { background: rgba(255,255,255,.06); border: 1px solid rgba(255,255,255,.12); color: #e5e7eb; padding: 10px 10px; border-radius: 10px; outline: none; min-width: 220px; }
      input::placeholder { color: rgba(229,231,235,.45); }
      button { background: #4f46e5; color: white; border: none; border-radius: 10px; padding: 10px 12px; cursor: pointer; font-weight: 600; }
      button.secondary { background: rgba(255,255,255,.10); }
      button:disabled { opacity: .6; cursor: not-allowed; }
      table { width: 100%; border-collapse: collapse; }
      th, td { text-align: left; padding: 10px 8px; border-bottom: 1px solid rgba(255,255,255,.08); font-size: 13px; }
      th { color: rgba(229,231,235,.8); font-weight: 600; }
      tr:hover td { background: rgba(255,255,255,.04); }
      .muted { color: rgba(229,231,235,.65); }
      .pill { display: inline-block; padding: 3px 8px; border-radius: 999px; background: rgba(79,70,229,.18); border: 1px solid rgba(79,70,229,.35); font-size: 12px; }
      pre { background: rgba(0,0,0,.35); border: 1px solid rgba(255,255,255,.08); padding: 12px; border-radius: 12px; overflow: auto; max-height: 50vh; }
      .modal { position: fixed; inset: 0; background: rgba(0,0,0,.6); display: none; align-items: center; justify-content: center; padding: 18px; }
      .modal.open { display: flex; }
      .modal-content { width: min(980px, 100%); }
      .right { margin-left: auto; }
      a { color: #93c5fd; text-decoration: none; }
      a:hover { text-decoration: underline; }
    </style>
  </head>
  <body>
    <header>
      <h1>TrainBuddy Admin</h1>
      <div class="muted">Localhost only • Protected by <span class="pill">x-admin-token</span></div>
    </header>
    <main>
      <div class="row">
        <div class="card" style="flex: 1; min-width: 320px;">
          <h2>Auth</h2>
          <label>Admin token (sent as <code>x-admin-token</code>)</label>
          <div class="row">
            <input id="token" type="password" placeholder="ADMIN_TOKEN" />
            <button id="saveToken" class="secondary">Save</button>
          </div>
          <div class="muted" style="margin-top: 10px; font-size: 12px;">Token is stored in your browser localStorage.</div>
        </div>

        <div class="card" style="flex: 2; min-width: 420px;">
          <h2>Users</h2>
          <div class="row">
            <div>
              <label>Search (phone / name / email)</label>
              <input id="q" placeholder="e.g. 9876 or azar" />
            </div>
            <div>
              <label>Limit</label>
              <input id="limit" type="number" value="50" min="1" max="200" />
            </div>
            <div class="right" style="display:flex; gap:10px; align-items:end;">
              <button id="downloadJson" class="secondary">Download JSON</button>
              <button id="downloadCsv" class="secondary">Download CSV</button>
              <button id="refresh">Refresh</button>
            </div>
          </div>
          <div id="status" class="muted" style="margin-top: 10px; font-size: 12px;"></div>
        </div>
      </div>

      <div class="card" style="margin-top: 16px;">
        <div class="row" style="align-items:center; justify-content: space-between;">
          <h2 style="margin:0;">Results</h2>
          <div class="muted" id="counts" style="font-size: 12px;"></div>
        </div>
        <div style="overflow:auto; margin-top: 10px;">
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Phone</th>
                <th>Name</th>
                <th>Email</th>
                <th>Aadhaar</th>
                <th>DOB</th>
                <th>Age</th>
                <th>Emergency</th>
                <th>Profile %</th>
                <th>Created</th>
                <th></th>
              </tr>
            </thead>
            <tbody id="rows"></tbody>
          </table>
        </div>
      </div>
    </main>

    <div id="modal" class="modal" role="dialog" aria-modal="true">
      <div class="modal-content card">
        <div class="row" style="align-items:center; justify-content: space-between;">
          <h2 style="margin:0;">User JSON</h2>
          <button id="closeModal" class="secondary">Close</button>
        </div>
        <div id="photoWrap" style="margin-top: 12px; display:none;">
          <div class="muted" style="font-size: 12px; margin-bottom: 8px;">Profile photo preview</div>
          <img id="photo" alt="Profile photo" style="max-width: 220px; border-radius: 12px; border: 1px solid rgba(255,255,255,.10);" />
        </div>
        <pre id="json"></pre>
      </div>
    </div>

    <script>
      const tokenInput = document.getElementById('token');
      const saveTokenBtn = document.getElementById('saveToken');
      const qInput = document.getElementById('q');
      const limitInput = document.getElementById('limit');
      const refreshBtn = document.getElementById('refresh');
      const downloadJsonBtn = document.getElementById('downloadJson');
      const downloadCsvBtn = document.getElementById('downloadCsv');
      const statusEl = document.getElementById('status');
      const countsEl = document.getElementById('counts');
      const rowsEl = document.getElementById('rows');
      const modal = document.getElementById('modal');
      const closeModal = document.getElementById('closeModal');
      const jsonEl = document.getElementById('json');
      const photoWrap = document.getElementById('photoWrap');
      const photoImg = document.getElementById('photo');

      function getToken() {
        return localStorage.getItem('trainbuddy_admin_token') || '';
      }
      function setToken(v) {
        localStorage.setItem('trainbuddy_admin_token', v || '');
      }

      const qpToken = new URLSearchParams(location.search).get('token');
      if (qpToken) {
        setToken(qpToken);
      }

      tokenInput.value = getToken();
      saveTokenBtn.addEventListener('click', () => {
        setToken(tokenInput.value.trim());
        statusEl.textContent = 'Saved token.';
        setTimeout(() => (statusEl.textContent = ''), 1200);
      });

      function fmtDate(v) {
        if (!v) return '';
        try { return new Date(v).toLocaleString(); } catch (_) { return String(v); }
      }

      function openJson(obj) {
        jsonEl.textContent = JSON.stringify(obj, null, 2);

        const rawUrl = (obj && (obj.profilePhotoUrl || obj.photoUrl)) ? String(obj.profilePhotoUrl || obj.photoUrl) : '';
        if (rawUrl) {
          let url = rawUrl;
          if (url.startsWith('/')) {
            url = location.origin + url;
          } else {
            // If it was stored with emulator host, rewrite for browser usage.
            url = url.replace('10.0.2.2', location.hostname);
          }
          photoImg.src = url;
          photoWrap.style.display = 'block';
        } else {
          photoImg.src = '';
          photoWrap.style.display = 'none';
        }

        modal.classList.add('open');
      }

      closeModal.addEventListener('click', () => modal.classList.remove('open'));
      modal.addEventListener('click', (e) => { if (e.target === modal) modal.classList.remove('open'); });

      async function fetchJson(url) {
        const token = getToken() || tokenInput.value.trim();
        if (!token) {
          throw new Error('Missing admin token. Enter ADMIN_TOKEN and click Save.');
        }
        const res = await fetch(url, {
          headers: { 'x-admin-token': token }
        });
        const text = await res.text();
        let json;
        try { json = JSON.parse(text); } catch (_) { throw new Error(text || ('HTTP ' + res.status)); }
        if (!res.ok) {
          throw new Error(json.message || ('HTTP ' + res.status));
        }
        return json;
      }

      async function downloadExport(format) {
        const token = getToken() || tokenInput.value.trim();
        if (!token) {
          alert('Missing admin token. Enter ADMIN_TOKEN and click Save.');
          return;
        }

        const q = qInput.value.trim();
        const url = new URL(location.origin + '/admin/users/export');
        url.searchParams.set('format', format);
        if (q) url.searchParams.set('q', q);

        statusEl.textContent = 'Preparing download...';
        try {
          const res = await fetch(url.toString(), { headers: { 'x-admin-token': token } });
          const blob = await res.blob();
          if (!res.ok) {
            try {
              const txt = await blob.text();
              const j = JSON.parse(txt);
              throw new Error(j.message || ('HTTP ' + res.status));
            } catch (_) {
              throw new Error('HTTP ' + res.status);
            }
          }

          const filename = format === 'csv' ? 'users.csv' : 'users.json';
          const a = document.createElement('a');
          a.href = URL.createObjectURL(blob);
          a.download = filename;
          document.body.appendChild(a);
          a.click();
          a.remove();
          setTimeout(() => URL.revokeObjectURL(a.href), 1000);
          statusEl.textContent = '';
        } catch (e) {
          statusEl.textContent = 'Error: ' + (e.message || e);
        }
      }

      async function loadUsers() {
        rowsEl.innerHTML = '';
        countsEl.textContent = '';
        statusEl.textContent = 'Loading...';

        const q = qInput.value.trim();
        const limit = Math.min(Math.max(parseInt(limitInput.value || '50', 10) || 50, 1), 200);

        const url = new URL(location.origin + '/admin/users');
        if (q) url.searchParams.set('q', q);
        url.searchParams.set('limit', String(limit));

        try {
          const json = await fetchJson(url.toString());
          const users = json.users || [];
          countsEl.textContent =
            'Total: ' +
            ((json.total !== undefined && json.total !== null) ? json.total : users.length) +
            ' • Showing: ' +
            users.length;

          if (!users.length) {
            statusEl.textContent = 'No users found.';
            return;
          }

          for (const u of users) {
            const tr = document.createElement('tr');
            const id = u._id || u.id || '';
            tr.innerHTML =
              '<td class="muted">' + id + '</td>' +
              '<td>' + (u.phoneNumber || '') + '</td>' +
              '<td>' + (u.name || '') + '</td>' +
              '<td class="muted">' + (u.email || '') + '</td>' +
              '<td class="muted">' + (u.aadhaarNumber || '') + '</td>' +
              '<td class="muted">' + (u.dob ? new Date(u.dob).toLocaleDateString() : '') + '</td>' +
              '<td class="muted">' + ((u.age !== undefined && u.age !== null) ? u.age : '') + '</td>' +
              '<td class="muted">' + (u.emergencyContact || '') + '</td>' +
              '<td class="muted">' + ((u.profileCompleteness !== undefined && u.profileCompleteness !== null) ? u.profileCompleteness : '') + '</td>' +
              '<td class="muted">' + fmtDate(u.createdAt) + '</td>' +
              '<td><button class="secondary" data-id="' + id + '">View</button></td>';
            tr.querySelector('button').addEventListener('click', async () => {
              try {
                const detail = await fetchJson(location.origin + '/admin/users/' + encodeURIComponent(id));
                openJson(detail.user || detail);
              } catch (e) {
                alert(String(e.message || e));
              }
            });
            rowsEl.appendChild(tr);
          }

          statusEl.textContent = '';
        } catch (e) {
          statusEl.textContent = 'Error: ' + (e.message || e);
        }
      }

      refreshBtn.addEventListener('click', loadUsers);
      downloadJsonBtn.addEventListener('click', () => downloadExport('json'));
      downloadCsvBtn.addEventListener('click', () => downloadExport('csv'));
      qInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') loadUsers(); });
      window.addEventListener('load', loadUsers);
    </script>
  </body>
</html>`);
});

router.get('/users/by-phone/:phone', adminAuth, async (req, res, next) => {
  try {
    const phone = (req.params.phone || '').toString().trim();
    if (!phone) {
      throw new ApiError('INVALID_PARAMETERS', 'Phone number is required', 400);
    }

    const user = await User.findOne({ phoneNumber: phone }).select({ __v: 0, ageGroup: 0 }).lean();
    if (!user) {
      throw new ApiError('USER_NOT_FOUND', 'User not found', 404);
    }

    res.json({ success: true, user });
  } catch (err) {
    next(err);
  }
});

router.get('/users/:id', adminAuth, async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await User.findById(id).select({ __v: 0, ageGroup: 0 }).lean();
    if (!user) {
      throw new ApiError('USER_NOT_FOUND', 'User not found', 404);
    }

    res.json({ success: true, user });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
