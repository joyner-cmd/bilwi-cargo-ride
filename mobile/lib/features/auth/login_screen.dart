import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../state/auth_provider.dart';
import '../common/app_logo.dart';
import '../home/role_router.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController(text: '+505');
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().login(_phone.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RoleRouter()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.messageFrom(e)), backgroundColor: AppColors.alerta));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo(String phone) {
    _phone.text = phone;
    _password.text = 'demo1234';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppLogo(size: 88)),
                const SizedBox(height: 16),
                const Center(
                  child: Text('Bilwi Cargo & Ride',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                const Center(
                  child: Text('Inicia sesion para continuar',
                      style: TextStyle(color: AppColors.grisTexto)),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Telefono', prefixIcon: Icon(Icons.phone)),
                  validator: (v) =>
                      (v == null || v.trim().length < 8) ? 'Telefono invalido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Contrasena',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Minimo 6 caracteres' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Entrar'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Crear cuenta nueva'),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),
                const Text('Cuentas demo (rapido):',
                    style: TextStyle(color: AppColors.grisTexto, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                        avatar: const Icon(Icons.person, size: 18),
                        label: const Text('Cliente'),
                        onPressed: () => _fillDemo('+50588880001')),
                    ActionChip(
                        avatar: const Icon(Icons.local_taxi, size: 18),
                        label: const Text('Conductor'),
                        onPressed: () => _fillDemo('+50588880002')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
