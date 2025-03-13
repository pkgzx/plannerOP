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

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
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

      // Configurar un timeout para cerrar el diálogo después de 10 segundos
      Future.delayed(const Duration(seconds: 10), () {
        if (dialogIsOpen) {
          closeDialog();
          showAlertToast(
              context, 'La operación está tardando demasiado tiempo');
          debugPrint(
              '⚠️ Timeout de login activado - Diálogo cerrado por timeout');
        }
      });

      try {
        debugPrint('🔒 Iniciando proceso de login...');

        final ResSigninDto response = await _signinService.signin(
          _usernameController.text,
          _passwordController.text,
        );

        // Cerrar el diálogo de carga si aún está abierto
        closeDialog();
        debugPrint('✅ Login completado - Diálogo cerrado normalmente');

        if (response.isSuccess) {
          if (!mounted) return;

          // Resto del código para iniciar sesión exitosa...
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          authProvider.setAccessToken(response.accessToken);

          final decodedToken = JwtDecoder.decode(response.accessToken);

          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          userProvider.setUser(User(
            name: decodedToken['username'],
            id: decodedToken['id'],
            dni: decodedToken['dni'],
            phone: decodedToken['phone'],
          ));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SupervisorHome()),
          );
        } else {
          if (!mounted) return;
          showErrorToast(context, 'Usuario o contraseña incorrectos');
        }
      } catch (e) {
        debugPrint('❌ Error en login: $e');

        // Cerrar el diálogo de carga si hay error y está abierto
        closeDialog();
        debugPrint('⚠️ Login fallido - Diálogo cerrado por error');

        if (mounted) {
          showErrorToast(context, 'Error de conexión: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
