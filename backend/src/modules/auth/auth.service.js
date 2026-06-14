import { usersRepo } from '../users/users.repository.js';
import { driversRepo } from '../drivers/drivers.repository.js';
import { hashPassword, verifyPassword, signToken } from '../../utils/security.js';
import { conflict, unauthorized } from '../../utils/errors.js';

export const authService = {
  async register({ role, fullName, phone, email, password }) {
    const existing = await usersRepo.findByPhone(phone);
    if (existing) throw conflict('Ese telefono ya esta registrado');

    const passwordHash = await hashPassword(password);
    const user = await usersRepo.create({ role, fullName, phone, email, passwordHash });

    // Si es conductor, crea su perfil base (pendiente de documentos).
    if (role === 'driver') await driversRepo.ensureProfile(user.id);

    const token = signToken({ sub: user.id, role: user.role });
    return { user, token };
  },

  async login({ phone, password }) {
    const record = await usersRepo.findByPhone(phone);
    if (!record) throw unauthorized('Telefono o contrasena incorrectos');
    if (record.status === 'suspended') throw unauthorized('Cuenta suspendida');

    const ok = await verifyPassword(password, record.password_hash);
    if (!ok) throw unauthorized('Telefono o contrasena incorrectos');

    const user = await usersRepo.findById(record.id);
    const token = signToken({ sub: user.id, role: user.role });
    return { user, token };
  },
};
