import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/dependency_injection.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/user_dao.dart';

/// Modelo combinado de Usuario + Rol para mostrar en la UI
class UserWithRole {
  final UserData user;
  final RoleData? role;

  UserWithRole({required this.user, this.role});
}

/// Página de gestión de Empleados
class EmployeesPage extends StatefulWidget {
  const EmployeesPage({Key? key}) : super(key: key);

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  late UserDao _userDao;
  late AppDatabase _database;
  List<RoleData> _availableRoles = [];

  @override
  void initState() {
    super.initState();
    _userDao = getIt<UserDao>();
    _database = getIt<AppDatabase>();
    _loadRoles();
  }

  /// Carga todos los roles disponibles del sistema
  Future<void> _loadRoles() async {
    final roles = await _database.select(_database.roles).get();
    setState(() {
      _availableRoles = roles;
    });
  }

  /// Carga todos los usuarios con sus roles
  Future<List<UserWithRole>> _loadUsersWithRoles() async {
    final users = await _userDao.getAllUsers();
    final usersWithRoles = <UserWithRole>[];

    for (final user in users) {
      final role = await _userDao.getUserPrimaryRole(user.id);
      usersWithRoles.add(UserWithRole(user: user, role: role));
    }

    return usersWithRoles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empleados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Refrescar la lista
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: FutureBuilder<List<UserWithRole>>(
        future: _loadUsersWithRoles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar empleados',
                    style: TextStyle(fontSize: 16, color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final usersWithRoles = snapshot.data ?? [];

          if (usersWithRoles.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: usersWithRoles.length,
            itemBuilder: (context, index) {
              final userWithRole = usersWithRoles[index];
              return _buildEmployeeCard(userWithRole);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Empleado'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay empleados registrados',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(UserWithRole userWithRole) {
    final user = userWithRole.user;
    final role = userWithRole.role;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.textSecondary.withOpacity(0.1),
          child: Text(
            user.fullName[0].toUpperCase(),
            style: TextStyle(
              color: user.isActive ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.account_circle, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user.username,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.badge, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    role?.name ?? 'Sin rol asignado',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (user.email != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.email, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      user.email!,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            if (user.phone != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    user.phone!,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            if (!user.isActive) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'INACTIVO',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'password',
              child: Row(
                children: [
                  Icon(Icons.lock, size: 20),
                  SizedBox(width: 8),
                  Text('Cambiar Contraseña'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    user.isActive ? Icons.block : Icons.check_circle,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'Desactivar' : 'Activar'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditDialog(userWithRole);
            } else if (value == 'password') {
              _showPasswordDialog(user);
            } else if (value == 'toggle') {
              _toggleEmployeeStatus(user);
            }
          },
        ),
      ),
    );
  }

  /// Hash de contraseña usando SHA-256
  /// NOTA: En producción se debe usar bcrypt o argon2
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    // Generar un hash compatible con bcrypt format (60 caracteres)
    return '\$2a\$10\$${hash.toString().substring(0, 53)}';
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    int? selectedRoleId;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Empleado'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario *',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: jperez',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo *',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: Juan Pérez',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: jperez@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: 555-1234',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña *',
                      border: OutlineInputBorder(),
                      hintText: 'Mínimo 6 caracteres',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedRoleId,
                    decoration: const InputDecoration(
                      labelText: 'Rol *',
                      border: OutlineInputBorder(),
                    ),
                    items: _availableRoles
                        .map((role) => DropdownMenuItem(
                              value: role.id,
                              child: Text(role.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRoleId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validaciones
                if (usernameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El usuario es obligatorio'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre es obligatorio'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (passwordController.text.isEmpty || passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La contraseña debe tener al menos 6 caracteres'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (selectedRoleId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debe seleccionar un rol'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                try {
                  // Crear el usuario
                  final userId = await _userDao.createUser(
                    UsersCompanion.insert(
                      username: usernameController.text.trim(),
                      passwordHash: _hashPassword(passwordController.text),
                      fullName: nameController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? const drift.Value.absent()
                          : drift.Value(emailController.text.trim()),
                      phone: phoneController.text.trim().isEmpty
                          ? const drift.Value.absent()
                          : drift.Value(phoneController.text.trim()),
                    ),
                  );

                  // Asignar el rol al usuario
                  await _userDao.assignRoleToUser(
                    userId: userId,
                    roleId: selectedRoleId!,
                    isPrimary: true,
                  );

                  if (!mounted) return;

                  Navigator.of(dialogContext).pop();
                  setState(() {}); // Refrescar la lista

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Empleado creado exitosamente'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al crear empleado: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(UserWithRole userWithRole) {
    final user = userWithRole.user;
    final nameController = TextEditingController(text: user.fullName);
    final usernameController = TextEditingController(text: user.username);
    final emailController = TextEditingController(text: user.email ?? '');
    final phoneController = TextEditingController(text: user.phone ?? '');
    int? selectedRoleId = userWithRole.role?.id;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Empleado'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedRoleId,
                    decoration: const InputDecoration(
                      labelText: 'Rol *',
                      border: OutlineInputBorder(),
                    ),
                    items: _availableRoles
                        .map((role) => DropdownMenuItem(
                              value: role.id,
                              child: Text(role.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRoleId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validaciones
                if (usernameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El usuario es obligatorio'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre es obligatorio'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (selectedRoleId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debe seleccionar un rol'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                try {
                  // Actualizar el usuario
                  final updatedUser = user.copyWith(
                    username: usernameController.text.trim(),
                    fullName: nameController.text.trim(),
                    email: drift.Value(emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim()),
                    phone: drift.Value(phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim()),
                    updatedAt: DateTime.now(),
                  );

                  await _userDao.updateUser(updatedUser);

                  // Si cambió el rol, actualizar
                  if (selectedRoleId != userWithRole.role?.id) {
                    // Remover rol anterior si existe
                    if (userWithRole.role != null) {
                      await _userDao.removeRoleFromUser(user.id, userWithRole.role!.id);
                    }

                    // Asignar nuevo rol
                    await _userDao.assignRoleToUser(
                      userId: user.id,
                      roleId: selectedRoleId!,
                      isPrimary: true,
                    );
                  }

                  if (!mounted) return;

                  Navigator.of(dialogContext).pop();
                  setState(() {}); // Refrescar la lista

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Empleado actualizado exitosamente'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al actualizar empleado: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordDialog(UserData user) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cambiar contraseña de: ${user.fullName}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Nueva Contraseña',
                border: OutlineInputBorder(),
                hintText: 'Mínimo 6 caracteres',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Confirmar Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validaciones
              if (passwordController.text.isEmpty || passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La contraseña debe tener al menos 6 caracteres'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              if (passwordController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Las contraseñas no coinciden'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              try {
                // Actualizar la contraseña
                await _userDao.updatePassword(
                  user.id,
                  _hashPassword(passwordController.text),
                );

                if (!mounted) return;

                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contraseña actualizada exitosamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al actualizar contraseña: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _toggleEmployeeStatus(UserData user) async {
    try {
      if (user.isActive) {
        await _userDao.softDeleteUser(user.id);
      } else {
        // Reactivar usuario
        final updatedUser = user.copyWith(
          isActive: true,
          updatedAt: DateTime.now(),
        );
        await _userDao.updateUser(updatedUser);
      }

      setState(() {}); // Refrescar la lista

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Empleado ${!user.isActive ? "activado" : "desactivado"} exitosamente',
          ),
          backgroundColor: AppColors.info,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
