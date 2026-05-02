/**
 * excel_parser_worker.js
 *
 * A native browser Web Worker that uses SheetJS to parse Excel files.
 * Runs on a completely separate OS thread — the Flutter UI is 100% free.
 *
 * Message IN:  ArrayBuffer (raw Excel file bytes)
 * Message OUT: JSON string — { success: true, data: [...rows] }
 *              or            { success: false, error: "..." }
 */

// Load SheetJS from CDN inside the worker context
importScripts('https://cdn.sheetjs.com/xlsx-0.20.3/package/dist/xlsx.full.min.js');

self.onmessage = function (e) {
  try {
    const arrayBuffer = e.data;

    // Read the workbook from the ArrayBuffer
    const workbook = XLSX.read(arrayBuffer, { type: 'array', cellDates: false, cellText: true });

    const firstSheetName = workbook.SheetNames[0];
    if (!firstSheetName) {
      self.postMessage(JSON.stringify({ success: false, error: 'No sheets found in workbook.' }));
      return;
    }

    const worksheet = workbook.Sheets[firstSheetName];

    // Convert to array of arrays (header row + data rows)
    const rawRows = XLSX.utils.sheet_to_json(worksheet, { header: 1, defval: '', raw: false });

    if (rawRows.length < 2) {
      self.postMessage(JSON.stringify({ success: false, error: 'No data rows found.' }));
      return;
    }

    // --- Header mapping ---
    const headerRow = rawRows[0].map(h => String(h).toLowerCase().trim());

    function findCol(aliases) {
      for (const alias of aliases) {
        const idx = headerRow.indexOf(alias.toLowerCase());
        if (idx !== -1) return idx;
      }
      return -1;
    }

    const iName    = findCol(['name', 'customer name', 'customer', 'full name']);
    const iMeter   = findCol(['meter', 'meter number', 'meter no']);
    const iAccount = findCol(['account', 'account number', 'acc no', 'account no']);
    const iSpn     = findCol(['spn', 'spn number', 'spn no', 'consumption', 'kwh']);
    const iFraud   = findCol(['fraud', 'fraud status', 'fraud risk', 'fraud type']);
    const iBills   = findCol(['bills', 'total bills', 'no of bills', 'total amount', 'amount']);
    const iPaid    = findCol(['amount paid', 'paid amount', 'paid']);
    const iFbs     = findCol(['fraud bill status', 'fraud bill', 'bill status']);
    const iBalance = findCol(['balance', 'total balance', 'outstanding', 'outstanding balance']);
    const iTariff  = findCol(['tariff', 'tariff type', 'category']);
    const iDate    = findCol(['date', 'billing date', 'last billing date']);
    const iSched   = findCol(['scheduled date', 'scheduled', 'date scheduled']);
    const iCreated = findCol(['created date', 'created', 'date created', 'timestamp', 'created at']);
    const iStatus  = findCol(['status', 'billing status', 'payment status']);

    function getVal(row, col) {
      if (col < 0 || col >= row.length) return '—';
      const v = String(row[col] ?? '').trim();
      return v === '' ? '—' : v;
    }

    function formatNum(s) {
      if (s === '—' || s === '') return '—';
      try {
        const numeric = s.replace(/[^\d.-]/g, '');
        if (numeric === '') return s;
        const n = parseFloat(numeric);
        if (isNaN(n)) return s;
        return Number.isInteger(n) ? String(Math.trunc(n)) : n.toFixed(2);
      } catch (_) {
        return s;
      }
    }

    // --- Parse all data rows ---
    const results = [];
    for (let r = 1; r < rawRows.length; r++) {
      const row = rawRows[r];
      // Skip completely empty rows
      if (!row || row.every(c => c === '' || c == null)) continue;

      const name = getVal(row, iName);
      const parts = name !== '—' ? name.trim().split(/\s+/).filter(Boolean) : [];
      const initials = parts.length > 0
        ? parts.slice(0, 2).map(p => p[0].toUpperCase()).join('')
        : '??';

      results.push({
        initials:          initials,
        name:              name,
        meter:             getVal(row, iMeter),
        account:           getVal(row, iAccount),
        consumption:       formatNum(getVal(row, iSpn)),
        fraud_status:      getVal(row, iFraud),
        total_amount:      formatNum(getVal(row, iBills)),
        amount_paid:       formatNum(getVal(row, iPaid)),
        fraud_bill_status: getVal(row, iFbs),
        balance:           formatNum(getVal(row, iBalance)),
        tariff:            getVal(row, iTariff),
        date:              getVal(row, iDate),
        scheduled:         getVal(row, iSched),
        created_at:        getVal(row, iCreated),
        status:            getVal(row, iStatus),
      });
    }

    self.postMessage(JSON.stringify({ success: true, data: results }));
  } catch (err) {
    self.postMessage(JSON.stringify({ success: false, error: String(err) }));
  }
};
