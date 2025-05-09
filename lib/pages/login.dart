import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:lottie/lottie.dart';
import 'package:plannerop/core/model/user.dart';
import 'package:plannerop/dto/auth/signin.dart';
import 'package:plannerop/pages/supervisor/home.dart';
import 'package:plannerop/services/auth/signin.dart';
import 'package:plannerop/store/auth.dart';
import 'package:plannerop/store/user.dart';
import 'package:plannerop/utils/DataManager.dart';
import 'package:plannerop/utils/toast.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final SigninService _signinService = SigninService();
  bool _isLoading = false;

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);

    // Intentar auto-login al iniciar la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoLogin();
    });
  }

  Future<void> _tryAutoLogin() async {
    if (!mounted) return;

    // Usar un timer para evitar que el loader se quede colgado indefinidamente
    Timer? timeoutTimer;

    setState(() {
      _isLoading = true;
    });

    // Configurar un timeout para evitar que el loader se quede infinitamente
    timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoading) {
        debugPrint('⚠️ AutoLogin timeout: cancelando operación');
        setState(() {
          _isLoading = false;
        });
      }
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bool success = await authProvider.tryAutoLogin(context);

      // Cancelar el timer ya que hemos terminado correctamente
      timeoutTimer.cancel();

      if (!mounted) return;

      if (success) {
        // Inicializar datos del usuario a partir del token
        final decodedToken = JwtDecoder.decode(authProvider.accessToken);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        userProvider.setUser(User(
          name: decodedToken['username'],
          id: decodedToken['id'],
          dni: decodedToken['dni'],
          phone: decodedToken['phone'],
          cargo: decodedToken['occupation'],
        ));

        // Mostrar un loader más visible durante la carga de datos
        if (mounted) {
          // Un overlay más sofisticado para la carga de datos
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return WillPopScope(
                onWillPop: () async => false,
                child: Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Cargando sesión...',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        // Cargar datos con manejo de errores mejorado
        try {
          await DataManager().loadDataAfterAuthentication(context);
        } catch (dataError) {
          debugPrint('Error cargando datos: $dataError');
          // Continuar incluso si hay error en la carga de datos
        }

        // Navegar al dashboard
        if (mounted) {
          // Cerrar el diálogo de carga si está abierto
          if (ModalRoute.of(context)?.isCurrent != true) {
            Navigator.of(context).pop();
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SupervisorHome()),
          );
        }
      }
    } catch (e) {
      debugPrint('Error en auto-login: $e');
      // Cancelar el timer en caso de error
      timeoutTimer?.cancel();
    } finally {
      // Asegurarnos de que _isLoading se establezca en false incluso si hay error
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      // Variable para controlar si el diálogo está mostrado
      bool dialogIsOpen = true;

      // Mantener una referencia al contexto del diálogo
      BuildContext? dialogContextRef;

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          // Guardar la referencia al contexto del diálogo
          dialogContextRef = dialogContext;

          return WillPopScope(
            onWillPop: () async => false, // Prevenir cierre con el botón atrás
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          );
        },
      );

      // Función para cerrar el diálogo de manera segura
      void closeDialog() {
        if (dialogIsOpen && mounted && dialogContextRef != null) {
          Navigator.of(dialogContextRef!).pop();
          dialogIsOpen = false;
        }
      }

      // Configurar un timeout para cerrar el diálogo después de 15 segundos
      // Aumentado a 15 segundos para dar más tiempo a la carga de datos
      Future.delayed(const Duration(seconds: 15), () {
        if (dialogIsOpen) {
          closeDialog();
          if (mounted) {
            showAlertToast(
                context, 'La operación está tardando demasiado tiempo');
          }
        }
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Usar el nuevo método de login que guardará las credenciales
        final success = await authProvider.login(
          _usernameController.text,
          _passwordController.text,
          context,
        );

        if (success) {
          // Inicializar datos del usuario
          final decodedToken = JwtDecoder.decode(authProvider.accessToken);
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);

          userProvider.setUser(User(
            name: decodedToken['username'],
            id: decodedToken['id'],
            dni: decodedToken['dni'],
            phone: decodedToken['phone'],
            cargo: decodedToken['occupation'],
          ));

          // Cargar datos mientras se muestra el loader
          await DataManager().loadDataAfterAuthentication(context);

          // Navegar al dashboard
          if (mounted) {
            closeDialog();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SupervisorHome()),
            );
          }
        } else {
          closeDialog();
          if (mounted) {
            showErrorToast(
                context, authProvider.error ?? 'Error de autenticación');
          }
        }
      } catch (e) {
        debugPrint('❌ Error en login: $e');
        closeDialog();
        if (mounted) {
          showErrorToast(context, 'Error de conexión: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si está cargando (intentando auto-login), mostrar spinner
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 300,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
                child: Lottie.asset('assets/auth-animation.json'),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 20),
                      Neumorphic(
                        style: NeumorphicStyle(
                          depth: -4,
                          intensity: 0.8,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12)),
                        ),
                        child: TextFormField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            errorStyle: TextStyle(
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su usuario';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Neumorphic(
                        style: NeumorphicStyle(
                          depth: -4,
                          intensity: 0.8,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12)),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su contraseña';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      NeumorphicButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await _login();
                          }
                        },
                        style: NeumorphicStyle(
                          shape: NeumorphicShape.flat,
                          depth: 8,
                          intensity: 1.0,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(12)),
                          color: Colors.blue, // Cambia el color del botón
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0,
                            horizontal: 32.0), // Aumenta el tamaño del botón
                        child: const Center(
                          child: Text(
                            'Ingresar',
                            style: TextStyle(
                              fontSize: 20, // Aumenta el tamaño del texto
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Cambia el color del texto
                            ),
                          ),
                        ),
                      ),

                      // Footer con "Created by" y logo
                      const SizedBox(height: 90),
                      Column(
                        children: [
                          Text(
                            'Created by',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Image.asset(
                            'assets/cargoban.png',
                            height: 100, // Tamaño controlado de la imagen
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
