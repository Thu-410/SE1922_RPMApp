const { query } = require('../../config/db');

const ALLOWED_STATUS = ['pending', 'processing', 'completed', 'cancelled'];

function buildWhere(filters, user) {
    const where = [];
    const params = [];

    if (user?.role === 'Tenant' && user?.tenant_id) {
        where.push('mr.tenant_id = ?');
        params.push(user.tenant_id);
    }

    if (filters.status) {
        where.push('mr.status = ?');
        params.push(filters.status);
    }

    if (filters.room_id) {
        where.push('mr.room_id = ?');
        params.push(Number(filters.room_id));
    }

    if (filters.tenant_id && user?.role !== 'Tenant') {
        where.push('mr.tenant_id = ?');
        params.push(Number(filters.tenant_id));
    }

    if (filters.keyword) {
        where.push('(mr.title LIKE ? OR mr.description LIKE ? OR r.room_number LIKE ? OR t.full_name LIKE ?)');
        const keyword = `%${filters.keyword}%`;
        params.push(keyword, keyword, keyword, keyword);
    }

    return {
        sql: where.length ? `WHERE ${where.join(' AND ')}` : '',
        params,
    };
}

async function getAll(filters = {}, user) {
    const page = Math.max(Number(filters.page || 1), 1);
    const limit = Math.min(Math.max(Number(filters.limit || 20), 1), 100);
    const offset = (page - 1) * limit;
    const { sql: whereSql, params } = buildWhere(filters, user);

    const [rows] = await query(
        `SELECT
        mr.id,
        mr.room_id,
        r.room_number,
        mr.tenant_id,
        t.full_name AS tenant_name,
        mr.title,
        mr.description,
        mr.image_url,
        mr.status,
        mr.manager_note,
        mr.created_at,
        mr.updated_at
      FROM maintenance_requests mr
      LEFT JOIN rooms r ON r.id = mr.room_id
      LEFT JOIN tenants t ON t.id = mr.tenant_id
      ${whereSql}
      ORDER BY mr.created_at DESC
      OFFSET ? ROWS FETCH NEXT ? ROWS ONLY`,
        [...params, offset, limit]
    );

    const [[countRow]] = await query(
        `SELECT COUNT(*) AS total
      FROM maintenance_requests mr
      LEFT JOIN rooms r ON r.id = mr.room_id
      LEFT JOIN tenants t ON t.id = mr.tenant_id
      ${whereSql}`,
        params
    );

    return {
        data: rows,
        pagination: {
            page,
            limit,
            total: countRow.total,
            total_pages: Math.ceil(countRow.total / limit),
        },
    };
}

async function getById(id, user) {
    const [rows] = await query(
        `SELECT
        mr.id,
        mr.room_id,
        r.room_number,
        mr.tenant_id,
        t.full_name AS tenant_name,
        t.phone AS tenant_phone,
        mr.title,
        mr.description,
        mr.image_url,
        mr.status,
        mr.manager_note,
        mr.created_at,
        mr.updated_at
      FROM maintenance_requests mr
      LEFT JOIN rooms r ON r.id = mr.room_id
      LEFT JOIN tenants t ON t.id = mr.tenant_id
      WHERE mr.id = ?`,
        [id]
    );

    const request = rows[0];
    if (!request) return null;

    if (user?.role === 'Tenant' && user?.tenant_id && request.tenant_id !== user.tenant_id) {
        return 'FORBIDDEN';
    }

    return request;
}

async function create(payload, user) {
    const { room_id, tenant_id, title, description, image_url } = payload;

    if (!room_id || !tenant_id || !title) {
        const err = new Error('room_id, tenant_id và title là bắt buộc');
        err.statusCode = 400;
        throw err;
    }

    if (user?.role === 'Tenant' && user?.tenant_id && Number(tenant_id) !== user.tenant_id) {
        const err = new Error('Người thuê chỉ được tạo yêu cầu cho chính mình');
        err.statusCode = 403;
        throw err;
    }

    const [result] = await query(
        `INSERT INTO maintenance_requests
      (room_id, tenant_id, title, description, image_url, status, created_at, updated_at)
     OUTPUT INSERTED.id
     VALUES (?, ?, ?, ?, ?, 'pending', GETDATE(), GETDATE())`,
        [room_id, tenant_id, title, description || null, image_url || null]
    );

    const insertedId = result[0]?.id;
    return getById(insertedId, user);
}

async function update(id, payload) {
    const current = await getById(id, { role: 'Manager' });
    if (!current) return null;

    const fields = [];
    const params = [];

    ['room_id', 'tenant_id', 'title', 'description', 'image_url', 'manager_note'].forEach((field) => {
        if (payload[field] !== undefined) {
            fields.push(`${field} = ?`);
            params.push(payload[field]);
        }
    });

    if (payload.status !== undefined) {
        if (!ALLOWED_STATUS.includes(payload.status)) {
            const err = new Error('Trạng thái không hợp lệ');
            err.statusCode = 400;
            throw err;
        }
        fields.push('status = ?');
        params.push(payload.status);
    }

    if (!fields.length) return current;

    fields.push('updated_at = GETDATE()');
    await query(`UPDATE maintenance_requests SET ${fields.join(', ')} WHERE id = ?`, [...params, id]);
    return getById(id, { role: 'Manager' });
}

async function updateStatus(id, status, manager_note) {
    if (!ALLOWED_STATUS.includes(status)) {
        const err = new Error('Trạng thái không hợp lệ');
        err.statusCode = 400;
        throw err;
    }

    const [result] = await query(
        `UPDATE maintenance_requests
      SET status = ?, manager_note = COALESCE(?, manager_note), updated_at = GETDATE()
      WHERE id = ?`,
        [status, manager_note || null, id]
    );

    if (!result || result.rowsAffected === 0) return null;
    return getById(id, { role: 'Manager' });
}

async function remove(id) {
    const [result] = await query('DELETE FROM maintenance_requests WHERE id = ?', [id]);
    return result && result.rowsAffected > 0;
}

module.exports = {
    getAll,
    getById,
    create,
    update,
    updateStatus,
    remove,
};
