import { badRequest } from '../utils/errors.js';

/**
 * Valida req[source] contra un schema de zod. Reemplaza el valor por el parseado.
 * Uso: validate(schema), validate(schema, 'query')
 */
export const validate = (schema, source = 'body') => (req, _res, next) => {
  const result = schema.safeParse(req[source]);
  if (!result.success) {
    const msg = result.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ');
    return next(badRequest(msg));
  }
  req[source] = result.data;
  next();
};
